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
