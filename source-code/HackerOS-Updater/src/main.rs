use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Frame, Terminal};
use std::{
    env,
    io::{self, Write},
    process::{Command, Stdio},
    sync::mpsc,
    time::Duration,
};

mod app;
mod config;
mod tasks;
mod ui;
mod worker;

use app::{App, AppEvent, AppState};
use config::detect_variant;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.contains(&"--with-gui".to_string()) {
        if let Ok(current_exe) = env::current_exe() {
            let _ = Command::new("alacritty")
            .arg("-e")
            .arg(current_exe)
            .spawn();
            return Ok(());
        }
    }

    if !is_tty() {
        worker::run_headless()?;
        return Ok(());
    }

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let (tx, rx) = mpsc::channel::<AppEvent>();
    let variant = detect_variant();
    let mut app = App::new(rx, variant);

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

fn is_tty() -> bool {
    use std::os::unix::io::AsRawFd;
    unsafe { libc::isatty(io::stdout().as_raw_fd()) == 1 }
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
    tx: mpsc::Sender<AppEvent>,
) -> Result<()> {
    loop {
        terminal.draw(|f: &mut Frame| ui::render(f, app))?;

        loop {
            match app.rx.try_recv() {
                Ok(event) => app::handle_app_event(app, event),
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
                    AppState::Login => app::handle_login_key(app, key.code, tx.clone()),
                    AppState::Processing => app::handle_processing_key(app, key.code),
                    AppState::Finished => {
                        if app::handle_finished_key(app, key.code)? {
                            return Ok(());
                        }
                    }
                    AppState::ConfirmCancel => app::handle_confirm_cancel_key(app, key.code),
                }
            }
        }
    }
}

/// Safe SIGTERM wrapper
#[cfg(unix)]
pub fn libc_kill(pid: i32, sig: i32) {
    unsafe {
        libc::kill(pid, sig);
    }
}
#[cfg(not(unix))]
pub fn libc_kill(_pid: i32, _sig: i32) {}
