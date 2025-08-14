use std::process::{Command, ExitStatus};
use std::env;
use std::os::unix::fs::PermissionsExt;

const APT_PATH: &str = "/usr/lib/HackerOS/apt";

fn print_help() {
    println!("hacker: A simple package management tool for Ubuntu");
    println!("Usage: hacker <command> [arguments]");
    println!("\nAvailable commands:");
    println!(" autoremove    Remove unneeded packages");
    println!(" install       Install one or more packages");
    println!(" remove        Remove one or more packages");
    println!(" purge         Remove one or more packages and their configuration files");
    println!(" list          List installed packages");
    println!(" list-available List all available packages");
    println!(" list-upgradable List packages that can be upgraded");
    println!(" search        Search for packages");
    println!(" clean         Clean package cache");
    println!(" show          Show package information");
    println!(" hold          Prevent a package from being upgraded");
    println!(" unhold        Allow a package to be upgraded");
    println!(" repolist      List enabled repositories");
    println!(" ?             Show this help message");
    println!("\nNote: Use 'hacker-update' for system updates and upgrades.");
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

fn can_run_without_sudo() -> bool {
    // Check if user has write permissions to /usr/lib/HackerOS/apt
    if let Ok(metadata) = std::fs::metadata(APT_PATH) {
        let permissions = metadata.permissions();
        let mode = permissions.mode();
        // Check if executable and writable by user or group
        (mode & 0o111) != 0 && (mode & 0o600) != 0
    } else {
        false
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Error: No command provided");
        print_help();
        std::process::exit(1);
    }
    let command = &args[1];
    let use_sudo = !can_run_without_sudo();

    match command.as_str() {
        "autoremove" => {
            match execute_apt(vec!["autoremove", "-y"], use_sudo) {
                Ok(status) if status.success() => println!("Autoremove completed successfully"),
                Ok(_) => println!("Autoremove failed"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "install" => {
            if args.len() < 3 {
                println!("Error: At least one package name required for install");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["install", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("Package(s) {} installed successfully", packages.join(" ")),
                Ok(_) => println!("Failed to install package(s) {}", packages.join(" ")),
                Err(e) => println!("Error: {}", e),
            }
        }
        "remove" => {
            if args.len() < 3 {
                println!("Error: At least one package name required for remove");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["remove", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("Package(s) {} removed successfully", packages.join(" ")),
                Ok(_) => println!("Failed to remove package(s) {}", packages.join(" ")),
                Err(e) => println!("Error: {}", e),
            }
        }
        "purge" => {
            if args.len() < 3 {
                println!("Error: At least one package name required for purge");
                std::process::exit(1);
            }
            let packages = &args[2..];
            let mut apt_args = vec!["purge", "-y"];
            apt_args.extend(packages.iter().map(|s| s.as_str()));
            match execute_apt(apt_args, use_sudo) {
                Ok(status) if status.success() => println!("Package(s) {} purged successfully", packages.join(" ")),
                Ok(_) => println!("Failed to purge package(s) {}", packages.join(" ")),
                Err(e) => println!("Error: {}", e),
            }
        }
        "list" => {
            match execute_apt(vec!["list", "--installed"], use_sudo) {
                Ok(status) if status.success() => println!("Listed installed packages"),
                Ok(_) => println!("Failed to list packages"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "list-available" => {
            match execute_apt(vec!["list"], use_sudo) {
                Ok(status) if status.success() => println!("Listed available packages"),
                Ok(_) => println!("Failed to list available packages"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "list-upgradable" => {
            match execute_apt(vec!["list", "--upgradable"], use_sudo) {
                Ok(status) if status.success() => println!("Listed upgradable packages"),
                Ok(_) => println!("Failed to list upgradable packages"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "search" => {
            if args.len() < 3 {
                println!("Error: Search term required");
                std::process::exit(1);
            }
            let term = &args[2];
            match execute_apt(vec!["search", term], use_sudo) {
                Ok(status) if status.success() => println!("Search completed"),
                Ok(_) => println!("Search failed"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "clean" => {
            match execute_apt(vec!["clean"], use_sudo) {
                Ok(status) if status.success() => println!("Package cache cleaned successfully"),
                Ok(_) => println!("Failed to clean package cache"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "show" => {
            if args.len() < 3 {
                println!("Error: Package name required for show");
                std::process::exit(1);
            }
            let package = &args[2];
            match execute_apt(vec!["show", package], use_sudo) {
                Ok(status) if status.success() => println!("Package information displayed"),
                Ok(_) => println!("Failed to display package information"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "hold" => {
            if args.len() < 3 {
                println!("Error: Package name required for hold");
                std::process::exit(1);
            }
            let package = &args[2];
            match execute_apt(vec!["hold", package], use_sudo) {
                Ok(status) if status.success() => println!("Package {} set to hold", package),
                Ok(_) => println!("Failed to hold package {}", package),
                Err(e) => println!("Error: {}", e),
            }
        }
        "unhold" => {
            if args.len() < 3 {
                println!("Error: Package name required for unhold");
                std::process::exit(1);
            }
            let package = &args[2];
            match execute_apt(vec!["unhold", package], use_sudo) {
                Ok(status) if status.success() => println!("Package {} set to unhold", package),
                Ok(_) => println!("Failed to unhold package {}", package),
                Err(e) => println!("Error: {}", e),
            }
        }
        "repolist" => {
            match execute_apt(vec!["-o", "Debug::pkgProblemResolver=yes", "update"], use_sudo) {
                Ok(status) if status.success() => println!("Repository list refreshed (use 'less /etc/apt/sources.list' for details)"),
                Ok(_) => println!("Failed to refresh repository list"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "update" | "upgrade" => {
            println!("Error: Use 'hacker-update' for system updates and upgrades.");
            std::process::exit(1);
        }
        "?" => {
            print_help();
        }
        _ => {
            println!("Error: Unknown command '{}'", command);
            print_help();
            std::process::exit(1);
        }
    }
}
