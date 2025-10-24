use colored::*;
use std::process::{Command, Stdio};
use std::io::{self, Write};
use std::thread;
use std::time::Duration;
use std::sync::{Arc, atomic::{AtomicBool, Ordering}};
pub fn run_command_with_spinner(program: &str, args: Vec<&str>, message: &str) {
    println!("{}", format!("{}: {}", message, args.join(" ")).blue().bold().on_black());
    let stop = Arc::new(AtomicBool::new(false));
    let stop_clone = stop.clone();
    let spinner_chars: Vec<&str> = vec!["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
    let handle = thread::spawn(move || {
        let mut i = 0;
        while !stop_clone.load(Ordering::Relaxed) {
            print!("\r{}", spinner_chars[i].purple().bold());
            let _ = io::stdout().flush();
            i = (i + 1) % spinner_chars.len();
            thread::sleep(Duration::from_millis(100));
        }
        print!("\r   \r");
        let _ = io::stdout().flush();
    });
    let child = Command::new(program)
    .args(&args)
    .stdout(Stdio::piped())
    .stderr(Stdio::piped())
    .spawn()
    .expect(&format!("Failed to execute {}", program));
    let output = child.wait_with_output().expect("Failed to wait on child");
    stop.store(true, Ordering::Relaxed);
    handle.join().unwrap();
    if output.status.success() {
        println!("{}", String::from_utf8_lossy(&output.stdout).green().bold().on_black());
    } else {
        println!("{}", String::from_utf8_lossy(&output.stderr).red().bold().on_black());
    }
}
pub fn handle_update() {
    println!("{}", "========== Starting System Update ==========".magenta().bold().on_black());
    run_command_with_spinner("sudo", vec!["apt", "update"], "Updating APT repositories");
    run_command_with_spinner("sudo", vec!["apt", "upgrade", "-y"], "Upgrading APT packages");
    run_command_with_spinner("flatpak", vec!["update", "-y"], "Updating Flatpak packages");
    run_command_with_spinner("snap", vec!["refresh"], "Refreshing Snap packages");
    run_command_with_spinner("fwupdmgr", vec!["update"], "Updating firmware");
    println!("{}", "========== System Update Complete ==========".green().bold().on_black());
}
pub fn handle_cybersecurity() {
    println!("{}", "========== Installing Penetration Tools ==========".cyan().bold().on_black());
    run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command_with_spinner("sudo", vec!["apt", "install", "-y", "nmap", "wireshark", "nikto", "john", "hydra", "aircrack-ng", "sqlmap", "ettercap-text-only", "tcpdump", "zmap", "bettercap", "wfuzz", "hashcat", "fail2ban", "rkhunter", "chkrootkit", "lynis", "clamav", "tor", "proxychains4", "httrack", "sublist3r", "macchanger", "inxi", "htop", "openvas", "openvpn"], "Installing cybersecurity tools");
    println!("{}", "========== Installing Metasploit Framework ==========".cyan().bold().on_black());
    run_command_with_spinner("sudo", vec!["snap", "install", "metasploit-framework"], "Installing Metasploit");
    println!("{}", "========== Installing Ghidra ==========".cyan().bold().on_black());
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "org.ghidra_sre.Ghidra"], "Installing Ghidra");
    println!("{}", "========== Hacker-Unpack-Cybersecurity Complete ==========".green().bold().on_black());
}
pub fn handle_gaming() {
    println!("{}", "========== Installing Gaming Tools ==========".cyan().bold().on_black());
    run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
    run_command_with_spinner("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
    run_command_with_spinner("flatpak", vec!["install", "--user", "https://sober.vinegarhq.org/sober.flatpakref"], "Installing Roblox");
    run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "org.vinegarhq.Vinegar"], "Installing Roblox Studio");
    println!("{}", "========== Hacker-Unpack-Gaming Complete ==========".green().bold().on_black());
}
