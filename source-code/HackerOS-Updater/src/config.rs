use std::fs;

/// All known HackerOS edition variants.
#[derive(Debug, Clone, PartialEq)]
pub enum Variant {
    /// Standard editions — full update set
    Standard,
    /// Atomic Edition — immutable base, uses hammer instead of apt, no snap/hackeros/wallpapers
    Atomic,
    /// Cybersecurity Edition — full set + cybersecurity-cli update-all after NixManager
    Cybersecurity,
    /// Blue Edition — full set + blue update after NixManager
    Blue,
    /// Gaming Edition — full set + gaming-cli update after NixManager
    Gaming,
}

const DISTRO_RC: &str = "/etc/xdg/kcm-about-distrorc";

pub fn detect_variant() -> Variant {
    let contents = match fs::read_to_string(DISTRO_RC) {
        Ok(c) => c,
        Err(_) => return Variant::Standard,
    };

    // Look for "Variant=<value>" line (case-insensitive match on value)
    for line in contents.lines() {
        let line = line.trim();
        if let Some(value) = line.strip_prefix("Variant=") {
            let value = value.trim();
            return match value {
                "Atomic Edition" => Variant::Atomic,
                "Cybersecurity Edition" => Variant::Cybersecurity,
                "Blue Edition" => Variant::Blue,
                "Gaming Edition" => Variant::Gaming,
                // Official Edition, LTS Edition, Hydra Edition, Gnome Edition,
                // Xfce Edition, NVIDIA Edition — all standard behaviour
                _ => Variant::Standard,
            };
        }
    }

    Variant::Standard
}
