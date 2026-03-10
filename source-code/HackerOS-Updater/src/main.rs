use anyhow::Result;
use crossterm::{
	event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
	execute,
	terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
	backend::CrosstermBackend,
	layout::{Alignment, Constraint, Direction, Layout, Rect},
	style::{Color, Modifier, Style, Stylize},
	text::{Line, Span},
	widgets::{Block, BorderType, Borders, Clear, Gauge, List, ListItem, Paragraph, Wrap},
	Frame, Terminal,
};
use std::{
	env,
	io::{self, BufRead, BufReader},
	process::{Command, Stdio},
	sync::{
		atomic::{AtomicBool, Ordering},
		Arc,
	},
	time::Duration,
};
use tokio::sync::mpsc;

// --- CONFIGURATION ---
const HACKEROS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh";
const WALLPAPERS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh";

// --- THEME ---
// Paleta kolorów "Cyberpunk / Modern Purple"
const COLOR_BG: Color = Color::Reset;
const COLOR_ACCENT: Color = Color::Magenta; // Fioletowy akcent
const COLOR_FOCUS: Color = Color::Yellow;   // Kolor aktywnego pola (input)
const COLOR_TEXT_MAIN: Color = Color::White;
const COLOR_TEXT_DIM: Color = Color::DarkGray;
const COLOR_SUCCESS: Color = Color::Green;
const COLOR_ERROR: Color = Color::Red;

// --- DATA STRUCTURES ---

#[derive(Clone, Debug, PartialEq)]
enum TaskStatus {
	Pending,
	Running,
	Success,
	Failed,
}

#[derive(Clone, Debug)]
struct Task {
	name: String,
	command: String,
	is_sudo: bool,
	status: TaskStatus,
}

enum AppState {
	Login,
	Processing,
	Finished,
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

	// Logi i przewijanie
	logs: Vec<String>,
	log_scroll_offset: u16,
	auto_scroll: bool,

	rx: mpsc::Receiver<AppEvent>,
	is_working: Arc<AtomicBool>,
}

// --- MAIN ---

#[tokio::main]
async fn main() -> Result<()> {
	// 1. Argument Parsing: Check for --with-gui
	let args: Vec<String> = env::args().collect();
	if args.contains(&"--with-gui".to_string()) {
		// Get absolute path to the current executable
		if let Ok(current_exe) = env::current_exe() {
			// Spawn Alacritty running this binary (without the flag to avoid loop)
			Command::new("alacritty")
			.arg("-e")
			.arg(current_exe)
			.spawn()
			.expect("Failed to launch alacritty");
			// Exit the parent process immediately
			return Ok(());
		}
	}

	// 2. Standard TUI Startup
	enable_raw_mode()?;
	let mut stdout = io::stdout();
	execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
	let backend = CrosstermBackend::new(stdout);
	let mut terminal = Terminal::new(backend)?;

	// Create Channel for async communication
	let (tx, rx) = mpsc::channel(100);

	// Initial App State
	let mut app = App::new(rx);

	// Run App Loop
	let res = run_app(&mut terminal, &mut app, tx).await;

	// Restore Terminal
	disable_raw_mode()?;
	execute!(
		terminal.backend_mut(),
			 LeaveAlternateScreen,
			 DisableMouseCapture
	)?;
	terminal.show_cursor()?;

	if let Err(err) = res {
		println!("Application Error: {:?}", err);
	}

	Ok(())
}

impl App {
	fn new(rx: mpsc::Receiver<AppEvent>) -> Self {
		Self {
			state: AppState::Login,
			password_input: String::new(),
			password_error: None,
			tasks: vec![
				Task {
					name: "System Update (APT)".to_string(),
					command: "apt update && apt upgrade -y && apt autoremove -y".to_string(),
					is_sudo: true,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Flatpak Update".to_string(),
					command: "flatpak update -y".to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Snap Updates".to_string(),
					command: "snap refresh".to_string(),
					is_sudo: true,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Brew Updates".to_string(),
					command: r#"
					if ! command -v brew &> /dev/null; then
						echo "Brew not found. Installing...";
					NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
					(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.zshrc;
					eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)";
					else
						echo "Brew detected.";
					fi && brew update && brew upgrade && brew cleanup
					"#.to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Firmware Update".to_string(),
					command: "fwupdmgr update".to_string(),
					is_sudo: true,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Zsh Update".to_string(),
					command: "zsh -c "source ~/.zshrc && omz update""
".to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Distrobox".to_string(),
					command: "distrobox-upgrade --all".to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
				Task {
					name: "HackerOS Update".to_string(),
					command: HACKEROS_UPDATE_SCRIPT.to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
				Task {
					name: "Wallpapers Updates".to_string(),
					command: WALLPAPERS_UPDATE_SCRIPT.to_string(),
					is_sudo: false,
					status: TaskStatus::Pending,
				},
			],
			current_task_idx: 0,
			logs: Vec::new(),
			log_scroll_offset: 0,
			auto_scroll: true,
			rx,
			is_working: Arc::new(AtomicBool::new(false)),
		}
	}

	fn try_login(&mut self, tx: mpsc::Sender<AppEvent>) {
		let password = self.password_input.clone();

		let output = Command::new("sudo")
		.arg("-S")
		.arg("-v")
		.stdin(Stdio::piped())
		.stderr(Stdio::piped())
		.stdout(Stdio::null())
		.spawn();

		match output {
			Ok(mut child) => {
				if let Some(mut stdin) = child.stdin.take() {
					use std::io::Write;
					let _ = stdin.write_all(format!("{}\n", password).as_bytes());
				}
				match child.wait() {
					Ok(status) if status.success() => {
						self.state = AppState::Processing;
						self.password_error = None;
						self.start_updates(tx, password);
					}
					_ => {
						self.password_input.clear();
						self.password_error = Some("Incorrect password.".to_string());
					}
				}
			}
			Err(e) => {
				self.password_error = Some(format!("System error: {}", e));
			}
		}
	}

	fn start_updates(&mut self, tx: mpsc::Sender<AppEvent>, password: String) {
		let tasks = self.tasks.clone();
		self.is_working.store(true, Ordering::SeqCst);

		tokio::spawn(async move {
			for (idx, task) in tasks.iter().enumerate() {
				let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Running)).await;
				let _ = tx.send(AppEvent::LogLine(format!(">>> STARTED: {}", task.name))).await;

				let mut cmd_builder = if task.is_sudo {
					let mut c = Command::new("sudo");
					c.arg("-S");
					c.arg("bash").arg("-c").arg(&task.command);
					c
				} else {
					let mut c = Command::new("bash");
					c.arg("-c").arg(&task.command);
					c
				};

				cmd_builder.stdout(Stdio::piped());
				cmd_builder.stderr(Stdio::piped());
				cmd_builder.stdin(Stdio::piped());

				match cmd_builder.spawn() {
					Ok(mut child) => {
						if task.is_sudo {
							if let Some(mut stdin) = child.stdin.take() {
								use std::io::Write;
								let _ = stdin.write_all(format!("{}\n", password).as_bytes());
							}
						}

						let stdout = child.stdout.take().expect("Failed to open stdout");
						let stderr = child.stderr.take().expect("Failed to open stderr");
						let tx_clone = tx.clone();
						let tx_clone_err = tx.clone();

						let h1 = tokio::task::spawn_blocking(move || {
							let reader = BufReader::new(stdout);
							for line in reader.lines() {
								if let Ok(l) = line {
									let _ = tx_clone.blocking_send(AppEvent::LogLine(l));
								}
							}
						});

						let h2 = tokio::task::spawn_blocking(move || {
							let reader = BufReader::new(stderr);
							for line in reader.lines() {
								if let Ok(l) = line {
									if !l.contains("[sudo] password") {
										let _ = tx_clone_err.blocking_send(AppEvent::LogLine(format!("STDERR: {}", l)));
									}
								}
							}
						});

						let status = child.wait();
						let _ = h1.await;
						let _ = h2.await;

						match status {
							Ok(s) if s.success() => {
								let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Success)).await;
							}
							_ => {
								let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Failed)).await;
							}
						}
					}
					Err(e) => {
						let _ = tx.send(AppEvent::LogLine(format!("EXEC ERROR: {}", e))).await;
						let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Failed)).await;
					}
				}
				let _ = tx.send(AppEvent::LogLine(format!(">>> FINISHED: {}\n", task.name))).await;
			}
			let _ = tx.send(AppEvent::AllTasksFinished).await;
		});
	}
}

async fn run_app<B: ratatui::backend::Backend>(
	terminal: &mut Terminal<B>,
	app: &mut App,
	tx: mpsc::Sender<AppEvent>,
) -> Result<()> {
	loop {
		terminal.draw(|f| ui(f, app))?;

		while let Ok(event) = app.rx.try_recv() {
			match event {
				AppEvent::LogLine(line) => {
					app.logs.push(line);
					if app.auto_scroll {
						app.log_scroll_offset = 0;
					}
				}
				AppEvent::TaskStatusChange(idx, status) => {
					if idx < app.tasks.len() {
						app.tasks[idx].status = status;
						app.current_task_idx = idx;
					}
				}
				AppEvent::AllTasksFinished => {
					app.state = AppState::Finished;
					app.is_working.store(false, Ordering::SeqCst);
					app.logs.push("----------------------------------------".to_string());
					app.logs.push(" All tasks completed successfully.".to_string());
					app.logs.push("----------------------------------------".to_string());
				}
				AppEvent::Error(e) => {
					app.logs.push(format!("APP ERROR: {}", e));
				}
			}
		}

		if crossterm::event::poll(Duration::from_millis(50))? {
			if let Event::Key(key) = event::read()? {
				if key.kind != KeyEventKind::Press {
					continue;
				}
				if key.code == KeyCode::F(10) { return Ok(()); }

				match app.state {
					AppState::Login => match key.code {
						KeyCode::Esc => return Ok(()),
						KeyCode::Enter => {
							if !app.password_input.is_empty() {
								app.try_login(tx.clone());
							}
						}
						KeyCode::Backspace => { app.password_input.pop(); }
						KeyCode::Char(c) => { app.password_input.push(c); }
						_ => {}
					},
					AppState::Processing | AppState::Finished => {
						match key.code {
							KeyCode::Up => {
								app.auto_scroll = false;
								app.log_scroll_offset = app.log_scroll_offset.saturating_add(1);
							}
							KeyCode::Down => {
								app.log_scroll_offset = app.log_scroll_offset.saturating_sub(1);
								if app.log_scroll_offset == 0 { app.auto_scroll = true; }
							}
							KeyCode::Home => {
								app.auto_scroll = false;
								app.log_scroll_offset = u16::MAX;
							}
							KeyCode::End => {
								app.auto_scroll = true;
								app.log_scroll_offset = 0;
							}
							KeyCode::Esc | KeyCode::Char('q') => {
								if let AppState::Finished = app.state { return Ok(()); }
								return Ok(());
							}
							KeyCode::Char('r') if matches!(app.state, AppState::Finished) => {
								let _ = Command::new("sudo").args(["-S", "reboot"]).spawn();
								return Ok(());
							}
							KeyCode::Char('s') if matches!(app.state, AppState::Finished) => {
								let _ = Command::new("sudo").args(["-S", "shutdown", "-h", "now"]).spawn();
								return Ok(());
							}
							_ => {}
						}
					}
				}
			}
		}
	}
}

// --- UI RENDERING ---

fn ui(f: &mut Frame, app: &App) {
	let size = f.size();

	let bg_block = Block::default().style(Style::default().bg(COLOR_BG));
	f.render_widget(bg_block, size);

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
	}
}

fn render_header(f: &mut Frame, area: Rect) {
	let title = Paragraph::new("HackerOS Updater")
	.style(Style::default().fg(COLOR_ACCENT).add_modifier(Modifier::BOLD))
	.alignment(Alignment::Center)
	.block(
		Block::default()
		.borders(Borders::BOTTOM)
		.border_style(Style::default().fg(COLOR_TEXT_DIM))
	);
	f.render_widget(title, area);
}

fn render_login(f: &mut Frame, area: Rect, app: &App) {
	// FIX: Zwiększono obszar popupu, aby upewnić się, że elementy inputu
	// są widoczne nawet na mniejszych terminalach. (45% wysokości)
	let popup_area = centered_rect(60, 45, area);
	f.render_widget(Clear, popup_area);

	// Główna ramka
	let block = Block::default()
	.borders(Borders::ALL)
	.border_type(BorderType::Thick)
	.title(" [ Security Verification ] ")
	.title_alignment(Alignment::Center)
	.style(Style::default().fg(COLOR_ACCENT));

	f.render_widget(block, popup_area);

	let inner_layout = Layout::default()
	.direction(Direction::Vertical)
	.constraints([
		Constraint::Length(4), // Text
				 Constraint::Length(3), // Input box
				 Constraint::Min(1),    // Error space
	])
	.margin(2)
	.split(popup_area);

	// Opis
	let text = Paragraph::new("Root privileges are required to perform system updates.\nPlease enter your sudo password below.")
	.style(Style::default().fg(COLOR_TEXT_MAIN))
	.alignment(Alignment::Center)
	.wrap(Wrap { trim: true });
	f.render_widget(text, inner_layout[0]);

	// Input Box (Poprawa widoczności)
	// Generowanie gwiazdek
	let mut stars: String = app.password_input.chars().map(|_| '*').collect();
	// Dodanie "kursora" aby użytkownik widział aktywność
	stars.push('█');

	// Używamy koloru FOCUS (żółty) dla ramki inputu, aby się wyróżniała
	let input_block = Block::default()
	.borders(Borders::ALL)
	.border_type(BorderType::Rounded)
	.border_style(Style::default().fg(COLOR_FOCUS));

	let input = Paragraph::new(Span::styled(stars, Style::default().fg(COLOR_ACCENT).add_modifier(Modifier::BOLD)))
	.alignment(Alignment::Center)
	.block(input_block);

	f.render_widget(input, inner_layout[1]);

	if let Some(err) = &app.password_error {
		let err_text = Paragraph::new(format!("Error: {}", err))
		.style(Style::default().fg(COLOR_ERROR))
		.alignment(Alignment::Center);
		f.render_widget(err_text, inner_layout[2]);
	}
}

fn render_dashboard(f: &mut Frame, area: Rect, app: &App) {
	let layout = Layout::default()
	.direction(Direction::Vertical)
	.constraints([
		Constraint::Length(3), // Progress
				 Constraint::Min(10),   // Content
	])
	.split(area);

	// 1. Progress Gauge (Naprawa obliczeń + Etykieta)
	// Zadanie zakończone to sukces LUB porażka (bo program idzie dalej)
	let completed_count = app.tasks.iter().filter(|t|
	t.status == TaskStatus::Success || t.status == TaskStatus::Failed
	).count();
	let total_count = app.tasks.len();

	let percent = if total_count > 0 {
		((completed_count as f64 / total_count as f64) * 100.0) as u16
	} else {
		0
	};

	let label = format!(" Progress: {}/{} ({}%) ", completed_count, total_count, percent);

	let gauge = Gauge::default()
	.block(Block::default()
	.borders(Borders::ALL)
	.border_type(BorderType::Rounded)
	.title(" Total Progress ")
	.border_style(Style::default().fg(COLOR_TEXT_DIM)))
	.gauge_style(Style::default().fg(COLOR_ACCENT).bg(Color::Black))
	.percent(percent)
	.label(label);

	f.render_widget(gauge, layout[0]);

	// 2. Content
	let content_split = Layout::default()
	.direction(Direction::Horizontal)
	.constraints([
		Constraint::Percentage(40), // Task List
				 Constraint::Percentage(60), // Logs
	])
	.split(layout[1]);

	// Left: Tasks
	let tasks: Vec<ListItem> = app.tasks.iter().map(|t| {
		let (icon, color, style) = match t.status {
			TaskStatus::Pending => (" [..] ", COLOR_TEXT_DIM, Style::default()),
													TaskStatus::Running => (" [>>] ", COLOR_ACCENT, Style::default().add_modifier(Modifier::BOLD)),
													TaskStatus::Success => (" [OK] ", COLOR_SUCCESS, Style::default()),
													TaskStatus::Failed => (" [!!] ", COLOR_ERROR, Style::default()),
		};

		ListItem::new(Line::from(vec![
			Span::styled(format!(" {} ", icon), Style::default().fg(color)),
								 Span::styled(t.name.clone(), style.fg(COLOR_TEXT_MAIN)),
		]))
	}).collect();

	let task_list = List::new(tasks)
	.block(
		Block::default()
		.borders(Borders::ALL)
		.border_type(BorderType::Rounded)
		.title(" Update Tasks ")
		.border_style(Style::default().fg(COLOR_ACCENT))
	);
	f.render_widget(task_list, content_split[0]);

	// Right: Logs
	let log_height = content_split[1].height.saturating_sub(2);
	let total_logs = app.logs.len() as u16;

	let scroll_pos = if app.auto_scroll {
		if total_logs > log_height { total_logs - log_height } else { 0 }
	} else {
		if total_logs > log_height {
			let max_scroll = total_logs - log_height;
			max_scroll.saturating_sub(app.log_scroll_offset)
		} else {
			0
		}
	};

	let log_text = app.logs.join("\n");
	let logs_widget = Paragraph::new(log_text)
	.wrap(Wrap { trim: false })
	.style(Style::default().fg(COLOR_TEXT_MAIN))
	.scroll((scroll_pos, 0))
	.block(
		Block::default()
		.borders(Borders::ALL)
		.border_type(BorderType::Rounded)
		.title(" Execution Log ")
		.border_style(Style::default().fg(COLOR_TEXT_DIM))
	);
	f.render_widget(logs_widget, content_split[1]);
}

fn render_footer(f: &mut Frame, area: Rect, app: &App) {
	let msg = match app.state {
		AppState::Login => "Enter: Login / Esc: Quit",
		AppState::Processing => "Processing... / Up-Down: Scroll Logs",
		AppState::Finished => "Done / R: Reboot / S: Shutdown / Q: Quit",
	};

	let footer = Paragraph::new(msg)
	.style(Style::default().fg(COLOR_TEXT_DIM))
	.alignment(Alignment::Center);
	f.render_widget(footer, area);
}

// Utility
fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
	let popup_layout = Layout::default()
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
	.split(popup_layout[1])[1]
}
