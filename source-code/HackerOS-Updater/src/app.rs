use anyhow::Result;
use crossterm::{
    event::KeyCode,
    execute,
    terminal::{disable_raw_mode, LeaveAlternateScreen},
    event::DisableMouseCapture,
};
use std::{
    io::{self, Write},
    process::{Command, Stdio},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread,
};
use std::sync::mpsc;

use crate::config::Variant;
use crate::tasks::{build_tasks, Task, TaskStatus};
use crate::worker::{run_hnm_task, run_standard_task};
use crate::libc_kill;

// --- EVENTS ---
pub enum AppEvent {
    LogLine(String),
    TaskStatusChange(usize, TaskStatus),
    AllTasksFinished,
    Error(String),
}

// --- APP STATE ---
pub enum AppState {
    Login,
    Processing,
    Finished,
    ConfirmCancel,
}

// --- APP ---
pub struct App {
    pub state: AppState,
    pub password_input: String,
    pub password_error: Option<String>,
    pub tasks: Vec<Task>,
    pub current_task_idx: usize,
    pub logs: Vec<String>,
    pub log_scroll_offset: usize,
    pub auto_scroll: bool,
    pub rx: mpsc::Receiver<AppEvent>,
    pub is_working: Arc<AtomicBool>,
    pub cancel_flag: Arc<AtomicBool>,
    pub current_child_pid: Arc<Mutex<Option<u32>>>,
    pub failed_tasks: Vec<String>,
    pub variant: Variant,
}

impl App {
    pub fn new(rx: mpsc::Receiver<AppEvent>, variant: Variant) -> Self {
        let tasks = build_tasks(&variant);
        Self {
            state: AppState::Login,
            password_input: String::new(),
            password_error: None,
            tasks,
            current_task_idx: 0,
            logs: Vec::new(),
            log_scroll_offset: 0,
            auto_scroll: true,
            rx,
            is_working: Arc::new(AtomicBool::new(false)),
            cancel_flag: Arc::new(AtomicBool::new(false)),
            current_child_pid: Arc::new(Mutex::new(None)),
            failed_tasks: Vec::new(),
            variant,
        }
    }

    pub fn try_login(&mut self, tx: mpsc::Sender<AppEvent>) {
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

    pub fn cancel_current(&mut self) {
        self.cancel_flag.store(true, Ordering::SeqCst);
        if let Ok(guard) = self.current_child_pid.lock() {
            if let Some(pid) = *guard {
                libc_kill(pid as i32, 15); // SIGTERM
            }
        }
        self.logs.push(">>> UPDATE CANCELLED BY USER <<<".to_string());
    }

    pub fn start_updates(&mut self, tx: mpsc::Sender<AppEvent>, password: String) {
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

                if task.is_hnm {
                    run_hnm_task(idx, &task.name, &tx, &cancel_flag, &child_pid);
                    continue;
                }

                run_standard_task(idx, task, &password, &tx, &cancel_flag, &child_pid);
            }

            let _ = tx.send(AppEvent::AllTasksFinished);
        });
    }
}

// --- EVENT HANDLING ---
pub fn handle_app_event(app: &mut App, event: AppEvent) {
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

// --- KEY HANDLERS ---
pub fn handle_login_key(app: &mut App, code: KeyCode, tx: mpsc::Sender<AppEvent>) {
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

pub fn handle_processing_key(app: &mut App, code: KeyCode) {
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

pub fn handle_finished_key(app: &mut App, code: KeyCode) -> Result<bool> {
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

pub fn handle_confirm_cancel_key(app: &mut App, code: KeyCode) {
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
