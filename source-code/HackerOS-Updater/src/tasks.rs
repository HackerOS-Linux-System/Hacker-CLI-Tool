use crate::config::Variant;

// --- CONFIGURATION ---
pub const HACKEROS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-hackeros.hl";
pub const WALLPAPERS_UPDATE_SCRIPT: &str = "/usr/share/HackerOS/Scripts/Bin/update-wallpapers.hl";

// --- THEME COLOURS (re-exported for ui module) ---
use ratatui::style::Color;
pub const COLOR_BG: Color = Color::Reset;
pub const COLOR_ACCENT: Color = Color::Magenta;
pub const COLOR_FOCUS: Color = Color::Yellow;
pub const COLOR_TEXT_MAIN: Color = Color::White;
pub const COLOR_TEXT_DIM: Color = Color::DarkGray;
pub const COLOR_SUCCESS: Color = Color::Green;
pub const COLOR_ERROR: Color = Color::Red;
pub const COLOR_WARN: Color = Color::Yellow;

// --- DATA STRUCTURES ---
#[derive(Clone, Debug, PartialEq)]
pub enum TaskStatus {
    Pending,
    Running,
    Success,
    Failed,
    Skipped,
    Cancelled,
}

#[derive(Clone, Debug)]
pub struct Task {
    pub name: String,
    /// Shell command to run (empty for special tasks)
    pub command: String,
    pub is_sudo: bool,
    pub status: TaskStatus,
    pub optional: bool,
    /// HackerOS Nix Manager — uses multi-step hnm logic
    pub is_hnm: bool,
}

/// Build the task list appropriate for the detected variant.
pub fn build_tasks(variant: &Variant) -> Vec<Task> {
    match variant {
        Variant::Atomic => build_atomic_tasks(),
        Variant::Cybersecurity => build_cybersecurity_tasks(),
        Variant::Blue => build_blue_tasks(),
        Variant::Gaming => build_gaming_tasks(),
        Variant::Standard => build_standard_tasks(),
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn apt_task() -> Task {
    Task {
        name: "System Update (APT)".to_string(),
        command: [
            "DEBIAN_FRONTEND=noninteractive",
            "apt-get update -qq &&",
            "DEBIAN_FRONTEND=noninteractive",
            "apt-get dist-upgrade -y",
            "-o Dpkg::Options::='--force-confdef'",
            "-o Dpkg::Options::='--force-confold' &&",
            "apt-get autoremove -y &&",
            "apt-get autoclean -y",
        ]
        .join(" "),
        is_sudo: true,
        status: TaskStatus::Pending,
        optional: false,
        is_hnm: false,
    }
}

fn flatpak_task() -> Task {
    Task {
        name: "Flatpak Update".to_string(),
        command: "flatpak update -y --noninteractive".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn snap_task() -> Task {
    Task {
        name: "Snap Updates".to_string(),
        command: "snap refresh".to_string(),
        is_sudo: true,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn brew_task() -> Task {
    Task {
        name: "Brew Updates".to_string(),
        command: r#"if command -v brew &>/dev/null; then brew update && brew upgrade && brew cleanup; else echo "Brew not found, skipping."; fi"#.to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn firmware_task() -> Task {
    Task {
        name: "Firmware Update".to_string(),
        command: "fwupdmgr refresh --force; fwupdmgr update --no-reboot-check".to_string(),
        is_sudo: true,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn omz_task() -> Task {
    Task {
        name: "Zsh / Oh-My-Zsh Update".to_string(),
        command: r#"if [ -d "$HOME/.oh-my-zsh" ]; then zsh -c 'source "$HOME/.zshrc" 2>/dev/null; omz update --unattended 2>&1 || true'; else echo "Oh-My-Zsh not found, skipping."; fi"#.to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn distrobox_task() -> Task {
    Task {
        name: "Distrobox Update".to_string(),
        command: "distrobox-upgrade --all 2>&1 || true".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn hnm_task() -> Task {
    Task {
        name: "HackerOS Nix Manager".to_string(),
        command: String::new(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: true,
    }
}

fn hackeros_update_task() -> Task {
    Task {
        name: "HackerOS Update".to_string(),
        command: format!("/usr/bin/hl run {}", HACKEROS_UPDATE_SCRIPT),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: false,
        is_hnm: false,
    }
}

fn wallpapers_task() -> Task {
    Task {
        name: "Wallpapers Update".to_string(),
        command: format!("/usr/bin/hl run {}", WALLPAPERS_UPDATE_SCRIPT),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn hammer_task() -> Task {
    Task {
        name: "Hammer Updates".to_string(),
        command: "hammer update && hammer upgrade -y".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: false,
        is_hnm: false,
    }
}

fn cybersecurity_task() -> Task {
    Task {
        name: "Cybersecurity Updates".to_string(),
        command: "cybersecurity-cli update-all".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn blue_task() -> Task {
    Task {
        name: "Blue Updates".to_string(),
        command: "blue update".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

fn gaming_task() -> Task {
    Task {
        name: "Gaming Updates".to_string(),
        command: "gaming-cli update".to_string(),
        is_sudo: false,
        status: TaskStatus::Pending,
        optional: true,
        is_hnm: false,
    }
}

// ── Per-variant task lists ─────────────────────────────────────────────────────

/// Standard / Official / LTS / Hydra / Gnome / Xfce / NVIDIA editions
fn build_standard_tasks() -> Vec<Task> {
    vec![
        apt_task(),
        flatpak_task(),
        snap_task(),
        brew_task(),
        firmware_task(),
        omz_task(),
        distrobox_task(),
        hnm_task(),
        hackeros_update_task(),
        wallpapers_task(),
    ]
}

/// Atomic Edition:
///   - No APT → Hammer Updates instead
///   - No Snap, no HackerOS Update, no Wallpapers Update
fn build_atomic_tasks() -> Vec<Task> {
    vec![
        hammer_task(),
        flatpak_task(),
        brew_task(),
        firmware_task(),
        omz_task(),
        distrobox_task(),
        hnm_task(),
    ]
}

/// Cybersecurity Edition: standard + Cybersecurity Updates after NixManager
fn build_cybersecurity_tasks() -> Vec<Task> {
    vec![
        apt_task(),
        flatpak_task(),
        snap_task(),
        brew_task(),
        firmware_task(),
        omz_task(),
        distrobox_task(),
        hnm_task(),
        cybersecurity_task(),
        hackeros_update_task(),
        wallpapers_task(),
    ]
}

/// Blue Edition: standard + Blue Updates after NixManager
fn build_blue_tasks() -> Vec<Task> {
    vec![
        apt_task(),
        flatpak_task(),
        snap_task(),
        brew_task(),
        firmware_task(),
        omz_task(),
        distrobox_task(),
        hnm_task(),
        blue_task(),
        hackeros_update_task(),
        wallpapers_task(),
    ]
}

/// Gaming Edition: standard + Gaming Updates after NixManager
fn build_gaming_tasks() -> Vec<Task> {
    vec![
        apt_task(),
        flatpak_task(),
        snap_task(),
        brew_task(),
        firmware_task(),
        omz_task(),
        distrobox_task(),
        hnm_task(),
        gaming_task(),
        hackeros_update_task(),
        wallpapers_task(),
    ]
}
