use colored::*;
use crate::utils::{handle_cybersecurity, handle_gaming, run_command_with_spinner};
use crate::UnpackCommands;
use crate::SystemCommands;
use crate::RunCommands;

pub fn handle_unpack(unpack_command: UnpackCommands) {
    match unpack_command {
        UnpackCommands::AddOns => {
            println!("{}", "========== Installing Add-Ons ==========".cyan().bold());
            run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_spinner("sudo", vec!["apt", "install", "-y", "wine", "winetricks"], "Installing Wine");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "io.github.dvlv.boxbuddyrs"], "Installing BoxBuddy");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "it.mijorus.winezgui"], "Installing Winezgui");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "it.mijorus.gearlever"], "Installing Gearlever");
            println!("{}", "========== Install Add-Ons Complete ==========".green().bold());
        }
        UnpackCommands::GS => {
            handle_gaming();
            handle_cybersecurity();
        }
        UnpackCommands::Devtools => {
            println!("{}", "========== Installing Atom ==========".cyan().bold());
            run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "io.atom.Atom"], "Installing Atom");
            println!("{}", "========== Install Dev Tools Complete ==========".green().bold());
        }
        UnpackCommands::Emulators => {
            println!("{}", "========== Installing Emulators ==========".cyan().bold());
            run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "org.shadps4.shadPS4"], "Installing PlayStation Emulator");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "io.github.ryubing.Ryujinx"], "Installing Nintendo Emulator");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "com.dosbox_x.DOSBox-X"], "Installing DOSBox");
            run_command_with_spinner("sudo", vec!["snap", "install", "rpcs3-emu"], "Installing PlayStation 3 Emulator");
            println!("{}", "========== Hacker-Unpack-Emulators Complete ==========".green().bold());
        }
        UnpackCommands::Cybersecurity => {
            handle_cybersecurity();
        }
        UnpackCommands::Select => {
            println!("{}", "Interactive package selection is not yet implemented.".yellow().bold());
        }
        UnpackCommands::Gaming => {
            handle_gaming();
        }
        UnpackCommands::Noroblox => {
            println!("{}", "========== Installing Gaming Tools (No Roblox) ==========".cyan().bold());
            run_command_with_spinner("flatpak", vec!["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"], "Adding flathub repo");
            run_command_with_spinner("sudo", vec!["apt", "install", "-y", "obs-studio", "lutris"], "Installing OBS Studio and Lutris");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "com.valvesoftware.Steam"], "Installing Steam");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "io.github.giantpinkrobots.varia"], "Installing Pika Torrent");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "net.davidotek.pupgui2"], "Installing ProtonUp-Qt");
            run_command_with_spinner("flatpak", vec!["install", "-y", "flathub", "com.heroicgameslauncher.hgl", "protontricks", "com.discordapp.Discord"], "Installing Heroic Games Launcher, Protontricks, and Discord");
            println!("{}", "========== Hacker-Unpack-Gaming-NoRoblox Complete ==========".green().bold());
        }
        UnpackCommands::HackerMode => {
            println!("{}", "========== Installing Hacker Mode ==========".cyan().bold());
            run_command_with_spinner("sudo", vec!["apt", "install", "-y", "gamescope"], "Installing gamescope");
            println!("{}", "========== Hacker Mode Install Complete ==========".green().bold());
        }
    }
}

pub fn handle_system(system_command: SystemCommands) {
    match system_command {
        SystemCommands::Logs => {
            println!("{}", "========== System Logs ==========".cyan().bold());
            run_command_with_spinner("sudo", vec!["journalctl", "-xe"], "Displaying system logs");
        }
    }
}

pub fn handle_run(cmd: RunCommands) {
    match cmd {
        RunCommands::HackerosCockpit => run_command_with_spinner("sudo", vec!["python3", "/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Cockpit/HackerOS-Cockpit.py"], "Running HackerOS Cockpit"),
        RunCommands::SwitchToOtherSession => run_command_with_spinner("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/Switch_To_Other_Session.sh"], "Switching to other session"),
        RunCommands::UpdateSystem => run_command_with_spinner("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/update-system.sh"], "Updating system"),
        RunCommands::CheckUpdates => run_command_with_spinner("sudo", vec!["/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh"], "Checking for updates"),
        RunCommands::Steam => run_command_with_spinner("bash", vec!["/usr/share/HackerOS/Scripts/Steam/HackerOS-Steam.sh"], "Launching Steam"),
        RunCommands::HackerLauncher => run_command_with_spinner("bash", vec!["/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher"], "Launching HackerOS Launcher"),
        RunCommands::HackerosGameMode => run_command_with_spinner("", vec!["/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Game-Mode.AppImage"], "Running HackerOS Game Mode"),
    }
}
