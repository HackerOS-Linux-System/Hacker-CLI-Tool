require "option_parser"
require "process"
require "file_utils"
require "colorize"

# ── Paths ────────────────────────────────────────────────────────────────────
HACKEROS_UPDATE_SCRIPT   = "/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh"
WALLPAPERS_UPDATE_SCRIPT = "/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh"
BIN_PATH                 = Process.executable_path.not_nil!

DISTRO_RC_PATH = "/etc/xdg/kcm-about-distrorc"

# Global: stored password used to keep sudo alive in background

# ── Sudo state ────────────────────────────────────────────────────────────────
module SudoState
  @@password : String = ""

  def self.password=(pwd : String)
    @@password = pwd
  end

  def self.password : String
    @@password
  end
end

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

# ── UI helpers ───────────────────────────────────────────────────────────────
def banner(title : String)
  total_width = 52
  label       = " [ #{title} ] "
  side        = [2, (total_width - label.size) // 2].max
  left_line   = "─" * side
  right_line  = "─" * [0, total_width - side - label.size].max
  puts ""
  puts (left_line + label.colorize(:white).bold.to_s + right_line).colorize(:dark_gray)
end

def step(msg : String)
  puts "  #{"›".colorize(:dark_gray)}  #{msg.colorize(:white)}"
end

def ok(msg : String)
  puts "  #{"✓".colorize(:green).bold}  #{msg.colorize(:light_gray)}"
end

def fail_msg(msg : String)
  puts "  #{"✗".colorize(:red).bold}  #{msg.colorize(:light_gray)}"
end

def warn_msg(msg : String)
  puts "  #{"⚠".colorize(:yellow).bold}  #{msg.colorize(:light_gray)}"
end

def format_duration(seconds : Int64) : String
  if seconds >= 60
    m = seconds // 60
    s = seconds % 60
    "#{m}m #{s}s"
  else
    "#{seconds}s"
  end
end

# ── Command runner ───────────────────────────────────────────────────────────
def run_command(cmd : String) : Bool
  Process.run(
    cmd,
    shell:  true,
    input:  Process::Redirect::Inherit,
    output: Process::Redirect::Inherit,
    error:  Process::Redirect::Inherit
  ).success?
end

def capture_command(cmd : String) : {Bool, String}
  buf    = IO::Memory.new
  status = Process.run(cmd, shell: true, input: Process::Redirect::Close, output: buf, error: buf)
  {status.success?, buf.to_s}
end

# ── Sudo helpers ─────────────────────────────────────────────────────────────

# Run sudo command with password piped via stdin — bypasses TTY cache issues.
def sudo_run(cmd : String) : Bool
  full = "echo #{Process.quote(SudoState.password)} | sudo -S sh -c #{Process.quote(cmd)} 2>/dev/null"
  Process.run(
    full,
    shell:  true,
    input:  Process::Redirect::Close,
    output: Process::Redirect::Inherit,
    error:  Process::Redirect::Inherit
  ).success?
end

# ── Sudo password prompt ──────────────────────────────────────────────────────
def prompt_sudo_password : String
  puts ""
  puts "  #{"┌".colorize(:dark_gray)} #{"Sudo authentication".colorize(:white).bold}"
  puts "  #{"│".colorize(:dark_gray)}  #{"Password is piped directly to each sudo call — no repeated prompts.".colorize(:dark_gray)}"
  print "  #{"└".colorize(:dark_gray)}  #{"password".colorize(:white)} › "

  password = ""
  STDIN.raw do |io|
    loop do
      byte = io.read_byte
      break if byte.nil?
      char = byte.chr
      break if char == '\r' || char == '\n'
      if char == '\u007F' || char == '\b'
        unless password.empty?
          password = password[0..-2]
          print "\b \b"
        end
        next
      end
      password += char.to_s
      print "*"
    end
  end
  puts ""

  # Validate by running a harmless sudo command
  validated = Process.run(
    "echo #{Process.quote(password)} | sudo -S true 2>/dev/null",
    shell:  true,
    input:  Process::Redirect::Close,
    output: Process::Redirect::Close,
    error:  Process::Redirect::Close
  ).success?

  unless validated
    puts ""
    puts "  #{"✗".colorize(:red).bold}  #{"Incorrect password — aborting.".colorize(:red)}"
    exit(1)
  end

  puts "  #{"✓".colorize(:green).bold}  #{"Authentication successful.".colorize(:light_gray)}"
  puts ""
  password
end

# ── Individual update sections ───────────────────────────────────────────────
def update_apt : Bool
  banner("System Update · APT")
  success = true
  {
    "apt update"     => "Refreshing package lists",
    "apt upgrade -y" => "Upgrading packages",
    "apt autoclean"  => "Cleaning cache",
  }.each do |cmd, label|
    step label
    success &&= sudo_run(cmd)
  end
  success
end

def update_hammer : Bool
  banner("System Update · Hammer")
  success = true
  step "Running hammer update"
  success &&= run_command("hammer update")
  step "Running hammer upgrade"
  success &&= run_command("hammer upgrade -y")
  success
end

def update_flatpak : Bool
  banner("Flatpak Update")
  step "Updating Flatpak apps"
  run_command("flatpak update -y")
end

def update_snap : Bool
  banner("Snap Update")
  step "Refreshing snaps"
  sudo_run("snap refresh")
end

def update_brew : Bool
  banner("Homebrew Update")
  brew_installed = Process.run("command -v brew", shell: true).success?

  unless brew_installed
    step "Brew not found — installing…"
    install_ok = true
    [
      %(NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"),
      %(echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc),
      %(eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"),
    ].each { |c| install_ok &&= run_command(c) }

    if install_ok
      ok "Brew installed successfully"
      brew_installed = true
    else
      fail_msg "Brew installation failed"
      return false
    end
  else
    ok "Brew already installed"
  end

  return false unless brew_installed

  success = true
  {
    "brew update"  => "Fetching updates",
    "brew upgrade" => "Upgrading formulae",
    "brew cleanup" => "Cleaning up",
  }.each do |cmd, label|
    step label
    success &&= run_command(cmd)
  end
  success
end

def update_firmware : Bool
  banner("Firmware Update · fwupd")
  step "Checking for firmware updates"
  sudo_run("fwupdmgr update")
end

def update_omz : Bool
  banner("Oh My Zsh Update")
  step "Updating Oh My Zsh"
  run_command(%(zsh -c 'ZSH_DISABLE_COMPFIX=true NONINTERACTIVE=1 "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>/dev/null'))
end

def update_distrobox : Bool
  banner("Distrobox Update")
  step "Upgrading all containers"
  run_command("distrobox-upgrade --all")
end

def update_hnm : Bool
  banner("HackerOS Nix Manager · hnm")

  step "Checking Nix installation…"
  check_ok, check_out = capture_command("hnm check 2>&1")

  if check_out.includes?("not found") && !check_ok
    warn_msg "hnm command not found — skipping Nix section"
    return false
  end

  nix_found = check_out.includes?("✓ nix") && !check_out.includes?("NOT FOUND")

  unless nix_found
    warn_msg "Nix not installed — running `hnm unpack`"
    unpack_ok = run_command("hnm unpack")
    unless unpack_ok
      fail_msg "hnm unpack failed — skipping update & upgrade"
      return false
    end
    ok "hnm unpack completed"
  else
    ok "Nix installation verified"
    check_out.lines.each { |l| puts "     #{l.colorize(:dark_gray)}" }
  end

  step "Running hnm update"
  update_ok = run_command("hnm update")
  fail_msg "hnm update failed" unless update_ok

  step "Running hnm upgrade"
  upgrade_ok = run_command("hnm upgrade")
  fail_msg "hnm upgrade failed" unless upgrade_ok

  update_ok && upgrade_ok
end

def update_hackeros : Bool
  banner("HackerOS Update")
  step "Running HackerOS update script"
  run_command(HACKEROS_UPDATE_SCRIPT)
end

def update_wallpapers : Bool
  banner("Wallpaper Updates")
  step "Fetching latest wallpapers"
  run_command(WALLPAPERS_UPDATE_SCRIPT)
end

def update_cybersecurity : Bool
  banner("Cybersecurity Updates")
  step "Running cybersecurity-cli update-all"
  run_command("cybersecurity-cli update-all")
end

def update_blue : Bool
  banner("Blue Updates")
  step "Running blue update"
  run_command("blue update")
end

def update_gaming : Bool
  banner("Gaming Updates")
  step "Running gaming-cli update"
  run_command("gaming-cli update")
end

# ── Clean section ─────────────────────────────────────────────────────────────
def do_clean
  banner("System Clean")

  step "APT autoremove"
  sudo_run("apt autoremove -y")

  step "APT clean"
  sudo_run("apt clean")

  step "Flatpak remove unused runtimes"
  run_command("flatpak uninstall --unused -y")

  if Process.run("command -v snap", shell: true).success?
    step "Snap remove disabled snaps"
    # Remove all disabled (old revision) snaps
    run_command(%(snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read name rev; do echo #{Process.quote(SudoState.password)} | sudo -S snap remove "$name" --revision="$rev" 2>/dev/null; done))
  end

  if Process.run("command -v brew", shell: true).success?
    step "Brew cleanup"
    run_command("brew cleanup --prune=all")
  end

  puts ""
  ok "Clean complete"
end

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
    hammer    = update_hammer
    flatpak   = update_flatpak
    brew      = update_brew
    firmware  = update_firmware
    omz       = update_omz
    distrobox = update_distrobox
    hnm       = update_hnm
    hackeros  = update_hackeros
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

# ── Interactive menu ─────────────────────────────────────────────────────────
MENU_ITEMS = [
  {"Q", "Quit",     "Close this terminal"},
  {"R", "Reboot",   "Reboot the system"},
  {"S", "Shutdown", "Shutdown the system"},
  {"L", "Log out",  "Log out from current session"},
  {"T", "Terminal", "Open a new Alacritty terminal"},
  {"C", "Clean",    "Remove unused packages & cache"},
]

def show_gui_menu
  loop do
    key_col_w = 17
    desc_w    = 32
    box_w     = 2 + key_col_w + 2 + desc_w

    puts "┌#{"─" * box_w}┐".colorize(:dark_gray)
    title     = "HackerOS Update System  ·  What's next?"
    title_pad = box_w - title.size - 2
    puts "│  #{title.colorize(:yellow).bold}#{" " * [title_pad, 0].max}│".colorize(:dark_gray)
    puts "├#{"─" * box_w}┤".colorize(:dark_gray)

    MENU_ITEMS.each do |(key, label, desc)|
      key_col  = ("[#{key}]  #{label}").ljust(key_col_w)
      desc_col = desc.ljust(desc_w)
      puts "│  #{key_col.colorize(:white)}  #{desc_col.colorize(:dark_gray)}│".colorize(:dark_gray)
    end

    puts "└#{"─" * box_w}┘".colorize(:dark_gray)
    print "\n  #{"›".colorize(:dark_gray)}  #{"Choice".colorize(:white)}: "

    choice = ""
    STDIN.raw do |io|
      byte = io.read_byte
      if byte
        choice = byte.chr.to_s.upcase
        puts choice.colorize(:cyan).bold
      end
    end

    puts ""

    case choice
    when "Q" then exit(0)
    when "R" then sudo_run("reboot")
    when "S" then sudo_run("shutdown -h now")
    when "L" then run_command("qdbus org.kde.ksmserver /KSMServer logout 0 0 0")
    when "T"
      Process.new("alacritty",
        input:  Process::Redirect::Close,
        output: Process::Redirect::Close,
        error:  Process::Redirect::Close)
    when "C" then do_clean
    else
      warn_msg "Unknown option '#{choice}' — try again"
    end

    puts ""
  end
end

# ── Entry point ──────────────────────────────────────────────────────────────
def main
  gui_mode = false
  OptionParser.parse do |parser|
    parser.banner = "Usage: hackeros-update-system [options]"
    parser.on("--gui-mode", "Run in interactive GUI mode inside terminal") { gui_mode = true }
  end

  unless gui_mode
    Process.new(
      "alacritty",
      args:   ["-e", BIN_PATH, "--gui-mode"],
      input:  Process::Redirect::Close,
      output: Process::Redirect::Close,
      error:  Process::Redirect::Close
    )
    return
  end

  variant = detect_variant
  pwd     = prompt_sudo_password
  results = perform_updates(pwd, variant)
  show_summary(results)
  show_gui_menu
end

main
