use clap::{Parser, Subcommand};
use colored::*;
use hacker::{display_ascii, handle_run, handle_system, handle_unpack, handle_update, play_game, run_command_with_spinner, RunCommands, SystemCommands, UnpackCommands};
use std::process::Command;

#[derive(Parser)]
#[command(name = "hacker", about = "A vibrant CLI tool for managing hacker tools, gaming, and system utilities", version = "1.0.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Unpack various toolsets and applications
    Unpack {
        #[command(subcommand)]
        unpack_command: UnpackCommands,
    },
    /// Display help information and list available commands
    Help,
    /// Display help UI
    HelpUi,
    /// Placeholder for install command
    Install {
        package: String,
    },
    /// Placeholder for remove command
    Remove {
        package: String,
    },
    /// Run apt install or sudo apt install -y
    AptInstall {
        package: String,
    },
    /// Run apt remove or sudo apt remove -y
    AptRemove {
        package: String,
    },
    /// Run flatpak install -y
    FlatpakInstall {
        package: String,
    },
    /// Run flatpak remove -y
    FlatpakRemove {
        package: String,
    },
    /// Run flatpak update -y
    FlatpakUpdate,
    /// System-related commands
    System {
        #[command(subcommand)]
        system_command: SystemCommands,
    },
    /// Run specific HackerOS scripts and applications
    Run {
        #[command(subcommand)]
        run_command: RunCommands,
    },
    /// Update the system
    Update,
    /// Play a simple terminal game
    Game,
    /// Information about Hacker programming language
    HackerLang,
    /// Display HackerOS ASCII art
    Ascii,
    /// Enter interactive Hacker shell mode
    Shell,
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Unpack { unpack_command } => handle_unpack(unpack_command),
        Commands::Help => {
            let home = std::env::var("HOME").unwrap_or_default();
            let help_bin = format!("{}/.hackeros/hacker-help", home);
            match Command::new(&help_bin).status() {
                Ok(status) => {
                    if !status.success() {
                        println!("{}", "Error running hacker-help. Ensure it's installed and executable in ~/.hackeros/".red().bold().on_black());
                    }
                }
                Err(e) => {
                    println!("{}", format!("Failed to execute hacker-help: {}", e).red().bold().on_black());
                }
            }
        }
        Commands::HelpUi => {
            let home = std::env::var("HOME").unwrap_or_default();
            let help_bin = format!("{}/.hackeros/hacker-help", home);
            match Command::new(&help_bin).status() {
                Ok(status) => {
                    if !status.success() {
                        println!("{}", "Error running hacker-help. Ensure it's installed and executable in ~/.hackeros/".red().bold().on_black());
                    }
                }
                Err(e) => {
                    println!("{}", format!("Failed to execute hacker-help: {}", e).red().bold().on_black());
                }
            }
        }
        Commands::Install { package } => println!("{}", format!("Install command is a placeholder for: {}", package).yellow().bold().on_black()),
        Commands::Remove { package } => println!("{}", format!("Remove command is a placeholder for: {}", package).yellow().bold().on_black()),
        Commands::AptInstall { package } => run_command_with_spinner("sudo", vec!["apt", "install", "-y", &package], "Running apt install"),
        Commands::AptRemove { package } => run_command_with_spinner("sudo", vec!["apt", "remove", "-y", &package], "Running apt remove"),
        Commands::FlatpakInstall { package } => run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", &package], "Running flatpak install"),
        Commands::FlatpakRemove { package } => run_command_with_spinner("flatpak", vec!["remove", "-y", &package], "Running flatpak remove"),
        Commands::FlatpakUpdate => run_command_with_spinner("flatpak", vec!["update", "-y"], "Running flatpak update"),
        Commands::System { system_command } => handle_system(system_command),
        Commands::Run { run_command } => handle_run(run_command),
        Commands::Update => handle_update(),
        Commands::Game => play_game(),
        Commands::HackerLang => {
            println!("{}", "========== Hacker Programming Language ==========".magenta().bold().on_black());
            println!("{}", "To use the hacker programming language for files/scripts with .hacker extension,".cyan().bold().on_black());
            println!("{}", "use the command 'hackerc' to compile or run them.".cyan().bold().on_black());
            println!("{}", "Note: This is for advanced users. Ensure hackerc is installed separately.".yellow().bold().on_black());
            println!("{}", "========== End of Info ==========".magenta().bold().on_black());
        }
        Commands::Ascii => display_ascii(),
        Commands::Shell => {
            let home = std::env::var("HOME").unwrap_or_default();
            let shell_bin = format!("{}/.hackeros/hacker-shell", home);
            match Command::new(&shell_bin).status() {
                Ok(status) => {
                    if !status.success() {
                        println!("{}", "Error running hacker-shell. Ensure it's installed and executable in ~/.hackeros/".red().bold().on_black());
                    }
                }
                Err(e) => {
                    println!("{}", format!("Failed to execute hacker-shell: {}", e).red().bold().on_black());
                }
            }
        }
    }
}
