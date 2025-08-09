use std::process::{Command, ExitStatus};
use std::env;

const DNF_PATH: &str = "/usr/lib/HackerOS/dnf";

fn print_help() {
    println!("hacker: A simple package management tool");
    println!("Usage: hacker <command> [arguments]");
    println!("\nAvailable commands:");
    println!("  autoremove         Remove unneeded packages");
    println!("  install <package>  Install a package");
    println!("  remove <package>   Remove a package");
    println!("  list               List installed packages");
    println!("  search <term>      Search for packages");
    println!("  ?                  Show this help message");
    println!("\nNote: Use 'hacker-update' for updates and upgrades.");
}

fn execute_dnf(args: Vec<&str>) -> Result<ExitStatus, String> {
    let output = Command::new(DNF_PATH)
    .args(&args)
    .status()
    .map_err(|e| format!("Failed to execute dnf: {}", e))?;
    Ok(output)
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("Error: No command provided");
        print_help();
        std::process::exit(1);
    }

    let command = &args[1];

    match command.as_str() {
        "autoremove" => {
            match execute_dnf(vec!["autoremove", "-y"]) {
                Ok(status) if status.success() => println!("Autoremove completed successfully"),
                Ok(_) => println!("Autoremove failed"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "install" => {
            if args.len() < 3 {
                println!("Error: Package name required for install");
                std::process::exit(1);
            }
            let package = &args[2];
            match execute_dnf(vec!["install", "-y", package]) {
                Ok(status) if status.success() => println!("Package {} installed successfully", package),
                Ok(_) => println!("Failed to install package {}", package),
                Err(e) => println!("Error: {}", e),
            }
        }
        "remove" => {
            if args.len() < 3 {
                println!("Error: Package name required for remove");
                std::process::exit(1);
            }
            let package = &args[2];
            match execute_dnf(vec!["remove", "-y", package]) {
                Ok(status) if status.success() => println!("Package {} removed successfully", package),
                Ok(_) => println!("Failed to remove package {}", package),
                Err(e) => println!("Error: {}", e),
            }
        }
        "list" => {
            match execute_dnf(vec!["list", "installed"]) {
                Ok(status) if status.success() => println!("Listed installed packages"),
                Ok(_) => println!("Failed to list packages"),
                Err(e) => println!("Error: {}", e),
            }
        }
        "search" => {
            if args.len() < 3 {
                println!("Error: Search term required");
                std::process::exit(1);
            }
            let term = &args[2];
            match execute_dnf(vec!["search", term]) {
                Ok(status) if status.success() => println!("Search completed"),
                Ok(_) => println!("Search failed"),
                Err(e) => println!("Error: {}", e),
            }
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
