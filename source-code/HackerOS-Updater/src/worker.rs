use anyhow::Result;
use std::{
    io::{BufRead, BufReader, Write},
    process::{Command, Stdio},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    thread,
};

use crate::app::AppEvent;
use crate::config::detect_variant;
use crate::tasks::{build_tasks, Task, TaskStatus};

// ── Headless mode ─────────────────────────────────────────────────────────────

/// Run all update tasks without a TUI (no terminal attached).
pub fn run_headless() -> Result<()> {
    let variant = detect_variant();
    let tasks = build_tasks(&variant);
    let log_path = "/tmp/hackeros-updater.log";
    let mut log_file = std::fs::File::create(log_path)?;

    writeln!(log_file, "=== HackerOS Updater (headless mode) ===")?;
    writeln!(log_file, "Detected variant: {:?}", variant)?;

    for task in &tasks {
        writeln!(log_file, "--- {} ---", task.name)?;

        if task.is_hnm {
            run_hnm_headless(&mut log_file)?;
            continue;
        }

        let mut cmd = build_cmd(task);
        cmd.stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(Stdio::null());

        match cmd.output() {
            Ok(out) => {
                let _ = log_file.write_all(&out.stdout);
                let _ = log_file.write_all(&out.stderr);
                if out.status.success() {
                    writeln!(log_file, "OK")?;
                } else {
                    writeln!(
                        log_file,
                        "FAILED (exit {})",
                             out.status.code().unwrap_or(-1)
                    )?;
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

/// Build the correct Command for a non-hnm task (without password injection).
fn build_cmd(task: &Task) -> Command {
    if task.is_sudo {
        let mut c = Command::new("sudo");
        c.args(["-n", "bash", "-c", &task.command]);
        c
    } else {
        let mut c = Command::new("bash");
        c.args(["-c", &task.command]);
        c
    }
}

// ── TUI task runners ───────────────────────────────────────────────────────────

/// Run the HackerOS Nix Manager task (multi-step hnm logic).
pub fn run_hnm_task(
    idx: usize,
    task_name: &str,
    tx: &std::sync::mpsc::Sender<AppEvent>,
    cancel_flag: &Arc<AtomicBool>,
    child_pid: &Arc<Mutex<Option<u32>>>,
) {
    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // 1. hnm check — capture output to detect NOT FOUND
    let check_output = Command::new("hnm").arg("check").output();

    let nix_found = match check_output {
        Ok(out) => {
            let combined = String::from_utf8_lossy(&out.stdout).to_string()
            + &String::from_utf8_lossy(&out.stderr);
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
        run_hnm_subcmd(&["unpack"], tx, cancel_flag, child_pid);
    }

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // 3. hnm update
    run_hnm_subcmd(&["update"], tx, cancel_flag, child_pid);

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    // 4. hnm upgrade
    run_hnm_subcmd(&["upgrade"], tx, cancel_flag, child_pid);

    if cancel_flag.load(Ordering::SeqCst) {
        let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Cancelled));
        return;
    }

    let _ = tx.send(AppEvent::TaskStatusChange(idx, TaskStatus::Success));
    let _ = tx.send(AppEvent::LogLine(format!("✓ {} — OK", task_name)));
    let _ = tx.send(AppEvent::LogLine(String::new()));
}

fn run_hnm_subcmd(
    args: &[&str],
    tx: &std::sync::mpsc::Sender<AppEvent>,
    cancel_flag: &Arc<AtomicBool>,
    child_pid: &Arc<Mutex<Option<u32>>>,
) -> Option<std::process::ExitStatus> {
    if cancel_flag.load(Ordering::SeqCst) {
        return None;
    }
    let _ = tx.send(AppEvent::LogLine(format!(
        "[hnm] Running: hnm {}",
        args.join(" ")
    )));

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
                    if cf_out.load(Ordering::SeqCst) {
                        break;
                    }
                    if let Ok(l) = line {
                        let _ = tx_out.send(AppEvent::LogLine(l));
                    }
                }
            });
            let h_err = thread::spawn(move || {
                let reader = BufReader::new(stderr);
                for line in reader.lines() {
                    if cf_err.load(Ordering::SeqCst) {
                        break;
                    }
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
}

/// Run a standard (non-hnm) task with live output streaming.
pub fn run_standard_task(
    idx: usize,
    task: &Task,
    password: &str,
    tx: &std::sync::mpsc::Sender<AppEvent>,
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
                    if cancel_out.load(Ordering::SeqCst) {
                        break;
                    }
                    if let Ok(l) = line {
                        let _ = tx_out.send(AppEvent::LogLine(l));
                    }
                }
            });

            let h_err = thread::spawn(move || {
                let reader = BufReader::new(stderr);
                for line in reader.lines() {
                    if cancel_err.load(Ordering::SeqCst) {
                        break;
                    }
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
                    let _ = tx.send(AppEvent::LogLine(format!(
                        "✗ {} — error: {}",
                        task.name, e
                    )));
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
