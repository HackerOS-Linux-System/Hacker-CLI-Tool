use colored::*;
use crate::utils::{handle_cybersecurity, handle_gaming, run_command_with_progress};
use crate::UnpackCommands;
use crate::SystemCommands;
use crate::RunCommands;
use std::io::{self, BufRead};
use std::fs::{self, File};
use chrono::{DateTime, Utc, Duration as ChronoDuration};

pub fn handle_unpack(unpack_command: UnpackCommands) {
    match unpack_command {
        UnpackCommands::AddOns => {
            println!("{}", "========== Installing Add-Ons ==========".cyan().bold().on_black());
            run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_progress("sudo", vec!["apt", "install", "-y", "wine", "winetricks"], "Installing Wine");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "io.github.dvlv.boxbuddyrs"], "Installing BoxBuddy");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "it.mijorus.winezgui"], "Installing Winezgui");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "it.mijorus.gearlever"], "Installing Gearlever");
            println!("{}", "========== Install Add-Ons Complete ==========".green().bold().on_black());
        }
        UnpackCommands::GS => {
            handle_gaming();
            handle_cybersecurity();
        }
        UnpackCommands::Devtools => {
            println!("{}", "========== Installing Atom ==========".cyan().bold().on_black());
            run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "io.atom.Atom"], "Installing Atom");
            println!("{}", "========== Install Dev Tools Complete ==========".green().bold().on_black());
        }
        UnpackCommands::Emulators => {
            println!("{}", "========== Installing Emulators ==========".cyan().bold().on_black());
            run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "org.shadps4.shadPS4"], "Installing PlayStation Emulator");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "io.github.ryubing.Ryujinx"], "Installing Nintendo Emulator");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "com.dosbox_x.DOSBox-X"], "Installing DOSBox");
            // Removed snap install for rpcs3-emu
            println!("{}", "========== Hacker-Unpack-Emulators Complete ==========".green().bold().on_black());
        }
        UnpackCommands::Cybersecurity => {
            handle_cybersecurity();
        }
        UnpackCommands::Select => {
            println!("{}", "========== Interactive Package Selection ==========".yellow().bold().on_black());
            println!("{}", "Select packages to install (enter numbers separated by commas, e.g., 1,3,5):".cyan().bold());
            println!("{}", "1. Add-Ons (Wine, BoxBuddy, etc.)".white().bold());
            println!("{}", "2. Gaming Tools (Steam, Lutris, etc.)".white().bold());
            println!("{}", "3. Cybersecurity Tools (nmap, wireshark, etc.)".white().bold());
            println!("{}", "4. Devtools (Atom)".white().bold());
            println!("{}", "5. Emulators (PlayStation, Nintendo, etc.)".white().bold());
            println!("{}", "6. Hacker Mode (gamescope)".white().bold());
            println!("{}", "7. Gaming No Roblox".white().bold());
            let mut input = String::new();
            io::stdin().read_line(&mut input).expect("Failed to read line");
            let selections: Vec<u32> = input.trim().split(',').filter_map(|s| s.parse().ok()).collect();
            for &sel in &selections {
                match sel {
                    1 => handle_unpack(UnpackCommands::AddOns),
                    2 => handle_unpack(UnpackCommands::Gaming),
                    3 => handle_unpack(UnpackCommands::Cybersecurity),
                    4 => handle_unpack(UnpackCommands::Devtools),
                    5 => handle_unpack(UnpackCommands::Emulators),
                    6 => handle_unpack(UnpackCommands::HackerMode),
                    7 => handle_unpack(UnpackCommands::Noroblox),
                    _ => println!("{}", "Invalid selection!".red().bold()),
                }
            }
            println!("{}", "========== Selection Complete ==========".green().bold().on_black());
        }
        UnpackCommands::Gaming => {
            handle_gaming();
        }
        UnpackCommands::Noroblox => {
            println!("{}", "========== Installing Gaming Tools (No Roblox) ==========".cyan().bold().on_black());
            run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_progress("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
            run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
            println!("{}", "========== Hacker-Unpack-Gaming-NoRoblox Complete ==========".green().bold().on_black());
        }
        UnpackCommands::HackerMode => {
            println!("{}", "========== Installing Hacker Mode ==========".cyan().bold().on_black());
            run_command_with_progress("sudo", vec!["apt", "install", "-y", "gamescope"], "Installing gamescope");
            println!("{}", "========== Hacker Mode Install Complete ==========".green().bold().on_black());
        }
    }
}

pub fn handle_system(system_command: SystemCommands) {
    match system_command {
        SystemCommands::Logs => {
            println!("{}", "========== System Logs ==========".cyan().bold().on_black());
            run_command_with_progress("sudo", vec!["journalctl", "-xe"], "Displaying system logs");
        }
    }
}

pub fn handle_run(cmd: RunCommands) {
    // All runs with chattr -i if immutable
    make_mutable();
    match cmd {
        RunCommands::HackerosCockpit => run_command_with_progress("sudo", vec!["python3", "/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Cockpit/HackerOS-Cockpit.py"], "Running HackerOS Cockpit"),
        RunCommands::SwitchToOtherSession => run_command_with_progress("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/Switch_To_Other_Session.sh"], "Switching to other session"),
        RunCommands::UpdateSystem => run_command_with_progress("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/update-system.sh"], "Updating system"),
        RunCommands::CheckUpdates => run_command_with_progress("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh"], "Checking for updates"),
        RunCommands::Steam => run_command_with_progress("bash", vec!["/usr/share/HackerOS/Scripts/Steam/HackerOS-Steam.sh"], "Launching Steam"),
        RunCommands::HackerLauncher => run_command_with_progress("bash", vec!["/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher"], "Launching HackerOS Launcher"),
        RunCommands::HackerosGameMode => run_command_with_progress("", vec!["/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Game-Mode.AppImage"], "Running HackerOS Game Mode"),
        RunCommands::UpdateHackeros => run_command_with_progress("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh"], "Updating HackerOS"),
    }
    make_immutable();
}

pub fn handle_immutable() {
    println!("{}", "Making system immutable...".cyan().bold());
    let paths = vec!["/bin", "/sbin", "/usr", "/etc", "/lib", "/lib64", "/var"];
    for path in paths {
        run_command_with_progress("sudo", vec!["chattr", "+i", "-R", path], &format!("Making {} immutable", path));
    }
    println!("{}", "System is now immutable.".green().bold());
}

pub fn handle_runtime(script: &str) {
    if !is_safe_script(script) {
        println!("{}", "Script contains unsafe commands! Aborting.".red().bold());
        return;
    }
    make_mutable();
    if script.ends_with(".hacker") {
        // Assume hackerc is the compiler/runner
        run_command_with_progress("hackerc", vec![script], "Running .hacker script");
    } else {
        run_command_with_progress("bash", vec![script], "Running script");
    }
    make_immutable();
}

fn is_safe_script(script_path: &str) -> bool {
    if let Ok(file) = File::open(script_path) {
        let reader = io::BufReader::new(file);
        let dangerous_commands = vec!["rm -rf /", "dd if=/dev/zero", "mkfs", ":(){ :|:& };:"];
        for line in reader.lines() {
            if let Ok(line) = line {
                for cmd in &dangerous_commands {
                    if line.contains(cmd) {
                        return false;
                    }
                }
            }
        }
        true
    } else {
        false
    }
}

fn make_mutable() {
    let paths = vec!["/bin", "/sbin", "/usr", "/etc", "/lib", "/lib64", "/var"];
    for path in paths {
        run_command_with_progress("sudo", vec!["chattr", "-i", "-R", path], &format!("Making {} mutable", path));
    }
}

fn make_immutable() {
    let paths = vec!["/bin", "/sbin", "/usr", "/etc", "/lib", "/lib64", "/var"];
    for path in paths {
        run_command_with_progress("sudo", vec!["chattr", "+i", "-R", path], &format!("Making {} immutable", path));
    }
}

pub fn handle_install(package: &str) {
    println!("{}", "Installing package in snapshot...".cyan().bold());
    let snapshot_dir = "/var/cache/hacker/";
    fs::create_dir_all(snapshot_dir).expect("Failed to create snapshot dir");
    let timestamp = Utc::now().format("%Y%m%d%H%M%S").to_string();
    let new_snapshot = format!("{}/snapshot-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &new_snapshot], "Creating new snapshot");
    // Chroot and install
    run_command_with_progress("sudo", vec!["chroot", &new_snapshot, "/usr/share/HackerOS/apt", "install", "-y", package], "Installing package in snapshot");
    // Assume bootloader update or set as next boot
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "set-default", &new_snapshot], "Setting new snapshot as default");
    println!("{}", "Package installed in snapshot. Reboot to apply.".green().bold());
    // Save current snapshot
    let current_snapshot = format!("{}/current-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &current_snapshot], "Saving current snapshot");
}

pub fn handle_remove(package: &str) {
    println!("{}", "Removing package in snapshot...".cyan().bold());
    let snapshot_dir = "/var/cache/hacker/";
    fs::create_dir_all(snapshot_dir).expect("Failed to create snapshot dir");
    let timestamp = Utc::now().format("%Y%m%d%H%M%S").to_string();
    let new_snapshot = format!("{}/snapshot-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &new_snapshot], "Creating new snapshot");
    // Chroot and remove
    run_command_with_progress("sudo", vec!["chroot", &new_snapshot, "/usr/share/HackerOS/apt", "remove", "-y", package], "Removing package in snapshot");
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "set-default", &new_snapshot], "Setting new snapshot as default");
    println!("{}", "Package removed in snapshot. Reboot to apply.".green().bold());
    let current_snapshot = format!("{}/current-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &current_snapshot], "Saving current snapshot");
}

pub fn handle_back() {
    println!("{}", "Rolling back to previous snapshot...".cyan().bold());
    let snapshot_dir = "/var/cache/hacker/";
    // Find latest current- snapshot
    let mut snapshots: Vec<_> = fs::read_dir(snapshot_dir).unwrap()
    .filter_map(|e| e.ok())
    .filter(|e| e.file_name().to_string_lossy().starts_with("current-"))
    .collect();
    snapshots.sort_by_key(|e| e.metadata().unwrap().modified().unwrap());
    if let Some(latest) = snapshots.last() {
        let path = latest.path().to_string_lossy().to_string();
        run_command_with_progress("sudo", vec!["btrfs", "subvolume", "set-default", &path], "Setting previous snapshot as default");
        println!("{}", "Rolled back. Reboot to apply.".green().bold());
    } else {
        println!("{}", "No previous snapshot found.".red().bold());
    }
}

pub fn handle_clean() {
    println!("{}", "Cleaning old snapshots...".cyan().bold());
    let snapshot_dir = "/var/cache/hacker/";
    let fifteen_days_ago = Utc::now() - ChronoDuration::days(15);
    for entry in fs::read_dir(snapshot_dir).unwrap() {
        if let Ok(entry) = entry {
            let path = entry.path();
            if let Ok(metadata) = entry.metadata() {
                if let Ok(modified) = metadata.modified() {
                    let datetime: DateTime<Utc> = modified.into();
                    if datetime < fifteen_days_ago {
                        run_command_with_progress("sudo", vec!["btrfs", "subvolume", "delete", path.to_str().unwrap()], "Deleting old snapshot");
                    }
                }
            }
        }
    }
    println!("{}", "Old snapshots cleaned.".green().bold());
}

pub fn handle_snapshot() {
    println!("{}", "Creating system snapshot...".cyan().bold());
    let snapshot_dir = "/var/cache/hacker/";
    fs::create_dir_all(snapshot_dir).expect("Failed to create snapshot dir");
    let timestamp = Utc::now().format("%Y%m%d%H%M%S").to_string();
    let new_snapshot = format!("{}/manual-snapshot-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &new_snapshot], "Creating snapshot");
    println!("{}", "Snapshot created.".green().bold());
}
