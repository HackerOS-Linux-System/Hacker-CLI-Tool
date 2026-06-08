# ── Results record ───────────────────────────────────────────────────────────
record Results,
  apt            : Bool,
  hammer         : Bool,
  flatpak        : Bool,
  snap           : Bool,
  brew           : Bool,
  firmware       : Bool,
  omz            : Bool,
  distrobox      : Bool,
  hnm            : Bool,
  cybersecurity  : Bool,
  blue           : Bool,
  gaming         : Bool,
  hackeros       : Bool,
  wallpapers     : Bool,
  elapsed        : Int64,
  variant        : String

# ── Variant detection ─────────────────────────────────────────────────────────
def detect_variant : String
  return "Unknown" unless File.exists?(DISTRO_RC_PATH)
  File.each_line(DISTRO_RC_PATH) do |line|
    stripped = line.strip
    if stripped.starts_with?("Variant=")
      return stripped.sub("Variant=", "").strip
    end
  end
  "Unknown"
end

# ── Update orchestration ──────────────────────────────────────────────────────
def perform_updates(pwd : String, variant : String) : Results
  SudoState.password = pwd
  start = Time.monotonic

  apt           = false
  hammer        = false
  flatpak       = false
  snap          = false
  brew          = false
  firmware      = false
  omz           = false
  distrobox     = false
  hnm           = false
  cybersecurity = false
  blue          = false
  gaming        = false
  hackeros      = false
  wallpapers    = false

  case variant
  when "Atomic Edition"
    hammer     = update_hammer
    flatpak    = update_flatpak
    brew       = update_brew
    firmware   = update_firmware
    omz        = update_omz
    distrobox  = update_distrobox
    hnm        = update_hnm
    hackeros   = update_hackeros
    wallpapers = update_wallpapers
  when "Cybersecurity Edition"
    apt           = update_apt
    flatpak       = update_flatpak
    snap          = update_snap
    brew          = update_brew
    firmware      = update_firmware
    omz           = update_omz
    distrobox     = update_distrobox
    hnm           = update_hnm
    cybersecurity = update_cybersecurity
    hackeros      = update_hackeros
    wallpapers    = update_wallpapers
  when "Blue Edition"
    apt        = update_apt
    flatpak    = update_flatpak
    snap       = update_snap
    brew       = update_brew
    firmware   = update_firmware
    omz        = update_omz
    distrobox  = update_distrobox
    hnm        = update_hnm
    blue       = update_blue
    hackeros   = update_hackeros
    wallpapers = update_wallpapers
  when "Gaming Edition"
    apt        = update_apt
    flatpak    = update_flatpak
    snap       = update_snap
    brew       = update_brew
    firmware   = update_firmware
    omz        = update_omz
    distrobox  = update_distrobox
    hnm        = update_hnm
    gaming     = update_gaming
    hackeros   = update_hackeros
    wallpapers = update_wallpapers
  else
    # Official Edition, LTS Edition, Hydra Edition, Gnome Edition, Xfce Edition, NVIDIA Edition, Unknown
    apt        = update_apt
    flatpak    = update_flatpak
    snap       = update_snap
    brew       = update_brew
    firmware   = update_firmware
    omz        = update_omz
    distrobox  = update_distrobox
    hnm        = update_hnm
    hackeros   = update_hackeros
    wallpapers = update_wallpapers
  end

  elapsed = (Time.monotonic - start).total_seconds.to_i64

  Results.new(
    apt:           apt,
    hammer:        hammer,
    flatpak:       flatpak,
    snap:          snap,
    brew:          brew,
    firmware:      firmware,
    omz:           omz,
    distrobox:     distrobox,
    hnm:           hnm,
    cybersecurity: cybersecurity,
    blue:          blue,
    gaming:        gaming,
    hackeros:      hackeros,
    wallpapers:    wallpapers,
    elapsed:       elapsed,
    variant:       variant
  )
end

# ── Summary ──────────────────────────────────────────────────────────────────
def show_summary(r : Results)
  case r.variant
  when "Atomic Edition"
    rows = [
      {"System (Hammer)",     r.hammer},
      {"Flatpak",             r.flatpak},
      {"Homebrew",            r.brew},
      {"Firmware",            r.firmware},
      {"Oh My Zsh",           r.omz},
      {"Distrobox",           r.distrobox},
      {"HackerOS Nix (hnm)",  r.hnm},
      {"HackerOS",            r.hackeros},
      {"Wallpapers",          r.wallpapers},
    ]
  when "Cybersecurity Edition"
    rows = [
      {"System (APT)",        r.apt},
      {"Flatpak",             r.flatpak},
      {"Snap",                r.snap},
      {"Homebrew",            r.brew},
      {"Firmware",            r.firmware},
      {"Oh My Zsh",           r.omz},
      {"Distrobox",           r.distrobox},
      {"HackerOS Nix (hnm)",  r.hnm},
      {"Cybersecurity",       r.cybersecurity},
      {"HackerOS",            r.hackeros},
      {"Wallpapers",          r.wallpapers},
    ]
  when "Blue Edition"
    rows = [
      {"System (APT)",        r.apt},
      {"Flatpak",             r.flatpak},
      {"Snap",                r.snap},
      {"Homebrew",            r.brew},
      {"Firmware",            r.firmware},
      {"Oh My Zsh",           r.omz},
      {"Distrobox",           r.distrobox},
      {"HackerOS Nix (hnm)",  r.hnm},
      {"Blue",                r.blue},
      {"HackerOS",            r.hackeros},
      {"Wallpapers",          r.wallpapers},
    ]
  when "Gaming Edition"
    rows = [
      {"System (APT)",        r.apt},
      {"Flatpak",             r.flatpak},
      {"Snap",                r.snap},
      {"Homebrew",            r.brew},
      {"Firmware",            r.firmware},
      {"Oh My Zsh",           r.omz},
      {"Distrobox",           r.distrobox},
      {"HackerOS Nix (hnm)",  r.hnm},
      {"Gaming",              r.gaming},
      {"HackerOS",            r.hackeros},
      {"Wallpapers",          r.wallpapers},
    ]
  else
    rows = [
      {"System (APT)",        r.apt},
      {"Flatpak",             r.flatpak},
      {"Snap",                r.snap},
      {"Homebrew",            r.brew},
      {"Firmware",            r.firmware},
      {"Oh My Zsh",           r.omz},
      {"Distrobox",           r.distrobox},
      {"HackerOS Nix (hnm)",  r.hnm},
      {"HackerOS",            r.hackeros},
      {"Wallpapers",          r.wallpapers},
    ]
  end

  col_w = 26
  box_w = 2 + col_w + 2 + 8 + 4  # 42

  failed_count = rows.count { |(_, s)| !s }
  all_ok       = failed_count == 0
  footer_color = all_ok ? :green : :yellow
  duration_str = format_duration(r.elapsed)

  puts ""
  puts "┌#{"─" * box_w}┐".colorize(:dark_gray)
  title_pad = box_w - "Update Summary".size - 2
  puts "│  #{"Update Summary".colorize(:yellow).bold}#{" " * [title_pad, 0].max}│".colorize(:dark_gray)
  puts "├#{"─" * box_w}┤".colorize(:dark_gray)

  rows.each do |(label, success)|
    tag     = success ? "✓ OK".colorize(:green).bold.to_s : "✗ FAILED".colorize(:red).bold.to_s
    tag_vis = success ? 4 : 8
    padding = " " * [0, box_w - 2 - col_w - 2 - tag_vis - 1].max
    puts "│  #{label.ljust(col_w).colorize(:white)}  #{tag}#{padding}│".colorize(:dark_gray)
  end

  puts "├#{"─" * box_w}┤".colorize(:dark_gray)

  time_line = "Completed in #{duration_str}"
  time_pad  = box_w - 2 - time_line.size - 1
  puts "│  #{"Completed in".colorize(:dark_gray)} #{duration_str.colorize(footer_color).bold}#{" " * [time_pad, 0].max}│".colorize(:dark_gray)

  status_text = all_ok ? "All updates completed successfully" : "#{failed_count} section(s) failed — check output above"
  status_pad  = box_w - 2 - status_text.size - 1
  puts "│  #{status_text.colorize(footer_color)}#{" " * [status_pad, 0].max}│".colorize(:dark_gray)

  puts "└#{"─" * box_w}┘".colorize(:dark_gray)
  puts ""
end
