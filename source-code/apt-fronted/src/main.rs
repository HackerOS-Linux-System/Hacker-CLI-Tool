use clap::{Parser, Subcommand};
use indicatif::{ProgressBar, ProgressStyle};
use std::process::{Command, Stdio};
use std::io::{self, BufRead};
use std::thread;
use std::time::Duration;
use colored::*;

#[derive(Parser)]
#[command(name = "apt-fronted")]
#[command(about = "A pretty frontend for apt package manager", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Install a package
    Install {
        /// Name of the package to install
        package: String,
    },
    /// Remove a package
    Remove {
        /// Name of the package to remove
        package: String,
    },
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Install { package } => {
            println!("{}", format!("Installing package: {}", package).green().bold());
            run_apt_command("install", &package);
        }
        Commands::Remove { package } => {
            println!("{}", format!("Removing package: {}", package).red().bold());
            run_apt_command("remove", &package);
        }
    }
}

fn capitalize(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => String::new(),
        Some(f) => f.to_uppercase().collect::<String>() + chars.as_str(),
    }
}

fn run_apt_command(action: &str, package: &str) {
    // Create a stylish progress bar with spinner
    let pb = ProgressBar::new_spinner();
    pb.enable_steady_tick(Duration::from_millis(80));
    pb.set_style(
        ProgressStyle::default_spinner()
        .tick_strings(&[
            "🌑 ", "🌒 ", "🌓 ", "🌔 ", "🌕 ", "🌖 ", "🌗 ", "🌘 ", "🌑 ",
        ])
        .template("{spinner:.green} {msg:.cyan.bold}")
        .unwrap(),
    );
    pb.set_message(format!("Running apt {} {}...", action, package));

    // Spawn the apt command with sudo
    let mut child = Command::new("sudo")
    .arg("apt")
    .arg(action)
    .arg("-y")
    .arg(package)
    .stdout(Stdio::piped())
    .stderr(Stdio::piped())
    .spawn()
    .expect("Failed to execute apt command");

    // Handle output in a separate thread to keep spinner updating
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let stdout_thread = thread::spawn(move || {
        let reader = io::BufReader::new(stdout);
        for line in reader.lines() {
            if let Ok(line) = line {
                println!("{}", line.yellow());
            }
        }
    });

    let stderr_thread = thread::spawn(move || {
        let reader = io::BufReader::new(stderr);
        for line in reader.lines() {
            if let Ok(line) = line {
                eprintln!("{}", line.red());
            }
        }
    });

    // Wait for the command to finish
    let status = child.wait().expect("Failed to wait on child");

    stdout_thread.join().unwrap();
    stderr_thread.join().unwrap();

    pb.finish_with_message(if status.success() {
        format!("{} completed successfully!", capitalize(action)).green().to_string()
    } else {
        format!("{} failed with exit code {:?}", capitalize(action), status.code()).red().to_string()
    });
}

