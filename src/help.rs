use colored::*;

pub fn display_help() {
    println!("{}", "========== Commands List ==========".cyan().bold());
    println!("{}", "Unpack Commands:".magenta().bold());
    println!("{}", "hacker unpack add-ons: Install Wine, BoxBuddy, Winezgui, Gearlever".white().bold());
    println!("{}", "hacker unpack g-s: Install gaming and cybersecurity tools".white().bold());
    println!("{}", "hacker unpack devtools: Install Atom".white().bold());
    println!("{}", "hacker unpack emulators: Install PlayStation, Nintendo, DOSBox, PS3 emulators".white().bold());
    println!("{}", "hacker unpack cybersecurity: Install nmap, wireshark, Metasploit, Ghidra, etc.".white().bold());
    println!("{}", "hacker unpack hacker-mode: Install gamescope".white().bold());
    println!("{}", "hacker unpack select: Interactive package selection (not implemented)".white().bold());
    println!("{}", "hacker unpack gaming: Install OBS Studio, Lutris, Steam, Roblox, etc.".white().bold());
    println!("{}", "hacker unpack noroblox: Install gaming tools without Roblox".white().bold());
    println!("{}", "General Commands:".magenta().bold());
    println!("{}", "hacker help: Display this help message".yellow().bold());
    println!("{}", "hacker install <package>: Placeholder for installing packages".yellow().bold());
    println!("{}", "hacker remove <package>: Placeholder for removing packages".yellow().bold());
    println!("{}", "Package Management:".magenta().bold());
    println!("{}", "hacker apt-install <package>: Run apt install -y <package>".blue().bold());
    println!("{}", "hacker apt-remove <package>: Run apt remove -y <package>".blue().bold());
    println!("{}", "hacker flatpak-install <package>: Run flatpak install -y flathub <package>".blue().bold());
    println!("{}", "hacker flatpak-remove <package>: Run flatpak remove -y <package>".blue().bold());
    println!("{}", "hacker flatpak-update: Run flatpak update -y".blue().bold());
    println!("{}", "System Commands:".magenta().bold());
    println!("{}", "hacker system logs: Show system logs".green().bold());
    println!("{}", "Run Commands:".magenta().bold());
    println!("{}", "hacker run hackeros-cockpit: Run HackerOS Cockpit".purple().bold());
    println!("{}", "hacker run switch-to-other-session: Switch to another session".purple().bold());
    println!("{}", "hacker run update-system: Update the system".purple().bold());
    println!("{}", "hacker run check-updates: Check for system updates".purple().bold());
    println!("{}", "hacker run steam: Launch Steam via HackerOS script".purple().bold());
    println!("{}", "hacker run hacker-launcher: Launch HackerOS Launcher".purple().bold());
    println!("{}", "hacker run hackeros-game-mode: Run HackerOS Game Mode".purple().bold());
    println!("{}", "Update and Game:".magenta().bold());
    println!("{}", "hacker update: Perform system update (apt, flatpak, snap, firmware)".red().bold());
    println!("{}", "hacker game: Play a fun Hacker Adventure game".red().bold());
    println!("{}", "========== Instead of sudo apt, you can use hacker ==========".green().bold());
}
