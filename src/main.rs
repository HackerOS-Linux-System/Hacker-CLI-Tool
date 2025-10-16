use clap::{Parser, Subcommand};
use colored::*;
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
    /// Handle update/upgrade command errors
    Update,
    Upgrade,
}

#[derive(Subcommand)]
enum UnpackCommands {
    /// Install add-ons (Wine, BoxBuddy, Winezgui, Gearlever)
    AddOns,
    /// Install both gaming and cybersecurity tools
    GS,
    /// Install development tools (Atom)
    Devtools,
    /// Install emulators (PlayStation, Nintendo, DOSBox, PS3)
    Emulators,
    /// Install cybersecurity tools (nmap, wireshark, Metasploit, Ghidra, etc.)
    Cybersecurity,
    /// Interactive UI for selecting individual packages
    Select,
    /// Install gaming tools (OBS Studio, Lutris, Steam, etc.) with Roblox
    Gaming,
    /// Install gaming tools without Roblox
    Noroblox,
}

#[derive(Subcommand)]
enum SystemCommands {
    /// Show system logs
    Logs,
}

#[derive(Subcommand)]
enum RunCommands {
    /// Run HackerOS Cockpit
    HackerosCockpit,
    /// Switch to another session
    SwitchToOtherSession,
    /// Update the system
    UpdateSystem,
    /// Check for system updates
    CheckUpdates,
    /// Launch Steam via HackerOS script
    Steam,
    /// Launch HackerOS Launcher
    HackerLauncher,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Unpack { unpack_command } => handle_unpack(unpack_command),
        Commands::Help => display_help(),
        Commands::Install { package } => println!("{}", format!("Install command is a placeholder for: {}", package).yellow()),
        Commands::Remove { package } => println!("{}", format!("Remove command is a placeholder for: {}", package).yellow()),
        Commands::AptInstall { package } => run_command("sudo", vec!["apt", "install", "-y", &package], "Running apt install"),
        Commands::AptRemove { package } => run_command("sudo", vec!["apt", "remove", "-y", &package], "Running apt remove"),
        Commands::FlatpakInstall { package } => run_command("flatpak", vec!["install", "-y", "flathub", &package], "Running flatpak install"),
        Commands::FlatpakRemove { package } => run_command("flatpak", vec!["remove", "-y", &package], "Running flatpak remove"),
        Commands::FlatpakUpdate => run_command("flatpak", vec!["update", "-y"], "Running flatpak update"),
        Commands::System { system_command } => handle_system(system_command),
        Commands::Run { run_command } => handle_run(run_command),
        Commands::Update | Commands::Upgrade => println!("{}", "Unknown command: update/upgrade. Did you mean 'hacker-update'?".red()),
    }
}

fn handle_unpack(unpack_command: UnpackCommands) {
    match unpack_command {
        UnpackCommands::AddOns => {
            println!("{}", "========== Installing Add-Ons ==========".cyan().bold());
            run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command("sudo", vec!["apt", "install", "-y", "wine", "winetricks"], "Installing Wine");
            run_command("flatpak", vec!["install", "-y", "flathub", "io.github.dvlv.boxbuddyrs"], "Installing BoxBuddy");
            run_command("flatpak", vec!["install", "-y", "flathub", "it.mijorus.winezgui"], "Installing Winezgui");
            run_command("flatpak", vec!["install", "-y", "flathub", "it.mijorus.gearlever"], "Installing Gearlever");
            println!("{}", "========== Install Add-Ons Complete ==========".green().bold());
        }
        UnpackCommands::GS => {
            handle_gaming();
            handle_cybersecurity();
        }
        UnpackCommands::Devtools => {
            println!("{}", "========== Installing Atom ==========".cyan().bold());
            run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command("flatpak", vec!["install", "-y", "flathub", "io.atom.Atom"], "Installing Atom");
            println!("{}", "========== Install Dev Tools Complete ==========".green().bold());
        }
        UnpackCommands::Emulators => {
            println!("{}", "========== Installing Emulators ==========".cyan().bold());
            run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command("flatpak", vec!["install", "-y", "flathub", "org.shadps4.shadPS4"], "Installing PlayStation Emulator");
            run_command("flatpak", vec!["install", "-y", "flathub", "io.github.ryubing.Ryujinx"], "Installing Nintendo Emulator");
            run_command("flatpak", vec!["install", "-y", "flathub", "com.dosbox_x.DOSBox-X"], "Installing DOSBox");
            run_command("sudo", vec!["snap", "install", "rpcs3-emu"], "Installing PlayStation 3 Emulator");
            println!("{}", "========== Hacker-Unpack-Emulators Complete ==========".green().bold());
        }
        UnpackCommands::Cybersecurity => {
            handle_cybersecurity();
        }
        UnpackCommands::Select => {
            println!("{}", "Interactive package selection is not yet implemented.".yellow());
        }
        UnpackCommands::Gaming => {
            handle_gaming();
        }
        UnpackCommands::Noroblox => {
            println!("{}", "========== Installing Gaming Tools (No Roblox) ==========".cyan().bold());
            run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
            run_command("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
            run_command("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
            run_command("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
            run_command("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
            println!("{}", "========== Hacker-Unpack-Gaming-NoRoblox Complete ==========".green().bold());
        }
    }
}

fn handle_cybersecurity() {
    println!("{}", "========== Installing Penetration Tools ==========".cyan().bold());
    run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command("sudo", vec!["apt", "install", "-y", "nmap", "wireshark", "nikto", "john", "hydra", "aircrack-ng", "sqlmap", "ettercap-text-only", "tcpdump", "zmap", "bettercap", "wfuzz", "hashcat", "fail2ban", "rkhunter", "chkrootkit", "lynis", "clamav", "tor", "proxychains4", "httrack", "sublist3r", "macchanger", "inxi", "htop", "openvas", "openvpn"], "Installing cybersecurity tools");
    println!("{}", "========== Installing Metasploit Framework ==========".cyan().bold());
    run_command("sudo", vec!["snap", "install", "metasploit-framework"], "Installing Metasploit");
    println!("{}", "========== Installing Ghidra ==========".cyan().bold());
    run_command("flatpak", vec!["install", "-y", "flathub", "org.ghidra_sre.Ghidra"], "Installing Ghidra");
    println!("{}", "========== Hacker-Unpack-Cybersecurity Complete ==========".green().bold());
}

fn handle_gaming() {
    println!("{}", "========== Installing Gaming Tools ==========".cyan().bold());
    run_command("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
    run_command("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
    run_command("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
    run_command("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
    run_command("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
    run_command("flatpak", vec!["install", "--user", "https://sober.vinegarhq.org/sober.flatpakref"], "Installing Roblox");
    run_command("flatpak", vec!["install", "-y", "flathub", "org.vinegarhq.Vinegar"], "Installing Roblox Studio");
    println!("{}", "========== Hacker-Unpack-Gaming Complete ==========".green().bold());
}

fn handle_system(system_command: SystemCommands) {
    match system_command {
        SystemCommands::Logs => {
            println!("{}", "========== System Logs ==========".cyan().bold());
            run_command("sudo", vec!["journalctl", "-xe"], "Displaying system logs");
        }
    }
}

fn handle_run(cmd: RunCommands) {
    match cmd {
        RunCommands::HackerosCockpit => run_command("sudo", vec!["python3", "/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Cockpit/HackerOS-Cockpit.py"], "Running HackerOS Cockpit"),
        RunCommands::SwitchToOtherSession => run_command("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/Switch_To_Other_Session.sh"], "Switching to other session"),
        RunCommands::UpdateSystem => run_command("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/update-system.sh"], "Updating system"),
        RunCommands::CheckUpdates => run_command("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh"], "Checking for updates"),
        RunCommands::Steam => run_command("bash", vec!["/usr/share/HackerOS/Scripts/Steam/HackerOS-Steam.sh"], "Launching Steam"),
        RunCommands::HackerLauncher => run_command("bash", vec!["/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher"], "Launching HackerOS Launcher"),
    }
}

fn run_command(program: &str, args: Vec<&str>, message: &str) {
    println!("{}", format!("{}: {}", message, args.join(" ")).blue());
    let output = Command::new(program)
        .args(&args)
        .output()
        .expect(&format!("Failed to execute {}", program));
    if output.status.success() {
        println!("{}", String::from_utf8_lossy(&output.stdout).green());
    } else {
        println!("{}", String::from_utf8_lossy(&output.stderr).red());
    }
}

fn display_help() {
    println!("{}", "========== Commands List ==========".cyan().bold());
    println!("{}", "hacker unpack add-ons: Install Wine, BoxBuddy, Winezgui, Gearlever".white());
    println!("{}", "hacker unpack g-s: Install gaming and cybersecurity tools".white());
    println!("{}", "hacker unpack devtools: Install Atom".white());
    println!("{}", "hacker unpack emulators: Install PlayStation, Nintendo, DOSBox, PS3 emulators".white());
    println!("{}", "hacker unpack cybersecurity: Install nmap, wireshark, Metasploit, Ghidra, etc.".white());
    println!("{}", "hacker unpack hacker-mode: Install gamescope".white());
    println!("{}", "hacker unpack select: Interactive package selection (not implemented)".white());
    println!("{}", "hacker unpack gaming: Install OBS Studio, Lutris, Steam, Roblox, etc.".white());
    println!("{}", "hacker unpack noroblox: Install gaming tools without Roblox".white());
    println!("{}", "hacker help: Display this help message".white());
    println!("{}", "hacker install <package>: Placeholder for installing packages".white());
    println!("{}", "hacker remove <package>: Placeholder for removing packages".white());
    println!("{}", "hacker apt-install <package>: Run apt install -y <package>".white());
    println!("{}", "hacker apt-remove <package>: Run apt remove -y <package>".white());
    println!("{}", "hacker flatpak-install <package>: Run flatpak install -y flathub <package>".white());
    println!("{}", "hacker flatpak-remove <package>: Run flatpak remove -y <package>".white());
    println!("{}", "hacker flatpak-update: Run flatpak update -y".white());
    println!("{}", "hacker system logs: Show system logs".white());
    println!("{}", "hacker run hackeros-cockpit: Run HackerOS Cockpit".white());
    println!("{}", "hacker run switch-to-other-session: Switch to another session".white());
    println!("{}", "hacker run update-system: Update the system".white());
    println!("{}", "hacker run check-updates: Check for system updates".white());
    println!("{}", "hacker run steam: Launch Steam via HackerOS script".white());
    println!("{}", "hacker run hacker-launcher: Launch HackerOS Launcher".white());
    println!("{}", "========== Instead of sudo apt, you can use hacker ==========".green().bold());
}
