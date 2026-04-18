use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Clear, Gauge, List, ListItem, Paragraph},
    Frame, Terminal,
};
use std::{
    env,
    io::{self, BufRead, BufReader, Write},
    process::{Command, Stdio},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread,
    time::Duration,
};
use std::sync::mpsc;

// --- CONFIGURATION ---
const HACKEROS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh";
const WALLPAPERS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh";

// --- THEME ---
const COLOR_BG: Color = Color::Reset;
const COLOR_ACCENT: Color = Color::Magenta;
const COLOR_FOCUS: Color = Color::Yellow;
const COLOR_TEXT_MAIN: Color = Color::White;
const COLOR_TEXT_DIM: Color = Color::DarkGray;
const COLOR_SUCCESS: Color = Color::Green;
const COLOR_ERROR: Color = Color::Red;
const COLOR_WARN: Color = Color::Yellow;

// --- DATA STRUCTURES ---
#[derive(Clone, Debug, PartialEq)]
enum TaskStatus {
    Pending,
    Running,
    Success,
    Failed,
    Skipped,
    Cancelled,
}

#[derive(Clone, Debug)]
struct Task {
    name: String,
    command: String,
    is_sudo: bool,
    status: TaskStatus,
    optional: bool,
    /// If true, this task uses custom logic instead of a direct shell command
    is_hnm: bool,
}

enum AppState {
    Login,
    Processing,
    Finished,
    ConfirmCancel,
}

enum AppEvent {
    LogLine(String),
    TaskStatusChange(usize, TaskStatus),
    AllTasksFinished,
    Error(String),
}

struct App {
    state: AppState,
    password_input: String,
    password_error: Option<String>,
    tasks: Vec<Task>,
    current_task_idx: usize,
    logs: Vec<String>,
    log_scroll_offset: usize,
    auto_scroll: bool,
    rx: mpsc::Receiver<AppEvent>,
    is_working: Arc<AtomicBool>,
    cancel_flag: Arc<AtomicBool>,
    current_child_pid: Arc<Mutex<Option<u32>>>,
    failed_tasks: Vec<String>,
}

// --- MAIN ---
fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    // --with-gui: relaunch in alacritty (only if not already in a terminal)
    if args.contains(&"--with-gui".to_string()) {
        if let Ok(current_exe) = env::current_exe() {
            let _ = Command::new("alacritty")
                .arg("-e")
                .arg(current_exe)
                .spawn();
            return Ok(());
        }
    }

    // If stdout is not a TTY (e.g. launched from a .desktop file without --with-gui),
    // run silently in background without opening any terminal window.
    if !is_tty() {
        run_headless()?;
        return Ok(());
    }

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let (tx, rx) = mpsc::channel::<AppEvent>();
    let mut app = App::new(rx);

    let res = run_app(&mut terminal, &mut app, tx);

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("Application Error: {:?}", err);
    }

    Ok(())
}

/// Check if stdout is connected to a real TTY
fn is_tty() -> bool {
    use std::os::unix::io::AsRawFd;
    unsafe { libc::isatty(io::stdout().as_raw_fd()) == 1 }
}

/// Run all update tasks headlessly (no TUI) when no terminal is available.
/// Useful when launched from a .desktop file or systemd service.
fn run_headless() -> Result<()> {
    let tasks = build_tasks();
    let log_path = "/tmp/hackeros-updater.log";
    let mut log_file = std::fs::File::create(log_path)?;

    writeln!(log_file, "=== HackerOS Updater (headless mode) ===")?;

    for task in &tasks {
        writeln!(log_file, "--- {} ---", task.name)?;

        if task.is_hnm {
            run_hnm_headless(&mut log_file)?;
            continue;
        }

        let mut cmd = if task.is_sudo {
            let mut c = Command::new("sudo");
            c.args(["-n", "bash", "-c", &task.command]);
            c
        } else {
            let mut c = Command::new("bash");
            c.args(["-c", &task.command]);
            c
        };

        cmd.stdout(Stdio::piped()).stderr(Stdio::piped()).stdin(Stdio::null());

        match cmd.output() {
            Ok(out) => {
                let _ = log_file.write_all(&out.stdout);
                let _ = log_file.write_all(&out.stderr);
                if out.status.success() {
                    writeln!(log_file, "OK")?;
                } else {
                    writeln!(log_file, "FAILED (exit {})", out.status.code().unwrap_or(-1))?;
                }
            }
            Err(e) => {
                writeln!(log_file, "Error: {}", e)?;
            }
        }
    }

    writeln!(log_file, "=== Done ===")?;
    Ok(())
}

fn run_hnm_headless(log_file: &mut std::fs::File) -> Result<()> {
    let check = Command::new("hnm").arg("check").output();
    match check {
        Ok(out) => {
            let _ = log_file.write_all(&out.stdout);
            let combined = String::from_utf8_lossy(&out.stdout).to_string()
                + &String::from_utf8_lossy(&out.stderr);
            if combined.contains("NOT FOUND") {
                writeln!(log_file, "[hnm] Nix not found, running hnm unpack...")?;
                let _ = Command::new("hnm").arg("unpack").status();
            }
            let _ = Command::new("hnm").arg("update").status();
            let _ = Command::new("hnm").arg("upgrade").status();
        }
        Err(e) => {
            writeln!(log_file, "[hnm] not available: {}", e)?;
        }
    }
    Ok(())
}

fn build_tasks() -> Vec<Task> {
    vec![
        Task {
            name: "System Update (APT)".to_string(),
            command: "apt-get update && apt-get upgrade -y && apt-get autoremove -y".to_string(),
            is_sudo: true,
            status: TaskStatus::Pending,
            optional: false,
            is_hnm: false,
        },
        Task {
            name: "Flatpak Update".to_string(),
            command: "flatpak update -y --noninteractive".to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        Task {
            name: "Snap Updates".to_string(),
            command: "snap refresh".to_string(),
            is_sudo: true,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        Task {
            name: "Brew Updates".to_string(),
            command: r#"if command -v brew &>/dev/null; then brew update && brew upgrade && brew cleanup; else echo "Brew not found, skipping."; fi"#.to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        Task {
            name: "Firmware Update".to_string(),
            command: "fwupdmgr refresh --force; fwupdmgr update --no-reboot-check".to_string(),
            is_sudo: true,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        Task {
            name: "Zsh / Oh-My-Zsh Update".to_string(),
            command: r#"if [ -d "$HOME/.oh-my-zsh" ]; then zsh -c 'source "$HOME/.zshrc" 2>/dev/null; omz update --unattended 2>&1 || true'; else echo "Oh-My-Zsh not found, skipping."; fi"#.to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        Task {
            name: "Distrobox Update".to_string(),
            command: "distrobox-upgrade --all 2>&1 || true".to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
        // HackerOS Nix Manager — uses custom logic via is_hnm flag
        Task {
            name: "HackerOS Nix Manager".to_string(),
            command: String::new(), // handled separately
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: true,
        },
        Task {
            name: "HackerOS Update".to_string(),
            command: HACKEROS_UPDATE_SCRIPT.to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: false,
            is_hnm: false,
        },
        Task {
            name: "Wallpapers Update".to_string(),
            command: WALLPAPERS_UPDATE_SCRIPT.to_string(),
            is_sudo: false,
            status: TaskStatus::Pending,
            optional: true,
            is_hnm: false,
        },
    ]
}

impl App {
    fn new(rx: mpsc::Receiver<AppEvent>) -> Self {
        Self {
            state: AppState::Login,
            password_input: String::new(),
            password_error: None,
            tasks: build_tasks(),
            current_task_idx: 0,
            logs: Vec::new(),
            log_scroll_offset: 0,
            auto_scroll: true,
            rx,
            is_working: Arc::new(AtomicBool::new(false)),
            cancel_flag: Arc::new(AtomicBool::new(false)),
            current_child_pid: Arc::new(Mutex::new(None)),
            failed_tasks: Vec::new(),
        }
    }

    fn try_login(&mut self, tx: mpsc::Sender<AppEvent>) {
        let password = self.password_input.clone();

        let mut child = match Command::new("sudo")
            .args(["-S", "-v"])
            .stdin(Stdio::piped())
            .stderr(Stdio::piped())
            .stdout(Stdio::null())
            .spawn()
        {
            Ok(c) => c,
            Err(e) => {
                self.password_error = Some(format!("System error: {}", e));
                return;
            }
        };

        if let Some(mut stdin) = child.stdin.take() {
            let _ = write!(stdin, "{}\n", password);
        }

        match child.wait() {
            Ok(status) if status.success() => {
                self.state = AppState::Processing;
                self.password_error = None;
                self.start_updates(tx, password);
            }
            _ => {
                self.password_input.clear();
                self.password_error = Some("Incorrect password. Try again.".to_string());
            }
        }
    }

    fn cancel_current(&mut self) {
        self.cancel_flag.store(true, Ordering::SeqCst);
        if let Ok(guard) = self.current_child_pid.lock() {
            if let Some(pid) = *guard {
                libc_kill(pid as i32, 15); // SIGTERM
            }
        }
        self.logs.push(">>> UPDATE CANCELLED BY USER <<<".to_string());
    }

    fn start_updates(&mut self, tx: mpsc::Sender<AppEvent>, password: String) {
        let tasks = self.tasks.clone();
        self.is_working.store(true, Ordering::SeqCst);
        self.cancel_flag.store(false, Ordering::SeqCst);

        let cancel_flag = self.cancel_flag.clone();
        let child_pid = self.current_child_pid.clone();

        thread::spawn(move || {
            for (idx, task) in tasks.iter().enumerate() {
                if cancel_flag.load(Ordering::SeqCst) {
                    let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
                    continue;
                }

                let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Running));
                let _ = tx.send(AppEvent::LogLine(format!(
                    "━━━ [{}/{}] {} ━━━",
                    idx + 1,
                    tasks.len(),
                    task.name
                )));

                // --- HackerOS Nix Manager: custom multi-step logic ---
                if task.is_hnm {
                    run_hnm_task(idx, &task.name, &tx, &cancel_flag, &child_pid);
                    continue;
                }

                // --- Standard task ---
                run_standard_task(
                    idx,
                    task,
                    &password,
                    &tx,
                    &cancel_flag,
                    &child_pid,
                );
            }

            let _ = tx.send(AppEvent::AllTasksFinished);
        });
    }
}

/// Run the HackerOS Nix Manager task:
/// 1. hnm check  → if NOT FOUND: hnm unpack
/// 2. hnm update
/// 3. hnm upgrade
fn run_hnm_task(
    idx: usize,
    task_name: &str,
    tx: &mpsc::Sender<AppEvent>,
    cancel_flag: &Arc<AtomicBool>,
    child_pid: &Arc<Mutex<Option<u32>>>,
) {
    // Helper to run a single hnm sub-command and stream its output
    let run_hnm_cmd = |args: &[&str]| -> Option<std::process::ExitStatus> {
        if cancel_flag.load(Ordering::SeqCst) {
            return None;
        }
        let _ = tx.send(AppEvent::LogLine(format!("[hnm] Running: hnm {}", args.join(" "))));

        let mut cmd = Command::new("hnm");
        cmd.args(args)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .stdin(Stdio::null());

        match cmd.spawn() {
            Ok(mut child) => {
                {
                    let mut pid_guard = child_pid.lock().unwrap();
                    *pid_guard = Some(child.id());
                }

                let stdout = child.stdout.take().unwrap();
                let stderr = child.stderr.take().unwrap();
                let tx_out = tx.clone();
                let tx_err = tx.clone();
                let cf_out = cancel_flag.clone();
                let cf_err = cancel_flag.clone();

                let h_out = thread::spawn(move || {
                    let reader = BufReader::new(stdout);
                    for line in reader.lines() {
                        if cf_out.load(Ordering::SeqCst) { break; }
                        if let Ok(l) = line {
                            let _ = tx_out.send(AppEvent::LogLine(l));
                        }
                    }
                });
                let h_err = thread::spawn(move || {
                    let reader = BufReader::new(stderr);
                    for line in reader.lines() {
                        if cf_err.load(Ordering::SeqCst) { break; }
                        if let Ok(l) = line {
                            let _ = tx_err.send(AppEvent::LogLine(format!("[stderr] {}", l)));
                        }
                    }
                });

                let status = child.wait().ok();
                let _ = h_out.join();
                let _ = h_err.join();

                {
                    let mut pid_guard = child_pid.lock().unwrap();
                    *pid_guard = None;
                }

                status
            }
            Err(e) => {
                let _ = tx.send(AppEvent::LogLine(format!("[hnm] spawn error: {}", e)));
                None
            }
        }
    };

    // 1. hnm check
    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // Capture check output to detect NOT FOUND
    let check_output = Command::new("hnm")
        .arg("check")
        .output();

    let nix_found = match check_output {
        Ok(out) => {
            let combined = String::from_utf8_lossy(&out.stdout).to_string()
                + &String::from_utf8_lossy(&out.stderr);
            // Stream check output to log
            for line in combined.lines() {
                let _ = tx.send(AppEvent::LogLine(line.to_string()));
            }
            !combined.contains("NOT FOUND")
        }
        Err(e) => {
            let _ = tx.send(AppEvent::LogLine(format!(
                "⚠ hnm not available ({}), skipping.",
                e
            )));
            let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Skipped));
            let _ = tx.send(AppEvent::LogLine(String::new()));
            return;
        }
    };

    // 2. If Nix not found → hnm unpack
    if !nix_found {
        let _ = tx.send(AppEvent::LogLine(
            "[hnm] Nix not found — running hnm unpack...".to_string(),
        ));
        run_hnm_cmd(&["unpack"]);
    }

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // 3. hnm update
    run_hnm_cmd(&["update"]);

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // 4. hnm upgrade
    run_hnm_cmd(&["upgrade"]);

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Success));
    let _ = tx.send(AppEvent::LogLine(format!("✓ {} — OK", task_name)));
    let _ = tx.send(AppEvent::LogLine(String::new()));
}

/// Run a standard (non-hnm) task
fn run_standard_task(
    idx: usize,
    task: &Task,
    password: &str,
    tx: &mpsc::Sender<AppEvent>,
    cancel_flag: &Arc<AtomicBool>,
    child_pid: &Arc<Mutex<Option<u32>>>,
) {
    let mut cmd = if task.is_sudo {
        let mut c = Command::new("sudo");
        c.args(["-S", "bash", "-c", &task.command]);
        c
    } else {
        let mut c = Command::new("bash");
        c.args(["-c", &task.command]);
        c
    };

    cmd.stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(Stdio::piped());

    match cmd.spawn() {
        Ok(mut child) => {
            {
                let mut pid_guard = child_pid.lock().unwrap();
                *pid_guard = Some(child.id());
            }

            if task.is_sudo {
                if let Some(mut stdin) = child.stdin.take() {
                    let _ = write!(stdin, "{}\n", password);
                }
            }

            let stdout = child.stdout.take().unwrap();
            let stderr = child.stderr.take().unwrap();
            let tx_out = tx.clone();
            let tx_err = tx.clone();
            let cancel_out = cancel_flag.clone();
            let cancel_err = cancel_flag.clone();

            let h_out = thread::spawn(move || {
                let reader = BufReader::new(stdout);
                for line in reader.lines() {
                    if cancel_out.load(Ordering::SeqCst) { break; }
                    if let Ok(l) = line {
                        let _ = tx_out.send(AppEvent::LogLine(l));
                    }
                }
            });

            let h_err = thread::spawn(move || {
                let reader = BufReader::new(stderr);
                for line in reader.lines() {
                    if cancel_err.load(Ordering::SeqCst) { break; }
                    if let Ok(l) = line {
                        if !l.contains("[sudo] password") && !l.contains("password for") {
                            let _ = tx_err.send(AppEvent::LogLine(format!("[stderr] {}", l)));
                        }
                    }
                }
            });

            let status = child.wait();
            let _ = h_out.join();
            let _ = h_err.join();

            {
                let mut pid_guard = child_pid.lock().unwrap();
                *pid_guard = None;
            }

            if cancel_flag.load(Ordering::SeqCst) {
                let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
                return;
            }

            match status {
                Ok(s) if s.success() => {
                    let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Success));
                    let _ = tx.send(AppEvent::LogLine(format!("✓ {} — OK", task.name)));
                }
                Ok(s) => {
                    if task.optional {
                        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Skipped));
                        let _ = tx.send(AppEvent::LogLine(format!(
                            "⚠ {} — skipped (exit {})",
                            task.name,
                            s.code().unwrap_or(-1)
                        )));
                    } else {
                        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Failed));
                        let _ = tx.send(AppEvent::LogLine(format!(
                            "✗ {} — FAILED (exit {})",
                            task.name,
                            s.code().unwrap_or(-1)
                        )));
                    }
                }
                Err(e) => {
                    let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Failed));
                    let _ = tx.send(AppEvent::LogLine(format!("✗ {} — error: {}", task.name, e)));
                }
            }
        }
        Err(e) => {
            if task.optional {
                let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Skipped));
                let _ = tx.send(AppEvent::LogLine(format!(
                    "⚠ {} — not available ({})",
                    task.name, e
                )));
            } else {
                let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Failed));
                let _ = tx.send(AppEvent::LogLine(format!(
                    "✗ {} — spawn error: {}",
                    task.name, e
                )));
            }
        }
    }

    let _ = tx.send(AppEvent::LogLine(String::new()));
}

// Safe SIGTERM wrapper
#[cfg(unix)]
fn libc_kill(pid: i32, sig: i32) {
    unsafe {
        libc::kill(pid, sig);
    }
}
#[cfg(not(unix))]
fn libc_kill(_pid: i32, _sig: i32) {}

// --- APP LOOP ---
fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
    tx: mpsc::Sender<AppEvent>,
) -> Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        loop {
            match app.rx.try_recv() {
                Ok(event) => handle_app_event(app, event),
                Err(mpsc::TryRecvError::Empty) => break,
                Err(mpsc::TryRecvError::Disconnected) => break,
            }
        }

        if crossterm::event::poll(Duration::from_millis(40))? {
            if let Event::Key(key) = event::read()? {
                if key.kind != KeyEventKind::Press {
                    continue;
                }

                if key.code == KeyCode::F(10) {
                    return Ok(());
                }

                match app.state {
                    AppState::Login => handle_login_key(app, key.code, tx.clone()),
                    AppState::Processing => handle_processing_key(app, key.code),
                    AppState::Finished => {
                        if handle_finished_key(app, key.code)? {
                            return Ok(());
                        }
                    }
                    AppState::ConfirmCancel => handle_confirm_cancel_key(app, key.code),
                }
            }
        }
    }
}

fn handle_app_event(app: &mut App, event: AppEvent) {
    match event {
        AppEvent::LogLine(line) => {
            app.logs.push(line);
            if app.auto_scroll {
                app.log_scroll_offset = app.logs.len().saturating_sub(1);
            }
        }
        AppEvent::TaskStatusChange(idx, status) => {
            if idx < app.tasks.len() {
                if status == TaskStatus::Failed {
                    app.failed_tasks.push(app.tasks[idx].name.clone());
                }
                app.tasks[idx].status = status;
                app.current_task_idx = idx;
            }
        }
        AppEvent::AllTasksFinished => {
            app.state = AppState::Finished;
            app.is_working.store(false, Ordering::SeqCst);
            app.logs.push(String::new());
            app.logs.push("══════════════════════════════════════".to_string());
            if app.failed_tasks.is_empty() {
                app.logs.push("  ✓ All tasks completed successfully.".to_string());
            } else {
                app.logs.push(format!(
                    "  ⚠ Completed with {} issue(s):",
                    app.failed_tasks.len()
                ));
                for t in &app.failed_tasks {
                    app.logs.push(format!("    • {}", t));
                }
            }
            app.logs.push("══════════════════════════════════════".to_string());
            if app.auto_scroll {
                app.log_scroll_offset = app.logs.len().saturating_sub(1);
            }
        }
        AppEvent::Error(e) => {
            app.logs.push(format!("[APP ERROR] {}", e));
        }
    }
}

fn handle_login_key(app: &mut App, code: KeyCode, tx: mpsc::Sender<AppEvent>) {
    match code {
        KeyCode::Esc => {
            let _ = disable_raw_mode();
            let _ = execute!(io::stdout(), LeaveAlternateScreen, DisableMouseCapture);
            std::process::exit(0);
        }
        KeyCode::Enter => {
            if !app.password_input.is_empty() {
                app.try_login(tx);
            }
        }
        KeyCode::Backspace => {
            app.password_input.pop();
        }
        KeyCode::Char(c) => {
            app.password_input.push(c);
        }
        _ => {}
    }
}

fn handle_processing_key(app: &mut App, code: KeyCode) {
    match code {
        KeyCode::Up => {
            app.auto_scroll = false;
            app.log_scroll_offset = app.log_scroll_offset.saturating_sub(1);
        }
        KeyCode::Down => {
            let max = app.logs.len().saturating_sub(1);
            app.log_scroll_offset = (app.log_scroll_offset + 1).min(max);
            if app.log_scroll_offset >= max {
                app.auto_scroll = true;
            }
        }
        KeyCode::Home => {
            app.auto_scroll = false;
            app.log_scroll_offset = 0;
        }
        KeyCode::End => {
            app.auto_scroll = true;
            app.log_scroll_offset = app.logs.len().saturating_sub(1);
        }
        KeyCode::Char('c') | KeyCode::Esc => {
            app.state = AppState::ConfirmCancel;
        }
        _ => {}
    }
}

fn handle_finished_key(app: &mut App, code: KeyCode) -> Result<bool> {
    match code {
        KeyCode::Up => {
            app.auto_scroll = false;
            app.log_scroll_offset = app.log_scroll_offset.saturating_sub(1);
        }
        KeyCode::Down => {
            let max = app.logs.len().saturating_sub(1);
            app.log_scroll_offset = (app.log_scroll_offset + 1).min(max);
        }
        KeyCode::Home => {
            app.auto_scroll = false;
            app.log_scroll_offset = 0;
        }
        KeyCode::End => {
            app.auto_scroll = true;
            app.log_scroll_offset = app.logs.len().saturating_sub(1);
        }
        KeyCode::Char('r') => {
            let _ = Command::new("sudo").args(["reboot"]).spawn();
            return Ok(true);
        }
        KeyCode::Char('s') => {
            let _ = Command::new("sudo").args(["shutdown", "-h", "now"]).spawn();
            return Ok(true);
        }
        KeyCode::Esc | KeyCode::Char('q') | KeyCode::Enter => {
            return Ok(true);
        }
        _ => {}
    }
    Ok(false)
}

fn handle_confirm_cancel_key(app: &mut App, code: KeyCode) {
    match code {
        KeyCode::Char('y') | KeyCode::Char('Y') => {
            app.cancel_current();
            app.state = AppState::Finished;
        }
        KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
            app.state = AppState::Processing;
        }
        _ => {}
    }
}

// --- UI RENDERING ---
fn ui(f: &mut Frame, app: &App) {
    let size = f.size();

    let bg = Block::default().style(Style::default().bg(COLOR_BG));
    f.render_widget(bg, size);

    let vertical = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(10),
            Constraint::Length(3),
        ])
        .margin(1)
        .split(size);

    render_header(f, vertical[0]);
    render_footer(f, vertical[2], app);

    match app.state {
        AppState::Login => render_login(f, vertical[1], app),
        AppState::Processing | AppState::Finished => render_dashboard(f, vertical[1], app),
        AppState::ConfirmCancel => {
            render_dashboard(f, vertical[1], app);
            render_confirm_cancel(f, size);
        }
    }
}

fn render_header(f: &mut Frame, area: Rect) {
    let title = Paragraph::new(" ⬡  HackerOS Updater  ⬡ ")
        .style(
            Style::default()
                .fg(COLOR_ACCENT)
                .add_modifier(Modifier::BOLD),
        )
        .alignment(Alignment::Center)
        .block(
            Block::default()
                .borders(Borders::BOTTOM)
                .border_style(Style::default().fg(COLOR_TEXT_DIM)),
        );
    f.render_widget(title, area);
}

fn render_login(f: &mut Frame, area: Rect, app: &App) {
    let popup_area = centered_rect(60, 50, area);
    f.render_widget(Clear, popup_area);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Thick)
        .title(" [ Security Verification ] ")
        .title_alignment(Alignment::Center)
        .style(Style::default().fg(COLOR_ACCENT));
    f.render_widget(block, popup_area);

    let inner = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Min(1),
        ])
        .margin(2)
        .split(popup_area);

    let info = Paragraph::new("Root privileges are required.\nEnter your sudo password to begin.")
        .style(Style::default().fg(COLOR_TEXT_MAIN))
        .alignment(Alignment::Center);
    f.render_widget(info, inner[1]);

    let stars: String = app.password_input.chars().map(|_| '●').collect();
    let display = format!("{}_", stars);
    let input = Paragraph::new(Span::styled(
        display,
        Style::default()
            .fg(COLOR_ACCENT)
            .add_modifier(Modifier::BOLD),
    ))
    .alignment(Alignment::Center)
    .block(
        Block::default()
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .border_style(Style::default().fg(COLOR_FOCUS))
            .title(" Password "),
    );
    f.render_widget(input, inner[2]);

    if let Some(err) = &app.password_error {
        let err_p = Paragraph::new(format!("⚠ {}", err))
            .style(Style::default().fg(COLOR_ERROR))
            .alignment(Alignment::Center);
        f.render_widget(err_p, inner[3]);
    }
}

fn render_dashboard(f: &mut Frame, area: Rect, app: &App) {
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(10)])
        .split(area);

    let completed = app
        .tasks
        .iter()
        .filter(|t| {
            matches!(
                t.status,
                TaskStatus::Success
                    | TaskStatus::Failed
                    | TaskStatus::Skipped
                    | TaskStatus::Cancelled
            )
        })
        .count();
    let total = app.tasks.len();
    let percent = if total > 0 {
        ((completed as f64 / total as f64) * 100.0) as u16
    } else {
        0
    };

    let failed_count = app.tasks.iter().filter(|t| t.status == TaskStatus::Failed).count();
    let label = if failed_count > 0 {
        format!(" {}/{} — {} failed ", completed, total, failed_count)
    } else {
        format!(" {}/{} ({}%) ", completed, total, percent)
    };

    let gauge_style = if failed_count > 0 {
        Style::default().fg(COLOR_ERROR).bg(Color::Black)
    } else {
        Style::default().fg(COLOR_ACCENT).bg(Color::Black)
    };

    let gauge = Gauge::default()
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .title(" Total Progress ")
                .border_style(Style::default().fg(COLOR_TEXT_DIM)),
        )
        .gauge_style(gauge_style)
        .percent(percent)
        .label(label);
    f.render_widget(gauge, layout[0]);

    let split = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(38), Constraint::Percentage(62)])
        .split(layout[1]);

    // Task list — no asterisk markers
    let task_items: Vec<ListItem> = app
        .tasks
        .iter()
        .map(|t| {
            let (icon, color) = match t.status {
                TaskStatus::Pending   => ("  ○  ", COLOR_TEXT_DIM),
                TaskStatus::Running   => ("  ▶  ", COLOR_ACCENT),
                TaskStatus::Success   => ("  ✓  ", COLOR_SUCCESS),
                TaskStatus::Failed    => ("  ✗  ", COLOR_ERROR),
                TaskStatus::Skipped   => ("  ⚠  ", COLOR_WARN),
                TaskStatus::Cancelled => ("  ⊘  ", COLOR_TEXT_DIM),
            };
            ListItem::new(Line::from(vec![
                Span::styled(icon, Style::default().fg(color)),
                Span::styled(
                    t.name.clone(),
                    Style::default()
                        .fg(if t.status == TaskStatus::Running {
                            COLOR_TEXT_MAIN
                        } else {
                            match t.status {
                                TaskStatus::Success  => COLOR_SUCCESS,
                                TaskStatus::Failed   => COLOR_ERROR,
                                TaskStatus::Skipped  => COLOR_WARN,
                                _                   => COLOR_TEXT_DIM,
                            }
                        })
                        .add_modifier(if t.status == TaskStatus::Running {
                            Modifier::BOLD
                        } else {
                            Modifier::empty()
                        }),
                ),
            ]))
        })
        .collect();

    let task_list = List::new(task_items).block(
        Block::default()
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .title(" Tasks ")
            .border_style(Style::default().fg(COLOR_ACCENT)),
    );
    f.render_widget(task_list, split[0]);

    // Log panel
    let log_inner_width = split[1].width.saturating_sub(2) as usize;
    let log_height = split[1].height.saturating_sub(2) as usize;

    let total_logs = app.logs.len();
    let scroll_row = if app.auto_scroll {
        total_logs.saturating_sub(log_height) as u16
    } else {
        let max_scroll = total_logs.saturating_sub(log_height);
        app.log_scroll_offset.min(max_scroll) as u16
    };

    f.render_widget(Clear, split[1]);

    let log_lines: Vec<Line> = app
        .logs
        .iter()
        .map(|raw| {
            let clean = strip_ansi(raw);
            // Safe truncate at char boundary to avoid UTF-8 panic
            let truncated = truncate_to_width(&clean, log_inner_width);
            let style = if truncated.contains("✗") || truncated.contains("FAILED") || raw.contains("[stderr]") {
                Style::default().fg(COLOR_ERROR)
            } else if truncated.contains("✓") && truncated.contains("OK") {
                Style::default().fg(COLOR_SUCCESS)
            } else if truncated.contains("⚠") || truncated.contains("skipped") {
                Style::default().fg(COLOR_WARN)
            } else if truncated.starts_with("━━━") || truncated.starts_with("══") {
                Style::default().fg(COLOR_ACCENT).add_modifier(Modifier::BOLD)
            } else if raw.starts_with("[stderr]") {
                Style::default().fg(COLOR_WARN)
            } else {
                Style::default().fg(COLOR_TEXT_MAIN)
            };
            Line::from(Span::styled(truncated, style))
        })
        .collect();

    let log_widget = Paragraph::new(log_lines)
        .scroll((scroll_row, 0))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .title(if app.auto_scroll {
                    " Execution Log [auto-scroll] "
                } else {
                    " Execution Log [↑↓ scroll] "
                })
                .border_style(Style::default().fg(COLOR_TEXT_DIM)),
        );
    f.render_widget(log_widget, split[1]);
}

fn render_confirm_cancel(f: &mut Frame, area: Rect) {
    let popup = centered_rect(50, 25, area);
    f.render_widget(Clear, popup);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Thick)
        .title(" Cancel Updates? ")
        .title_alignment(Alignment::Center)
        .style(Style::default().fg(COLOR_ERROR));
    f.render_widget(block, popup);

    let inner = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(1), Constraint::Length(2)])
        .margin(2)
        .split(popup);

    let text = Paragraph::new(
        "The current task will be terminated.\nPartial updates may leave the system in an inconsistent state.\n\nAre you sure? [Y]es / [N]o",
    )
    .style(Style::default().fg(COLOR_TEXT_MAIN))
    .alignment(Alignment::Center);
    f.render_widget(text, inner[0]);
}

fn render_footer(f: &mut Frame, area: Rect, app: &App) {
    let msg = match app.state {
        AppState::Login        => "  Enter: Authenticate  │  Esc: Quit  │  F10: Force Quit  ",
        AppState::Processing   => "  ↑↓: Scroll  │  Home/End: Jump  │  C/Esc: Cancel  │  F10: Force Quit  ",
        AppState::Finished     => "  ↑↓: Scroll  │  R: Reboot  │  S: Shutdown  │  Q/Enter: Quit  ",
        AppState::ConfirmCancel => "  Y: Confirm Cancel  │  N/Esc: Resume  ",
    };
    let footer = Paragraph::new(msg)
        .style(Style::default().fg(COLOR_TEXT_DIM))
        .alignment(Alignment::Center);
    f.render_widget(footer, area);
}

/// Strip ANSI escape sequences from a string.
fn strip_ansi(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if chars.peek() == Some(&'[') {
                chars.next(); // '['
                for cc in chars.by_ref() {
                    if cc.is_ascii_alphabetic() { break; }
                }
            }
        } else if c == '\r' {
            result.clear();
        } else {
            result.push(c);
        }
    }
    result
}

/// Safely truncate a string to at most `max_chars` Unicode scalar values,
/// appending '…' if truncated. Avoids byte-index panics on multi-byte chars.
fn truncate_to_width(s: &str, max_chars: usize) -> String {
    if max_chars == 0 {
        return String::new();
    }
    let char_count = s.chars().count();
    if char_count <= max_chars {
        s.to_string()
    } else {
        // Leave room for the ellipsis character
        let take = max_chars.saturating_sub(1);
        let truncated: String = s.chars().take(take).collect();
        format!("{}…", truncated)
    }
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let vert = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);
    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(vert[1])[1]
}
