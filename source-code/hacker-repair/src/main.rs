use anyhow::{Context, Result};
use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use log::info;
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    Frame, Terminal,
};
use regex::Regex;
use signal_hook::{consts::SIGINT, iterator::Signals};
use std::{
    collections::VecDeque,
    fs::{File, OpenOptions},
    io::{self, BufRead, BufReader, Write},
    path::Path,
    process::{Command, Stdio},
    sync::{
        mpsc::{channel, Receiver, Sender},
        Arc, Mutex,
    },
    thread,
    time::{Duration, Instant},
};
use libc;

#[derive(PartialEq, Clone, Copy)]
enum Stage {
    MainMenu,
    Checklist,
    TimeshiftMenu,
    Processing,
    OutputView,
}

#[derive(Clone)]
struct Item {
    title: String,
    desc: String,
    action: fn(&mut Model) -> Result<()>,
    selected: bool,
}

struct Model {
    stage: Stage,
    items: Vec<Item>,
    list_state: ListState,
    output: VecDeque<String>,
    sender: Sender<String>,
    receiver: Receiver<String>,
    spinner_idx: usize,
    current_cmd: Arc<Mutex<Option<std::process::Child>>>,
    title: String,
}
impl Model {
    fn new(sender: Sender<String>, receiver: Receiver<String>) -> Self {
        let mut m = Model {
            stage: Stage::MainMenu,
            items: vec![],
            list_state: ListState::default(),
            output: VecDeque::new(),
            sender,
            receiver,
            spinner_idx: 0,
            current_cmd: Arc::new(Mutex::new(None)),
            title: "Menu Główne".to_string(),
        };
        m.reset_main_menu();
        m.list_state.select(Some(0));
        m
    }
    fn reset_main_menu(&mut self) {
        self.items = get_main_items();
        self.title = "Menu Główne".to_string();
    }
    fn reset_checklist(&mut self) {
        self.items = get_repair_items();
        self.title = "Wybierz operacje do wykonania (space aby zaznaczyć, enter aby uruchomić)".to_string();
    }
    fn reset_timeshift(&mut self) {
        self.items = get_timeshift_items();
        self.title = "Menu Timeshift".to_string();
    }
}
fn main() -> Result<()> {
    // Check root
    if unsafe { libc::geteuid() } != 0 {
        println!("This program requires root privileges. Please run with sudo.");
        std::process::exit(1);
    }
    // Log setup
    let log_path = Path::new("/var/log/hacker-repair.log");
    let log_file = OpenOptions::new()
    .append(true)
    .create(true)
    .open(log_path)
    .context("Failed to open log file")?;
    let logger = env_logger::Builder::new()
    .format(|buf, record| writeln!(buf, "{}: {}", record.level(), record.args()))
    .target(env_logger::Target::Pipe(Box::new(log_file)))
    .build();
    log::set_boxed_logger(Box::new(logger))?;
    log::set_max_level(log::LevelFilter::Info);
    info!("Starting hacker-repair");
    // Signals
    let mut signals = Signals::new([SIGINT])?;
    thread::spawn(move || {
        for sig in signals.forever() {
            info!("Received signal {:?}", sig);
            std::process::exit(0);
        }
    });
    // TUI setup
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    let (sender, receiver) = channel::<String>();
    let mut model = Model::new(sender.clone(), receiver);
    let tick_rate = Duration::from_millis(250);
    let mut last_tick = Instant::now();
    loop {
        terminal.draw(|f| ui(f, &mut model))?;
        let timeout = tick_rate
        .checked_sub(last_tick.elapsed())
        .unwrap_or_else(|| Duration::from_secs(0));
        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    handle_key(&mut model, key.code)?;
                }
            }
        }
        while let Ok(line) = model.receiver.try_recv() {
            if line == "done" {
                model.stage = Stage::OutputView;
            } else {
                model.output.push_back(line);
                if model.output.len() > 1000 {
                    model.output.pop_front();
                }
            }
        }
        if last_tick.elapsed() >= tick_rate {
            if model.stage == Stage::Processing {
                model.spinner_idx = (model.spinner_idx + 1) % 4;
            }
            last_tick = Instant::now();
        }
        if model.stage == Stage::OutputView && model.output.iter().any(|l| l.contains("Błąd") || l.contains("Error")) {
            // Handle error style, but in text
        }
    }
}
fn handle_key(model: &mut Model, code: KeyCode) -> Result<()> {
    match code {
        KeyCode::Char('q') => {
            disable_raw_mode()?;
            execute!(io::stdout(), LeaveAlternateScreen)?;
            std::process::exit(0);
        }
        KeyCode::Down => {
            let i = match model.list_state.selected() {
                Some(i) => {
                    if i >= model.items.len() - 1 {
                        0
                    } else {
                        i + 1
                    }
                }
                None => 0,
            };
            model.list_state.select(Some(i));
        }
        KeyCode::Up => {
            let i = match model.list_state.selected() {
                Some(i) => {
                    if i == 0 {
                        model.items.len() - 1
                    } else {
                        i - 1
                    }
                }
                None => 0,
            };
            model.list_state.select(Some(i));
        }
        KeyCode::Enter => handle_enter(model)?,
        KeyCode::Char(' ') if model.stage == Stage::Checklist => {
            if let Some(i) = model.list_state.selected() {
                model.items[i].selected = !model.items[i].selected;
            }
        }
        KeyCode::Esc => {
            if model.stage == Stage::Processing {
                let mut cmd_guard = model.current_cmd.lock().unwrap();
                if let Some(cmd) = cmd_guard.as_mut() {
                    cmd.kill()?;
                }
                *cmd_guard = None;
                model.output.push_back("Operacja przerwana.".to_string());
                model.stage = Stage::OutputView;
            } else if model.stage == Stage::OutputView || model.stage == Stage::Checklist || model.stage == Stage::TimeshiftMenu {
                model.stage = Stage::MainMenu;
                model.reset_main_menu();
                model.list_state.select(Some(0));
            }
        }
        _ => {}
    }
    Ok(())
}
fn handle_enter(model: &mut Model) -> Result<()> {
    let selected_idx = model.list_state.selected().unwrap_or(0);
    let selected = &model.items[selected_idx];
    match model.stage {
        Stage::MainMenu => match selected.title.as_str() {
            "Rozpocznij diagnostykę (wybierz operacje)" => {
                model.stage = Stage::Checklist;
                model.reset_checklist();
            }
            "Nie wiem, co jest nie tak - automatyczne skanowanie i naprawa" => {
                model.stage = Stage::Processing;
                model.output.clear();
                let sender = model.sender.clone();
                let current_cmd = model.current_cmd.clone();
                thread::spawn(move || {
                    let items = get_repair_items();
                    let (_dummy_sender, dummy_receiver) = channel();
                    let mut dummy = Model::new(sender.clone(), dummy_receiver);
                    dummy.current_cmd = current_cmd;
                    for item in items {
                        sender.send(format!("### Starting: {}", item.title)).unwrap();
                        if let Err(e) = (item.action)(&mut dummy) {
                            sender.send(format!("Error: {}", e)).unwrap();
                        }
                    }
                    sender.send("done".to_string()).unwrap();
                });
            }
            "Zarządzanie Timeshift (snapshoty systemu)" => {
                model.stage = Stage::TimeshiftMenu;
                model.reset_timeshift();
            }
            "Wyjdź" => {
                disable_raw_mode()?;
                execute!(io::stdout(), LeaveAlternateScreen)?;
                std::process::exit(0);
            }
            _ => {}
        },
        Stage::TimeshiftMenu => match selected.title.as_str() {
            "Utwórz nowy snapshot" => run_timeshift(model, &["--create"])?,
            "Przywróć snapshot" => run_timeshift(model, &["--restore"])?,
            "Lista snapshotów" => run_timeshift(model, &["--list"])?,
            "Wróć" => {
                model.stage = Stage::MainMenu;
                model.reset_main_menu();
            }
            _ => {}
        },
        Stage::Checklist => {
            model.stage = Stage::Processing;
            model.output.clear();
            let sender = model.sender.clone();
            let current_cmd = model.current_cmd.clone();
            let items = model.items.clone();
            thread::spawn(move || {
                let (_dummy_sender, dummy_receiver) = channel();
                let mut dummy = Model::new(sender.clone(), dummy_receiver);
                dummy.current_cmd = current_cmd;
                for item in items.into_iter().filter(|i| i.selected) {
                    sender.send(format!("### Starting: {}", item.title)).unwrap();
                    if let Err(e) = (item.action)(&mut dummy) {
                        sender.send(format!("Error: {}", e)).unwrap();
                    }
                }
                sender.send("done".to_string()).unwrap();
            });
        }
        Stage::OutputView => {
            model.stage = Stage::MainMenu;
            model.reset_main_menu();
        }
        _ => {}
    }
    Ok(())
}
fn ui(f: &mut Frame, model: &mut Model) {
    let chunks = Layout::default()
    .direction(Direction::Vertical)
    .constraints([Constraint::Length(3), Constraint::Min(0)])
    .split(f.size());
    let title = Paragraph::new("Hacker-Repair: Narzędzie do naprawy systemu Debian")
    .style(Style::default().fg(Color::White).bg(Color::Magenta).add_modifier(Modifier::BOLD))
    .alignment(ratatui::layout::Alignment::Center);
    f.render_widget(title, chunks[0]);
    match model.stage {
        Stage::MainMenu | Stage::Checklist | Stage::TimeshiftMenu => {
            let items: Vec<ListItem> = model.items.iter().map(|i| {
                let prefix = if i.selected { "[x] " } else { "[ ] " };
                ListItem::new(Line::from(vec![Span::styled(prefix.to_string() + &i.title, Style::default().fg(Color::White))] ))
            }).collect();
            let list = List::new(items)
            .block(Block::default().title(model.title.clone()).borders(Borders::ALL))
            .highlight_style(Style::default().fg(Color::Magenta).add_modifier(Modifier::BOLD));
            f.render_stateful_widget(list, chunks[1], &mut model.list_state);
        }
        Stage::Processing => {
            let sub_chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(10), Constraint::Percentage(90)])
                .split(chunks[1]);
            let spinner = ["-", "\\", "|", "/"][model.spinner_idx];
            let p = Paragraph::new(spinner.to_string()).block(Block::default().title("Przetwarzanie...").borders(Borders::ALL));
            f.render_widget(p, sub_chunks[0]);
            let output_text = Text::from(model.output.iter().cloned().collect::<Vec<_>>().join("\n"));
            let vp = Paragraph::new(output_text).wrap(Wrap { trim: false }).scroll((model.output.len() as u16, 0)).block(Block::default().borders(Borders::ALL));
            f.render_widget(vp, sub_chunks[1]);
        }
        Stage::OutputView => {
            let output_text = Text::from(model.output.iter().cloned().collect::<Vec<_>>().join("\n"));
            let style = if model.output.iter().any(|l| l.contains("Błąd") || l.contains("Error")) {
                Style::default().fg(Color::Red)
            } else {
                Style::default().fg(Color::Green)
            };
            let p = Paragraph::new(output_text).style(style).block(Block::default().title("Wynik operacji").borders(Borders::ALL));
            f.render_widget(p, chunks[1]);
        }
    }
}
fn run_and_stream(model: &mut Model, cmd_str: &str, args: &[&str]) -> Result<()> {
    let mut cmd = Command::new(cmd_str);
    cmd.args(args);
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::piped());
    let child = cmd.spawn()?;
    let mut guard = model.current_cmd.lock().unwrap();
    *guard = Some(child);
    drop(guard);
    let mut guard = model.current_cmd.lock().unwrap();
    let child_ref = guard.as_mut().unwrap();
    let stdout = child_ref.stdout.take().unwrap();
    let stderr = child_ref.stderr.take().unwrap();
    drop(guard);
    let sender = model.sender.clone();
    let stdout_thread = thread::spawn(move || {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            sender.send(line.unwrap() + "\n").unwrap();
        }
    });
    let sender2 = model.sender.clone();
    let stderr_thread = thread::spawn(move || {
        let reader = BufReader::new(stderr);
        for line in reader.lines() {
            sender2.send(line.unwrap() + "\n").unwrap();
        }
    });
    let mut guard = model.current_cmd.lock().unwrap();
    let status = guard.as_mut().unwrap().wait()?;
    drop(guard);
    stdout_thread.join().unwrap();
    stderr_thread.join().unwrap();
    if !status.success() {
        return Err(anyhow::anyhow!("Command failed with status: {}", status));
    }
    Ok(())
}
fn get_main_items() -> Vec<Item> {
    vec![
        Item { title: "Rozpocznij diagnostykę (wybierz operacje)".to_string(), desc: "Wybierz, co chcesz sprawdzić/naprawić".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Nie wiem, co jest nie tak - automatyczne skanowanie i naprawa".to_string(), desc: "Narzędzie samo sprawdzi i naprawi typowe problemy".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Zarządzanie Timeshift (snapshoty systemu)".to_string(), desc: "Twórz, przywracaj snapshoty".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Wyjdź".to_string(), desc: "Zamknij program".to_string(), action: |_| Ok(()), selected: false },
    ]
}
fn get_timeshift_items() -> Vec<Item> {
    vec![
        Item { title: "Utwórz nowy snapshot".to_string(), desc: "Stwórz punkt przywracania".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Przywróć snapshot".to_string(), desc: "Przywróć system do poprzedniego stanu".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Lista snapshotów".to_string(), desc: "Wyświetl dostępne snapshoty".to_string(), action: |_| Ok(()), selected: false },
        Item { title: "Wróć".to_string(), desc: "Powrót do menu głównego".to_string(), action: |_| Ok(()), selected: false },
    ]
}
fn get_repair_items() -> Vec<Item> {
    vec![
        Item { title: "Napraw pakiety".to_string(), desc: "apt update, install -f, dpkg --configure -a".to_string(), action: fix_packages, selected: false },
        Item { title: "Napraw boot loader".to_string(), desc: "update-grub".to_string(), action: repair_boot, selected: false },
        Item { title: "Sprawdź dysk".to_string(), desc: "Porada nt. fsck".to_string(), action: check_disk, selected: false },
        Item { title: "Aktualizuj system".to_string(), desc: "apt upgrade -y".to_string(), action: upgrade_system, selected: false },
        Item { title: "Sprawdź miejsce na dysku".to_string(), desc: "df / i /var".to_string(), action: check_disk_space, selected: false },
        Item { title: "Diagnostyka sieci".to_string(), desc: "Pingi i status resolved".to_string(), action: network_diag, selected: false },
        Item { title: "Analiza logów".to_string(), desc: "Szukaj kluczowych błędów".to_string(), action: parse_logs, selected: false },
        Item { title: "Czyszczenie systemu".to_string(), desc: "apt clean, autoremove, vacuum journal".to_string(), action: clean_system, selected: false },
        Item { title: "Reset stacku sieciowego".to_string(), desc: "Restart NetworkManager, czyszczenie routingu, DHCP".to_string(), action: reset_network_stack, selected: false },
        Item { title: "Edytuj /etc/resolv.conf".to_string(), desc: "Przełącz DNS".to_string(), action: edit_resolv, selected: false },
        Item { title: "Sprawdź blokady RF".to_string(), desc: "Diagnostyka rfkill".to_string(), action: check_rfkill, selected: false },
    ]
}
fn repair_boot(m: &mut Model) -> Result<()> {
    run_and_stream(m, "update-grub", &[])
}
fn check_disk(m: &mut Model) -> Result<()> {
    m.sender.send("Sprawdzam dysk (wymaga ręcznej interwencji dla root).".to_string()).unwrap();
    m.sender.send("Użyj fsck na odmontowanym dysku.".to_string()).unwrap();
    Ok(())
}
fn upgrade_system(m: &mut Model) -> Result<()> {
    run_and_stream(m, "apt", &["upgrade", "-y"])
}
fn fix_packages(m: &mut Model) -> Result<()> {
    m.sender.send("Running apt update".to_string())?;
    run_and_stream(m, "apt", &["update"])?;
    m.sender.send("Running apt install -f".to_string())?;
    run_and_stream(m, "apt", &["install", "-f"])?;
    m.sender.send("Running dpkg --configure -a".to_string())?;
    run_and_stream(m, "dpkg", &["--configure", "-a"])?;
    Ok(())
}
fn check_disk_space(m: &mut Model) -> Result<()> {
    let out_root = Command::new("df").arg("-h").arg("/").output()?.stdout;
    m.sender.send(String::from("Disk space for /:") + std::str::from_utf8(&out_root)?)?;
    // Parse for 100%
    let lines = std::str::from_utf8(&out_root)?.lines().collect::<Vec<_>>();
    if lines.len() > 1 {
        let fields = lines[1].split_whitespace().collect::<Vec<_>>();
        if fields.len() > 4 && fields[4] == "100%" {
            m.sender.send("Warning: Partition / is 100% full!".to_string())?;
        }
    }
    let out_var = Command::new("df").arg("-h").arg("/var").output()?.stdout;
    m.sender.send(String::from("Disk space for /var:") + std::str::from_utf8(&out_var)?)?;
    let lines = std::str::from_utf8(&out_var)?.lines().collect::<Vec<_>>();
    if lines.len() > 1 {
        let fields = lines[1].split_whitespace().collect::<Vec<_>>();
        if fields.len() > 4 && fields[4] == "100%" {
            m.sender.send("Warning: Partition /var is 100% full!".to_string())?;
        }
    }
    Ok(())
}
fn network_diag(m: &mut Model) -> Result<()> {
    let route_out = Command::new("ip").args(["route", "get", "8.8.8.8"]).output()?.stdout;
    let route_str = std::str::from_utf8(&route_out)?;
    let fields = route_str.split_whitespace().collect::<Vec<_>>();
    let mut gateway = "";
    for (i, f) in fields.iter().enumerate() {
        if *f == "via" && i + 1 < fields.len() {
            gateway = fields[i + 1];
            break;
        }
    }
    if gateway.is_empty() {
        m.sender.send("No default gateway found.".to_string())?;
    } else {
        let out_gw = Command::new("ping").args(["-c", "1", gateway]).output()?.stdout;
        m.sender.send(String::from("Ping to gateway:") + std::str::from_utf8(&out_gw)?)?;
        if std::str::from_utf8(&out_gw)?.contains("1 received") {
            m.sender.send("Ping to gateway OK.".to_string())?;
        } else {
            m.sender.send("Ping to gateway failed.".to_string())?;
        }
    }
    let out_dns = Command::new("ping").args(["-c", "1", "8.8.8.8"]).output()?.stdout;
    m.sender.send(String::from("Ping to Google DNS:") + std::str::from_utf8(&out_dns)?)?;
    if std::str::from_utf8(&out_dns)?.contains("1 received") {
        m.sender.send("Ping to Google DNS OK.".to_string())?;
    } else {
        m.sender.send("Ping to Google DNS failed.".to_string())?;
    }
    let status = Command::new("systemctl").args(["status", "systemd-resolved"]).output()?.stdout;
    m.sender.send(String::from("systemd-resolved status:") + std::str::from_utf8(&status)?)?;
    if std::str::from_utf8(&status)?.contains("active (running)") {
        m.sender.send("systemd-resolved OK.".to_string())?;
    } else {
        m.sender.send("systemd-resolved has issues.".to_string())?;
    }
    Ok(())
}
fn parse_logs(m: &mut Model) -> Result<()> {
    let logs = Command::new("journalctl").args(["-p", "err", "-n", "100"]).output()?.stdout;
    let logs_str = std::str::from_utf8(&logs)?;
    m.sender.send(String::from("Last 100 error logs:") + logs_str)?;
    let keywords = vec!["Hardware Error", "Out of memory", "Failed to mount"];
    let mut found = vec![];
    for kw in keywords {
        let re = Regex::new(&format!("(?i){}", kw))?;
        if re.is_match(logs_str) {
            found.push(kw);
        }
    }
    if !found.is_empty() {
        m.sender.send(String::from("Found critical keywords: ") + &found.join(", "))?;
    } else {
        m.sender.send("No critical keywords found.".to_string())?;
    }
    Ok(())
}
fn clean_system(m: &mut Model) -> Result<()> {
    m.sender.send("Running apt clean".to_string())?;
    run_and_stream(m, "apt", &["clean"])?;
    m.sender.send("Running apt autoremove -y".to_string())?;
    run_and_stream(m, "apt", &["autoremove", "-y"])?;
    m.sender.send("Running journalctl --vacuum-time=7d".to_string())?;
    run_and_stream(m, "journalctl", &["--vacuum-time=7d"])?;
    Ok(())
}
fn run_timeshift(m: &mut Model, args: &[&str]) -> Result<()> {
    m.stage = Stage::Processing;
    m.output.clear();
    m.sender.send(format!("Running timeshift {}", args.join(" ")))?;
    run_and_stream(m, "timeshift", args)?;
    m.stage = Stage::OutputView;
    Ok(())
}
fn reset_network_stack(m: &mut Model) -> Result<()> {
    m.sender.send("Restarting NetworkManager".to_string())?;
    run_and_stream(m, "systemctl", &["restart", "NetworkManager"])?;
    m.sender.send("Clearing routing table".to_string())?;
    run_and_stream(m, "ip", &["route", "flush", "table", "main"])?;
    m.sender.send("Renewing DHCP lease".to_string())?;
    run_and_stream(m, "dhclient", &["-r"])?;
    run_and_stream(m, "dhclient", &[])?;
    Ok(())
}
fn edit_resolv(m: &mut Model) -> Result<()> {
    // Simple switch, assume switching to Google DNS
    m.sender.send("Switching to Google DNS".to_string())?;
    let mut file = File::create("/etc/resolv.conf")?;
    file.write_all(b"nameserver 8.8.8.8\n")?;
    Ok(())
    // For more, could ask for choice, but for simplicity
}
fn check_rfkill(m: &mut Model) -> Result<()> {
    let out = Command::new("rfkill").arg("list").output()?.stdout;
    m.sender.send(String::from("rfkill status:") + std::str::from_utf8(&out)?)?;
    if std::str::from_utf8(&out)?.contains("blocked: yes") {
        m.sender.send("WiFi is blocked. Use rfkill unblock wifi to enable.".to_string())?;
    }
    Ok(())
}
