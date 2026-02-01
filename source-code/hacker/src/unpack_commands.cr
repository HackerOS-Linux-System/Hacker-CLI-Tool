require "./helpers"
def handle_unpack(args : Array(String))
  if args.empty? || args[0] == "help"
    show_unpack_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "add-ons"
    safe_run("sudo apt install -y wine winetricks")
    safe_run("flatpak install -y flathub io.github.dvlv.boxbuddyrs")
    safe_run("flatpak install -y flathub it.mijorus.winezgui")
    safe_run("flatpak install -y flathub it.mijorus.gearlever")
  when "gs"
    # Installs hacker unpack gaming and cybersecurity
    handle_unpack(["gaming"])
    handle_unpack(["cybersecurity"])
  when "devtools"
    safe_run("flatpak install -y flathub io.atom.Atom")
    safe_run("sudo apt install -y crystal && sudo apt install -y shards")
    safe_run("sudo apt install -y npm && sudo apt install -y nodejs")
    safe_run("flatpak install -y flathub com.visualstudio.code")
    safe_run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
    safe_run("sudo apt install -y golang-go")
    safe_run("sudo apt install -y lua5.4")
    safe_run("sudo snap install zig --beta --classic")
  when "emulators"
    safe_run("flatpak install -y flathub org.shadps4.shadPS4")
    safe_run("flatpak install -y flathub io.ryujinx.Ryujinx")
    safe_run("flatpak install -y flathub com.dosbox_x.DOSBox-X")
    safe_run("sudo snap install rpcs3-emu")
  when "cybersecurity"
    safe_run("distrobox create --name blackarch --image docker.io/blackarchlinux/blackarch:latest")
    safe_run("distrobox enter blackarch")
    puts "#{Colors::YELLOW}Install all BlackArch tools inside the container.#{Colors::RESET}"
  when "select"
    safe_run("~/.hackeros/hacker/hacker-select")
  when "gaming"
    safe_run("flatpak install -y flathub com.valvesoftware.Steam")
    safe_run("flatpak install -y flathub com.github.Matoking.protontricks")
    safe_run("flatpak install -y flathub com.heroicgameslauncher.hgl")
    safe_run("flatpak install -y flathub com.vysp3r.ProtonPlus")
    safe_run("flatpak install -y flathub io.github.giantpinkrobots.varia")
    if args.size > 1 && args[1] == "with-roblox"
      safe_run("flatpak install -y flathub org.vinegarhq.Sober")
      safe_run("flatpak install -y flathub org.vinegarhq.Vinegar")
    end
  when "hacker-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode")
    safe_run("hl run /tmp/Hacker-Mode/unpack.hl")
  when "gamescope-session-steam"
    safe_run("flatpak install -y flathub com.valvesoftware.Steam")
    install_gamescope
    safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam")
    safe_run("hl run /tmp/gamescope-session-steam/unpack.hl")
  when "xanmod"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-xanmod.sh")
  when "liquorix"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-liquorix.sh")
  when "automatic-updates"
    safe_run("sudo mv /usr/share/HackerOS/Archived/Services/hup.service /etc/systemd/system/")
    safe_run("sudo systemctl daemon-reload")
    safe_run("sudo systemctl enable hup.service")
  when "alacritty-config"
    safe_run("mkdir -p ~/.config/alacritty")
    safe_run("cp /usr/share/HackerOS/Archived/alacritty.toml ~/.config/alacritty/alacritty.toml")
    puts "#{Colors::GREEN}Alacritty configuration has been successfully installed to ~/.config/alacritty/alacritty.toml#{Colors::RESET}"
  when "hackeros-tv"
    safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV")
    safe_run("hl run /tmp/HackerOS-TV/unpack.hl")
  when "security-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode")
    safe_run("hl run /tmp/Security-Mode/unpack.hl")
  when "winboat"
    safe_run("wget https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-amd64.deb -O /tmp/winboat-0.9.0-amd64.deb")
    safe_run("sudo apt install -y /tmp/winboat-0.9.0-amd64.deb")
  when "nvidia-drivers"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-nvidia-drivers.sh")
  when "hl-utils"
    safe_run("wget https://github.com/HackerOS-Linux-System/Hacker-Lang/releases/download/v1.5/bytes -O /tmp/bytes")
    safe_run("sudo mv /tmp/bytes /usr/bin/bytes")
    safe_run("sudo chmod a+x /usr/bin/bytes")
    safe_run("wget https://github.com/HackerOS-Linux-System/Hacker-Lang/releases/download/v1.5/hli -O /tmp/hli")
    safe_run("sudo mv /tmp/hli /usr/bin/hli")
    safe_run("sudo chmod a+x /usr/bin/hli")
  when "hl-advanced"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/Hacker-Lang/main/hacker-packages/install-hla.hl -o /tmp/install-hla.hl")
    safe_run("hl run /tmp/install-hla.hl")
  when "flox"
    safe_run("wget https://downloads.flox.dev/by-env/stable/deb/flox.x86_64-linux.deb -O /tmp/flox.x86_64-linux.deb")
    safe_run("sudo apt install -y /tmp/flox.x86_64-linux.deb")
  when "hackeros-builder"
    safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/HackerOS-Builder/main/install.hl -O /tmp/install.hacker")
    safe_run("hl run /tmp/install.hl")
  when "isolator"
    safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/Isolator/main/install.hl -O /tmp/install.hacker")
    safe_run("hl run /tmp/install.hl")
  else
    puts "#{Colors::RED}Unknown unpack subcommand: #{subcommand}#{Colors::RESET}"
    show_unpack_help
    exit(1)
  end
end
def show_unpack_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Unpack subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}add-ons #{Colors::RESET}- Install wine and related tools"
  puts " #{Colors::GRAY}gs #{Colors::RESET}- Install gaming and cybersecurity"
  puts " #{Colors::GRAY}devtools #{Colors::RESET}- Install development tools"
  puts " #{Colors::GRAY}emulators #{Colors::RESET}- Install emulators"
  puts " #{Colors::GRAY}cybersecurity #{Colors::RESET}- Set up BlackArch container"
  puts " #{Colors::GRAY}select #{Colors::RESET}- Run hacker-select"
  puts " #{Colors::GRAY}gaming #{Colors::RESET}- Install gaming tools"
  puts " #{Colors::GRAY}gaming with-roblox #{Colors::RESET}- Install gaming with Roblox support"
  puts " #{Colors::GRAY}hacker-mode #{Colors::RESET}- Install hacker mode tools"
  puts " #{Colors::GRAY}gamescope-session-steam #{Colors::RESET}- Set up gamescope session for Steam"
  puts " #{Colors::GRAY}xanmod #{Colors::RESET}- Unpack Xanmod kernel"
  puts " #{Colors::GRAY}liquorix #{Colors::RESET}- Unpack Liquorix kernel"
  puts " #{Colors::GRAY}automatic-updates #{Colors::RESET}- Enable automatic updates"
  puts " #{Colors::GRAY}alacritty-config #{Colors::RESET}- Install Alacritty configuration (copies alacritty.toml to ~/.config/alacritty/)"
  puts " #{Colors::GRAY}hackeros-tv #{Colors::RESET}- Install HackerOS TV"
  puts " #{Colors::GRAY}security-mode #{Colors::RESET}- Install Security Mode"
  puts " #{Colors::GRAY}winboat #{Colors::RESET}- Install Winboat"
  puts " #{Colors::GRAY}nvidia-drivers #{Colors::RESET}- Install NVIDIA drivers"
  puts " #{Colors::GRAY}hl-utils #{Colors::RESET}- Install hl-utils binaries"
  puts " #{Colors::GRAY}hl-advanced#{Colors::RESET}- Install the advanced Hacker programming language."
  puts " #{Colors::GRAY}flox #{Colors::RESET}- Install Flox"
  puts " #{Colors::GRAY}hackeros-builder #{Colors::RESET}- Install HackerOS Builder"
  puts " #{Colors::GRAY}isolator #{Colors::RESET}- Install isolator"
end
