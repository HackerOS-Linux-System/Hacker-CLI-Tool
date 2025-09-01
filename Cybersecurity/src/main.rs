use std::process::{Command, ExitStatus};
use std::env;
use std::os::unix::fs::PermissionsExt;
use colored::*;
use std::io::{self, Write};
use std::thread;
use std::time::Duration;

const APT_PATH: &str = "/usr/lib/HackerOS/apt";
const VERSION: &str = "1.0.2";

fn print_help() {
    println!("{}", "HackerOS Package Manager".bold().green());
    println!("Version: {}", VERSION);
    println!("{}", "A simple and fast package management tool for Debian".italic());
    println!("\n{}", "Usage:".bold());
    println!(" hacker <command> [arguments]");
    println!("\n{}", "Available Commands:".bold());
    let commands = [
        ("autoremove", "Remove unneeded packages"),
        ("install", "Install one or more packages"),
        ("remove", "Remove one or more packages"),
        ("purge", "Remove packages and their configuration files"),
        ("list", "List installed packages"),
        ("list-available", "List all available packages"),
        ("list-upgradable", "List packages that can be upgraded"),
        ("search", "Search for packages"),
        ("clean", "Clean package cache"),
        ("show", "Show package information"),
        ("hold", "Prevent a package from being upgraded"),
        ("unhold", "Allow a package to be upgraded"),
        ("repolist", "List enabled repositories"),
        ("check", "Check for broken dependencies"),
        ("entry", "Launch HackerOS cybersecurity container"),
        ("version", "Show tool version"),
        ("?", "Show this help message"),
    ];
    for (cmd, desc) in commands.iter() {
        println!(" {:<16} {}", cmd.bold().cyan(), desc);
    }
    println!("\n{}", "Note:".bold());
    println!(" Use 'hacker-update' for system updates and upgrades.");
    println!(" Run commands with '--help' for detailed usage (e.g., 'hacker install --help').");
}

fn print_progress(message: &str) {
    print!("{}", message);
    io::stdout().flush().unwrap();
    for _ in 0..3 {
        thread::sleep(Duration::from_millis(500));
        print!("{}", ".".yellow());
        io::stdout().flush().unwrap();
    }
    println!();
}

fn execute_apt(args: Vec<&str>, use_sudo: bool) -> Result<ExitStatus, String> {
    let mut command = if use_sudo {
        let mut cmd = Command::new("sudo");
        cmd.arg(APT_PATH);
        cmd
    } else {
        Command::new(APT_PATH)
    };
    let output = command
    .args(&args)
    .status()
    .map_err(|e| format!("Failed to execute apt: {}", e))?;
    Ok(output)
}

fn execute_entry() -> Result<ExitStatus, String> {
    let output = Command::new("podman")
    .args(["start", "-ai", "hackeros-cybersecurity"])
    .status()
    .map_err(|e| format!("Failed to execute podman: {}", e))?;
    Ok(output)
}

fn can_run_without_sudo() -> bool {
    if let Ok(metadata) = std::fs::metadata(APT_PATH) {
        let permissions = metadata.permissions();
        let mode = permissions.mode();
        (mode & 0o111) != 0 && (mode & 0o600) != 0
    } else {
        false
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("{}", "Error: No command provided".red());
        print_help();
        std::process::exit(1);
    }
    let command = &args[1];
    let use_sudo = !can_run_without_sudo();
    match command.as_str() {
        "autoremove" => {
            print_progress("Running autoremove");
            match execute_apt(vec!["autoremove", "-y"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Autoremove completed successfully".green()),
                Ok(_) => println!("{}", "Autoremove failed".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "install" => {
            if args.len() < 3 {
                println!("{}", "Error: At least one package name required for install".red());
                println!("Usage: hacker install <package1> [package2 ...]");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["install", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            print_progress(&format!("Installing {} ", packages.join(" ")));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("{}", format!("Package(s) {} installed successfully", packages.join(" ")).green()),
                Ok(_) => println!("{}", format!("Failed to install package(s) {}", packages.join(" ")).red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "remove" => {
            if args.len() < 3 {
                println!("{}", "Error: At least one package name required for remove".red());
                println!("Usage: hacker remove <package1> [package2 ...]");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["remove", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            print_progress(&format!("Removing {} ", packages.join(" ")));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("{}", format!("Package(s) {} removed successfully", packages.join(" ")).green()),
                Ok(_) => println!("{}", format!("Failed to remove package(s) {}", packages.join(" ")).red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "purge" => {
            if args.len() < 3 {
                println!("{}", "Error: At least one package name required for purge".red());
                println!("Usage: hacker purge <package1> [package2 ...]");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["purge", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            print_progress(&format!("Purging {} ", packages.join(" ")));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("{}", format!("Package(s) {} purged successfully", packages.join(" ")).green()),
                Ok(_) => println!("{}", format!("Failed to purge package(s) {}", packages.join(" ")).red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "list" => {
            print_progress("Listing installed packages");
            match execute_apt(vec!["list", "--installed"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Listed installed packages".green()),
                Ok(_) => println!("{}", "Failed to list packages".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "list-available" => {
            print_progress("Listing available packages");
            match execute_apt(vec!["list"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Listed available packages".green()),
                Ok(_) => println!("{}", "Failed to list available packages".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "list-upgradable" => {
            print_progress("Listing upgradable packages");
            match execute_apt(vec!["list", "--upgradable"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Listed upgradable packages".green()),
                Ok(_) => println!("{}", "Failed to list upgradable packages".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "search" => {
            if args.len() < 3 {
                println!("{}", "Error: Search term required".red());
                println!("Usage: hacker search <term>");
                std::process::exit(1);
            }
            let term = &args[2];
            print_progress(&format!("Searching for {}", term));
            match execute_apt(vec!["search", term], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Search completed".green()),
                Ok(_) => println!("{}", "Search failed".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "clean" => {
            print_progress("Cleaning package cache");
            match execute_apt(vec!["clean"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Package cache cleaned successfully".green()),
                Ok(_) => println!("{}", "Failed to clean package cache".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "show" => {
            if args.len() < 3 {
                println!("{}", "Error: Package name required for show".red());
                println!("Usage: hacker show <package>");
                std::process::exit(1);
            }
            let package = &args[2];
            print_progress(&format!("Showing info for {}", package));
            match execute_apt(vec!["show", package], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Package information displayed".green()),
                Ok(_) => println!("{}", "Failed to display package information".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "hold" => {
            if args.len() < 3 {
                println!("{}", "Error: Package name required for hold".red());
                println!("Usage: hacker hold <package>");
                std::process::exit(1);
            }
            let package = &args[2];
            print_progress(&format!("Holding package {}", package));
            match execute_apt(vec!["hold", package], use_sudo) {
                Ok(status) if status.success() => println!("{}", format!("Package {} set to hold", package).green()),
                Ok(_) => println!("{}", format!("Failed to hold package {}", package).red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "unhold" => {
            if args.len() < 3 {
                println!("{}", "Error: Package name required for unhold".red());
                println!("Usage: hacker unhold <package>");
                std::process::exit(1);
            }
            let package = &args[2];
            print_progress(&format!("Unholding package {}", package));
            match execute_apt(vec!["unhold", package], use_sudo) {
                Ok(status) if status.success() => println!("{}", format!("Package {} set to unhold", package).green()),
                Ok(_) => println!("{}", format!("Failed to unhold package {}", package).red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "repolist" => {
            print_progress("Refreshing repository list");
            match execute_apt(vec!["-o", "Debug::pkgProblemResolver=yes", "update"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Repository list refreshed (use 'less /etc/apt/sources.list' for details)".green()),
                Ok(_) => println!("{}", "Failed to refresh repository list".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "check" => {
            print_progress("Checking for broken dependencies");
            match execute_apt(vec!["check"], use_sudo) {
                Ok(status) if status.success() => println!("{}", "Dependency check completed successfully".green()),
                Ok(_) => println!("{}", "Dependency check found issues".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "entry" => {
            print_progress("Launching HackerOS cybersecurity container");
            match execute_entry() {
                Ok(status) if status.success() => println!("{}", "HackerOS cybersecurity container launched successfully".green()),
                Ok(_) => println!("{}", "Failed to launch HackerOS cybersecurity container".red()),
                Err(e) => println!("{} {}", "Error:".red(), e),
            }
        }
        "version" => {
            println!("{}", format!("HackerOS Package Manager v{}", VERSION).bold().green());
        }
        "update" | "upgrade" => {
            println!("{}", "Error: Use 'hacker-update' for system updates and upgrades.".red());
            std::process::exit(1);
        }
        "?" => {
            print_help();
        }
        _ => {
            println!("{}", format!("Error: Unknown command '{}'", command).red());
            print_help();
            std::process::exit(1);
        }
    }
}
