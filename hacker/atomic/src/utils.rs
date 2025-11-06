use colored::*;
use std::process::{Command, Stdio};
use std::io::{self, Write};
use std::thread;
use std::time::Duration;
use std::sync::{Arc, atomic::{AtomicUsize, Ordering}};
pub fn run_command_with_progress(program: &str, args: Vec<&str>, message: &str) {
    println!("{}", format!("▶ {}: {}", message, args.join(" ")).blue().bold().on_black());
    let progress = Arc::new(AtomicUsize::new(0));
    let progress_clone = progress.clone();
    let handle = thread::spawn(move || {
        let bar_length = 20;
        while progress_clone.load(Ordering::Relaxed) < 100 {
            let p = progress_clone.load(Ordering::Relaxed);
            let filled = (p as f32 / 100.0 * bar_length as f32) as usize;
            let bar: String = (0..bar_length).map(|i| if i < filled { '.' } else { ' ' }).collect();
            print!("\r{}% <{} >", p, bar.purple().bold());
            let _ = io::stdout().flush();
            thread::sleep(Duration::from_millis(200)); // Simulate progress
            progress_clone.store((p + 2).min(99), Ordering::Relaxed); // Increment slowly
        }
        print!("\r100% <{} >        \n", ".".repeat(bar_length).purple().bold());
        let _ = io::stdout().flush();
    });
    let child = Command::new(program)
    .args(&args)
    .stdout(Stdio::piped())
    .stderr(Stdio::piped())
    .spawn()
    .expect(&format!("Failed to execute {}", program));
    // Simple simulation, no real progress parsing for now
    let output = child.wait_with_output().expect("Failed to wait on child");
    progress.store(100, Ordering::Relaxed);
    handle.join().unwrap();
    if output.status.success() {
        let out_str = String::from_utf8_lossy(&output.stdout).to_string();
        if !out_str.is_empty() {
            println!("{}", format!("┌── Output ────────────────").green().bold().on_black());
            println!("{}", out_str.green().on_black());
            println!("{}", format!("└──────────────────────────").green().bold().on_black());
        } else {
            println!("{}", "✔ Success (no output)".green().bold().on_black());
        }
    } else {
        let err_str = String::from_utf8_lossy(&output.stderr).to_string();
        println!("{}", format!("┌── Error ─────────────────").red().bold().on_black());
        println!("{}", err_str.red().on_black());
        println!("{}", format!("└──────────────────────────").red().bold().on_black());
    }
}
pub fn handle_update() {
    println!("{}", "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓".magenta().bold().on_black());
    println!("{}", "┃ Starting System Update ┃".magenta().bold().on_black());
    println!("{}", "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛".magenta().bold().on_black());
    run_command_with_progress("sudo", vec!["apt", "update"], "Updating APT repositories");
    run_command_with_progress("sudo", vec!["apt", "upgrade", "-y"], "Upgrading APT packages");
    run_command_with_progress("flatpak", vec!["update", "-y"], "Updating Flatpak packages");
    // Removed snap refresh
    run_command_with_progress("fwupdmgr", vec!["update"], "Updating firmware");
    run_command_with_progress("omz", vec!["update"], "Updating Oh-My-Zsh");
    // Immutable update: update in snapshot
    let snapshot_dir = "/var/cache/hacker/";
    let timestamp = chrono::Utc::now().format("%Y%m%d%H%M%S").to_string();
    let new_snapshot = format!("{}/update-snapshot-{}", snapshot_dir, timestamp);
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "snapshot", "/", &new_snapshot], "Creating update snapshot");
    run_command_with_progress("sudo", vec!["chroot", &new_snapshot, "/usr/share/HackerOS/apt", "upgrade", "-y"], "Upgrading in snapshot");
    run_command_with_progress("sudo", vec!["btrfs", "subvolume", "set-default", &new_snapshot], "Setting update snapshot as default");
    println!("{}", "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓".green().bold().on_black());
    println!("{}", "┃ System Update Complete ┃".green().bold().on_black());
    println!("{}", "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛".green().bold().on_black());
}
pub fn handle_cybersecurity() {
    println!("{}", "========== Installing Penetration Tools ==========".cyan().bold().on_black());
    run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command_with_progress("sudo", vec!["apt", "install", "-y", "nmap", "wireshark", "nikto", "john", "hydra", "aircrack-ng", "sqlmap", "ettercap-text-only", "tcpdump", "zmap", "bettercap", "wfuzz", "hashcat", "fail2ban", "rkhunter", "chkrootkit", "lynis", "clamav", "tor", "proxychains4", "httrack", "sublist3r", "macchanger", "inxi", "htop", "openvas", "openvpn"], "Installing cybersecurity tools");
    // Removed Metasploit snap
    println!("{}", "========== Installing Ghidra ==========".cyan().bold().on_black());
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "org.ghidra_sre.Ghidra"], "Installing Ghidra");
    println!("{}", "========== Hacker-Unpack-Cybersecurity Complete ==========".green().bold().on_black());
}
pub fn handle_gaming() {
    println!("{}", "========== Installing Gaming Tools ==========".cyan().bold().on_black());
    run_command_with_progress("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command_with_progress("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
    run_command_with_progress("flatpak", vec!["install", "--user", "https://sober.vinegarhq.org/sober.flatpakref"], "Installing Roblox");
    run_command_with_progress("flatpak", vec!["install", "-y", "flathub", "org.vinegarhq.Vinegar"], "Installing Roblox Studio");
    println!("{}", "========== Hacker-Unpack-Gaming Complete ==========".green().bold().on_black());
}
