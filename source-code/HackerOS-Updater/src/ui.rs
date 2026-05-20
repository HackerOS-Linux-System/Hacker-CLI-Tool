use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Clear, Gauge, List, ListItem, Paragraph},
    Frame,
};

use crate::app::{App, AppState};
use crate::tasks::{
    COLOR_ACCENT, COLOR_BG, COLOR_ERROR, COLOR_FOCUS, COLOR_SUCCESS, COLOR_TEXT_DIM,
    COLOR_TEXT_MAIN, COLOR_WARN, TaskStatus,
};
use ratatui::style::Color;

pub fn render(f: &mut Frame, app: &App) {
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

    let info = Paragraph::new(
        "Root privileges are required.\nEnter your sudo password to begin.",
    )
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

    let failed_count = app
    .tasks
    .iter()
    .filter(|t| t.status == TaskStatus::Failed)
    .count();
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

    // Task list
    let task_items: Vec<ListItem> = app
    .tasks
    .iter()
    .map(|t| {
        let (icon, color) = match t.status {
            TaskStatus::Pending => ("  ○  ", COLOR_TEXT_DIM),
         TaskStatus::Running => ("  ▶  ", COLOR_ACCENT),
         TaskStatus::Success => ("  ✓  ", COLOR_SUCCESS),
         TaskStatus::Failed => ("  ✗  ", COLOR_ERROR),
         TaskStatus::Skipped => ("  ⚠  ", COLOR_WARN),
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
                                                      TaskStatus::Success => COLOR_SUCCESS,
                                                      TaskStatus::Failed => COLOR_ERROR,
                                                      TaskStatus::Skipped => COLOR_WARN,
                                                      _ => COLOR_TEXT_DIM,
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
        let truncated = truncate_to_width(&clean, log_inner_width);
        let style = if truncated.contains('✗')
        || truncated.contains("FAILED")
        || raw.contains("[stderr]")
        {
            Style::default().fg(COLOR_ERROR)
        } else if truncated.contains('✓') && truncated.contains("OK") {
            Style::default().fg(COLOR_SUCCESS)
        } else if truncated.contains('⚠') || truncated.contains("skipped") {
            Style::default().fg(COLOR_WARN)
        } else if truncated.starts_with("━━━") || truncated.starts_with("══") {
            Style::default()
            .fg(COLOR_ACCENT)
            .add_modifier(Modifier::BOLD)
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
        AppState::Login => "  Enter: Authenticate  │  Esc: Quit  │  F10: Force Quit  ",
        AppState::Processing => {
            "  ↑↓: Scroll  │  Home/End: Jump  │  C/Esc: Cancel  │  F10: Force Quit  "
        }
        AppState::Finished => {
            "  ↑↓: Scroll  │  R: Reboot  │  S: Shutdown  │  Q/Enter: Quit  "
        }
        AppState::ConfirmCancel => "  Y: Confirm Cancel  │  N/Esc: Resume  ",
    };
    let footer = Paragraph::new(msg)
    .style(Style::default().fg(COLOR_TEXT_DIM))
    .alignment(Alignment::Center);
    f.render_widget(footer, area);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn strip_ansi(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if chars.peek() == Some(&'[') {
                chars.next();
                for cc in chars.by_ref() {
                    if cc.is_ascii_alphabetic() {
                        break;
                    }
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

fn truncate_to_width(s: &str, max_chars: usize) -> String {
    if max_chars == 0 {
        return String::new();
    }
    let char_count = s.chars().count();
    if char_count <= max_chars {
        s.to_string()
    } else {
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
