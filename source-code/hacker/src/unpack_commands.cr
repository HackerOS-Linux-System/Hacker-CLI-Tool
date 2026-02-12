require "./helpers"

def handle_unpack(args : Array(String))
  if args.empty? || args[0] == "help"
    show_unpack_help
    exit(0)
  end

  subcommand = args[0]

  case subcommand
  when "install"
    puts "#{Colors::YELLOW}Pobieranie install.hl z HackerLand i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/install.hl -o /tmp/install.hl")
    safe_run("hl run /tmp/install.hl")
    safe_run("rm -f /tmp/install.hl")
    puts "#{Colors::GREEN}Pełna instalacja (unpack all) wykonana za pomocą install.hl z HackerLand.#{Colors::RESET}"

  when "add-ons"
    safe_run("sudo apt install -y wine winetricks")
    safe_run("flatpak install -y --noninteractive flathub io.github.dvlv.boxbuddyrs")
    safe_run("flatpak install -y --noninteractive flathub it.mijorus.winezgui")
    safe_run("flatpak install -y --noninteractive flathub it.mijorus.gearlever")

  when "gs"
    handle_unpack(["gaming"])
    handle_unpack(["cybersecurity"])

  when "devtools"
    safe_run("flatpak install -y --noninteractive flathub io.atom.Atom")
    safe_run("sudo apt install -y crystal shards")
    safe_run("sudo apt install -y npm nodejs")
    safe_run("flatpak install -y --noninteractive flathub com.visualstudio.code")
    safe_run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
    safe_run("sudo apt install -y golang-go")
    safe_run("sudo apt install -y lua5.4")
    safe_run("sudo snap install zig --beta --classic")

  when "emulators"
    safe_run("flatpak install -y --noninteractive flathub org.shadps4.shadPS4")
    safe_run("flatpak install -y --noninteractive flathub io.ryujinx.Ryujinx")
    safe_run("flatpak install -y --noninteractive flathub com.dosbox_x.DOSBox-X")
    safe_run("sudo snap install rpcs3-emu")

  when "cybersecurity"
    safe_run("distrobox create --name blackarch --image docker.io/blackarchlinux/blackarch:latest --additional-flags \"--privileged\" || true")
    puts "#{Colors::YELLOW}Kontener BlackArch utworzony. Wejdź: distrobox enter blackarch#{Colors::RESET}"
    puts "#{Colors::YELLOW}W środku: pacman -Syu && pacman -S blackarch (lub wybrane narzędzia).#{Colors::RESET}"

  when "select"
    safe_run("~/.hackeros/hacker/hacker-select")

  when "gaming"
    safe_run("flatpak install -y --noninteractive flathub com.valvesoftware.Steam")
    safe_run("flatpak install -y --noninteractive flathub com.github.Matoking.protontricks")
    safe_run("flatpak install -y --noninteractive flathub com.heroicgameslauncher.hgl")
    safe_run("flatpak install -y --noninteractive flathub com.vysp3r.ProtonPlus")
    safe_run("flatpak install -y --noninteractive flathub io.github.giantpinkrobots.varia")

    if args.size > 1 && args[1].downcase == "with-roblox"
      safe_run("flatpak install -y --noninteractive flathub org.vinegarhq.Sober")
      safe_run("flatpak install -y --noninteractive flathub org.vinegarhq.Vinegar")
      puts "#{Colors::GREEN}Dodano Roblox support (Sober + Vinegar).#{Colors::RESET}"
    end

  when "hacker-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode || true")
    safe_run("hl run /tmp/Hacker-Mode/unpack.hl")
    safe_run("rm -rf /tmp/Hacker-Mode")

  when "gamescope-session-steam"
    safe_run("flatpak install -y --noninteractive flathub com.valvesoftware.Steam")
    install_gamescope  # <-- poprawione: bez warunkowego sprawdzenia. Musi być zdefiniowane w helpers.cr!
    safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam || true")
    safe_run("hl run /tmp/gamescope-session-steam/unpack.hl")
    safe_run("rm -rf /tmp/gamescope-session-steam")

  when "xanmod"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-xanmod.sh")

  when "liquorix"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-liquorix.sh")

  when "automatic-updates"
    safe_run("sudo cp /usr/share/HackerOS/Archived/Services/hup.service /etc/systemd/system/hup.service")
    safe_run("sudo systemctl daemon-reload")
    safe_run("sudo systemctl enable --now hup.service")

  when "alacritty-config"
    safe_run("mkdir -p ~/.config/alacritty")
    safe_run("cp /usr/share/HackerOS/Archived/alacritty.toml ~/.config/alacritty/alacritty.toml")
    puts "#{Colors::GREEN}Konfiguracja Alacritty zainstalowana.#{Colors::RESET}"

  when "hackeros-tv"
    safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV || true")
    safe_run("hl run /tmp/HackerOS-TV/unpack.hl")
    safe_run("rm -rf /tmp/HackerOS-TV")

  when "security-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode || true")
    safe_run("hl run /tmp/Security-Mode/unpack.hl")
    safe_run("rm -rf /tmp/Security-Mode")

  when "winboat"
    safe_run("wget https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-amd64.deb -O /tmp/winboat.deb")
    safe_run("sudo apt install -y /tmp/winboat.deb")
    safe_run("rm -f /tmp/winboat.deb")

  when "nvidia-drivers"
    safe_run("/usr/share/HackerOS/Scripts/Bin/unpack-nvidia-drivers.sh")

  when "hl-utils"
    safe_run("wget https://github.com/Bytes-Repository/Bytes-CLI-Tool/releases/download/v0.6/bytes -O /tmp/bytes")
    safe_run("sudo mv /tmp/bytes /usr/bin/bytes")
    safe_run("sudo chmod +x /usr/bin/bytes")
    safe_run("wget https://github.com/HackerOS-Linux-System/Hacker-Lang/releases/download/v1.6.3/hli -O /tmp/hli")
    safe_run("sudo mv /tmp/hli /usr/bin/hli")
    safe_run("sudo chmod +x /usr/bin/hli")

  when "flox"
    safe_run("wget https://downloads.flox.dev/by-env/stable/deb/flox.x86_64-linux.deb -O /tmp/flox.deb")
    safe_run("sudo apt install -y /tmp/flox.deb")
    safe_run("rm -f /tmp/flox.deb")

  when "hackeros-builder"
    safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/HackerOS-Builder/main/install.hl -O /tmp/install-builder.hl")
    safe_run("hl run /tmp/install-builder.hl")
    safe_run("rm -f /tmp/install-builder.hl")

  when "isolator"
    safe_run("wget https://raw.githubusercontent.com/HackerOS-Linux-System/Isolator/main/install.hl -O /tmp/install-isolator.hl")
    safe_run("hl run /tmp/install-isolator.hl")
    safe_run("rm -f /tmp/install-isolator.hl")

  when "hydra"
    puts "#{Colors::YELLOW}Pobieranie unpack.hl z hydra-look-and-feel i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hydra-look-and-feel/main/unpack.hl -o /tmp/unpack.hl")
    safe_run("hl run /tmp/unpack.hl")
    puts "#{Colors::YELLOW}Ostrzeżenie: Nie da się tego usunąć.#{Colors::RESET}"
    puts "#{Colors::GREEN}Instalacja hydra wykonana za pomocą unpack.hl.#{Colors::RESET}"

  when "hammer"
    puts "#{Colors::YELLOW}Pobieranie install.hl z hammer i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hammer/main/install.hl -o /tmp/install.hl")
    safe_run("hl run /tmp/install.hl")
    safe_run("rm -f /tmp/install.hl")
    puts "#{Colors::GREEN}Instalacja hammer wykonana za pomocą install.hl.#{Colors::RESET}"

  when "hackerland"
    puts "#{Colors::YELLOW}Pobieranie install.hl z HackerLand i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/install.hl -o /tmp/install.hl")
    safe_run("hl run /tmp/install.hl")
    safe_run("rm -f /tmp/install.hl")
    puts "#{Colors::GREEN}Instalacja hackerland wykonana za pomocą install.hl.#{Colors::RESET}"

  when "hackerland"
    puts "#{Colors::YELLOW}Pobieranie install.hl z H# i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/H-Sharp/main/install.hl -o /tmp/install.hl")
    safe_run("hl run /tmp/install.hl")
    safe_run("rm -f /tmp/install.hl")
    puts "#{Colors::GREEN}Instalacja H# wykonana za pomocą install.hl.#{Colors::RESET}"

  else
    puts "#{Colors::RED}Nieznane polecenie unpack: #{subcommand}#{Colors::RESET}"
    show_unpack_help
    exit(1)
  end
end

def show_unpack_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Podpolecenia unpack (instalacja/rozpakowywanie):#{Colors::RESET}"
  puts " #{Colors::GRAY}install               #{Colors::RESET}- Pełna instalacja via install.hl z HackerLand"
  puts " #{Colors::GRAY}add-ons               #{Colors::RESET}- Zainstaluj wine + narzędzia"
  puts " #{Colors::GRAY}gs                    #{Colors::RESET}- Zainstaluj gaming + cybersecurity"
  puts " #{Colors::GRAY}devtools              #{Colors::RESET}- Zainstaluj narzędzia developerskie"
  puts " #{Colors::GRAY}emulators             #{Colors::RESET}- Zainstaluj emulatory"
  puts " #{Colors::GRAY}cybersecurity         #{Colors::RESET}- Utwórz BlackArch distrobox"
  puts " #{Colors::GRAY}select                #{Colors::RESET}- Uruchom hacker-select"
  puts " #{Colors::GRAY}gaming                #{Colors::RESET}- Zainstaluj gaming tools"
  puts " #{Colors::GRAY}gaming with-roblox    #{Colors::RESET}- Gaming + Roblox support"
  puts " #{Colors::GRAY}hacker-mode           #{Colors::RESET}- Zainstaluj Hacker Mode"
  puts " #{Colors::GRAY}gamescope-session-steam #{Colors::RESET}- Zainstaluj gamescope + Steam session"
  puts " #{Colors::GRAY}xanmod                #{Colors::RESET}- Zainstaluj Xanmod kernel"
  puts " #{Colors::GRAY}liquorix              #{Colors::RESET}- Zainstaluj Liquorix kernel"
  puts " #{Colors::GRAY}automatic-updates     #{Colors::RESET}- Włącz auto-updates"
  puts " #{Colors::GRAY}alacritty-config      #{Colors::RESET}- Zainstaluj konfigurację Alacritty"
  puts " #{Colors::GRAY}hackeros-tv           #{Colors::RESET}- Zainstaluj HackerOS TV"
  puts " #{Colors::GRAY}security-mode         #{Colors::RESET}- Zainstaluj Security Mode"
  puts " #{Colors::GRAY}winboat               #{Colors::RESET}- Zainstaluj Winboat"
  puts " #{Colors::GRAY}nvidia-drivers        #{Colors::RESET}- Zainstaluj NVIDIA drivers"
  puts " #{Colors::GRAY}hl-utils              #{Colors::RESET}- Zainstaluj bytes & hli"
  puts " #{Colors::GRAY}flox                  #{Colors::RESET}- Zainstaluj Flox"
  puts " #{Colors::GRAY}hackeros-builder      #{Colors::RESET}- Zainstaluj Builder"
  puts " #{Colors::GRAY}isolator              #{Colors::RESET}- Zainstaluj Isolator"
  puts " #{Colors::GRAY}hydra                 #{Colors::RESET}- Zainstaluj hydra via unpack.hl (nieusuwalne)"
  puts " #{Colors::GRAY}hammer                #{Colors::RESET}- Zainstaluj hammer via install.hl"
  puts " #{Colors::GRAY}hackerland            #{Colors::RESET}- Zainstaluj hackerland via install.hl"
  puts " #{Colors::GRAY}H#                    #{Colors::RESET}- Zainstaluj H# via install.hl"
end
