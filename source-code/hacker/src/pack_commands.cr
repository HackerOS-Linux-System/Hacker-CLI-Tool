require "./helpers"

def handle_pack(args : Array(String))
  if args.empty? || args[0] == "help"
    show_pack_help
    exit(0)
  end

  subcommand = args[0]

  case subcommand
  when "install"
    puts "#{Colors::YELLOW}Pobieranie remove.hl z HackerLand i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/remove.hl -o /tmp/remove.hl")
    safe_run("hl run /tmp/remove.hl")
    safe_run("rm -f /tmp/remove.hl")
    puts "#{Colors::GREEN}Pełne usunięcie (pack all) wykonane za pomocą remove.hl z HackerLand.#{Colors::RESET}"

  when "add-ons"
    safe_run("sudo apt remove -y wine winetricks")
    safe_run("flatpak uninstall -y flathub io.github.dvlv.boxbuddyrs")
    safe_run("flatpak uninstall -y flathub it.mijorus.winezgui")
    safe_run("flatpak uninstall -y flathub it.mijorus.gearlever")

  when "gs"
    handle_pack(["gaming"])
    handle_pack(["cybersecurity"])

  when "devtools"
    safe_run("flatpak uninstall -y flathub io.atom.Atom")
    safe_run("sudo apt remove -y crystal shards")
    safe_run("sudo apt remove -y npm nodejs")
    safe_run("flatpak uninstall -y flathub com.visualstudio.code")
    safe_run("rustup self uninstall -y || true")
    safe_run("sudo apt remove -y golang-go")
    safe_run("sudo apt remove -y lua5.4")
    safe_run("sudo snap remove zig")

  when "emulators"
    safe_run("flatpak uninstall -y flathub org.shadps4.shadPS4")
    safe_run("flatpak uninstall -y flathub io.ryujinx.Ryujinx")
    safe_run("flatpak uninstall -y flathub com.dosbox_x.DOSBox-X")
    safe_run("sudo snap remove rpcs3-emu")

  when "cybersecurity"
    safe_run("distrobox rm -f blackarch")

  when "select"
    safe_run("~/.hackeros/hacker/hacker-select --pack")

  when "gaming"
    safe_run("flatpak uninstall -y flathub com.valvesoftware.Steam")
    safe_run("flatpak uninstall -y flathub com.github.Matoking.protontricks")
    safe_run("flatpak uninstall -y flathub com.heroicgameslauncher.hgl")
    safe_run("flatpak uninstall -y flathub com.vysp3r.ProtonPlus")
    safe_run("flatpak uninstall -y flathub io.github.giantpinkrobots.varia")
    safe_run("flatpak uninstall -y flathub org.vinegarhq.Sober")
    safe_run("flatpak uninstall -y flathub org.vinegarhq.Vinegar")

  when "hacker-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode || true")
    safe_run("hl run /tmp/Hacker-Mode/remove.hl")
    safe_run("rm -rf /tmp/Hacker-Mode")

  when "gamescope-session-steam"
    safe_run("flatpak uninstall -y flathub com.valvesoftware.Steam")
    safe_run("flatpak uninstall -y flathub org.freedesktop.Platform.VulkanLayer.gamescope")
    safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam || true")
    safe_run("hl run /tmp/gamescope-session-steam/remove.hl")
    safe_run("rm -rf /tmp/gamescope-session-steam")

  when "xanmod"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-xanmod.sh")

  when "liquorix"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-liquorix.sh")

  when "automatic-updates"
    safe_run("sudo systemctl disable --now hup.service || true")
    safe_run("sudo rm -f /etc/systemd/system/hup.service")
    safe_run("sudo systemctl daemon-reload")

  when "alacritty-config"
    safe_run("rm -f ~/.config/alacritty/alacritty.toml")
    puts "#{Colors::GREEN}Konfiguracja Alacritty usunięta.#{Colors::RESET}"

  when "hackeros-tv"
    safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV || true")
    safe_run("hl run /tmp/HackerOS-TV/remove.hl")
    safe_run("rm -rf /tmp/HackerOS-TV")

  when "security-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode || true")
    safe_run("hl run /tmp/Security-Mode/remove.hl")
    safe_run("rm -rf /tmp/Security-Mode")

  when "winboat"
    safe_run("sudo apt remove -y winboat || true")

  when "nvidia-drivers"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-nvidia-drivers.sh")

  when "hl-utils"
    safe_run("sudo rm -f /usr/bin/bytes /usr/bin/hli")

  when "flox"
    safe_run("sudo apt remove -y flox || true")

  when "hackeros-builder"
    safe_run("sudo rm -f /usr/bin/hackeros-builder")

  when "isolator"
    safe_run("sudo rm -f /usr/bin/isolator")

  when "hammer"
    puts "#{Colors::YELLOW}Pobieranie remove.hl z hammer i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/hammer/main/remove.hl -o /tmp/remove.hl")
    safe_run("hl run /tmp/remove.hl")
    safe_run("rm -f /tmp/remove.hl")
    puts "#{Colors::GREEN}Usunięcie hammer wykonane za pomocą remove.hl.#{Colors::RESET}"

  when "hackerland"
    puts "#{Colors::YELLOW}Pobieranie remove.hl z HackerLand i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/HackerLand/main/remove.hl -o /tmp/remove.hl")
    safe_run("hl run /tmp/remove.hl")
    safe_run("rm -f /tmp/remove.hl")
    puts "#{Colors::GREEN}Usunięcie hackerland wykonane za pomocą remove.hl.#{Colors::RESET}"

  when "H#"
    puts "#{Colors::YELLOW}Pobieranie remove.hl z H# i uruchamianie...#{Colors::RESET}"
    safe_run("curl -L https://raw.githubusercontent.com/HackerOS-Linux-System/H-Sharp/main/remove.hl -o /tmp/remove.hl")
    safe_run("hl run /tmp/remove.hl")
    safe_run("rm -f /tmp/remove.hl")
    puts "#{Colors::GREEN}Usunięcie H# wykonane za pomocą remove.hl.#{Colors::RESET}"

  else
    puts "#{Colors::RED}Nieznane polecenie pack: #{subcommand}#{Colors::RESET}"
    show_pack_help
    exit(1)
  end
end

def show_pack_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Podpolecenia pack (usuwanie/pakowanie):#{Colors::RESET}"
  puts " #{Colors::GRAY}install               #{Colors::RESET}- Pełne usunięcie via remove.hl z HackerLand"
  puts " #{Colors::GRAY}add-ons               #{Colors::RESET}- Usuń wine + narzędzia"
  puts " #{Colors::GRAY}gs                    #{Colors::RESET}- Usuń gaming + cybersecurity"
  puts " #{Colors::GRAY}devtools              #{Colors::RESET}- Usuń narzędzia developerskie"
  puts " #{Colors::GRAY}emulators             #{Colors::RESET}- Usuń emulatory"
  puts " #{Colors::GRAY}cybersecurity         #{Colors::RESET}- Usuń BlackArch distrobox"
  puts " #{Colors::GRAY}select                #{Colors::RESET}- hacker-select --pack"
  puts " #{Colors::GRAY}gaming                #{Colors::RESET}- Usuń gaming tools"
  puts " #{Colors::GRAY}hacker-mode           #{Colors::RESET}- Usuń Hacker Mode"
  puts " #{Colors::GRAY}gamescope-session-steam #{Colors::RESET}- Usuń gamescope + Steam session"
  puts " #{Colors::GRAY}xanmod                #{Colors::RESET}- Usuń Xanmod kernel"
  puts " #{Colors::GRAY}liquorix              #{Colors::RESET}- Usuń Liquorix kernel"
  puts " #{Colors::GRAY}automatic-updates     #{Colors::RESET}- Wyłącz auto-updates"
  puts " #{Colors::GRAY}alacritty-config      #{Colors::RESET}- Usuń konfigurację Alacritty"
  puts " #{Colors::GRAY}hackeros-tv           #{Colors::RESET}- Usuń HackerOS TV"
  puts " #{Colors::GRAY}security-mode         #{Colors::RESET}- Usuń Security Mode"
  puts " #{Colors::GRAY}winboat               #{Colors::RESET}- Usuń Winboat"
  puts " #{Colors::GRAY}nvidia-drivers        #{Colors::RESET}- Usuń NVIDIA drivers"
  puts " #{Colors::GRAY}hl-utils              #{Colors::RESET}- Usuń bytes & hli"
  puts " #{Colors::GRAY}flox                  #{Colors::RESET}- Usuń Flox"
  puts " #{Colors::GRAY}hackeros-builder      #{Colors::RESET}- Usuń Builder"
  puts " #{Colors::GRAY}isolator              #{Colors::RESET}- Usuń Isolator"
  puts " #{Colors::GRAY}hammer                #{Colors::RESET}- Usuń hammer via remove.hl"
  puts " #{Colors::GRAY}hackerland            #{Colors::RESET}- Usuń hackerland via remove.hl"
  puts " #{Colors::GRAY}H#                    #{Colors::RESET}- Usuń H# via remove.hl"
end
