require "./helpers"
def handle_pack(args : Array(String))
  if args.empty? || args[0] == "help"
    show_pack_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
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
    safe_run("rustup self uninstall -y")
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
    safe_run("git clone https://github.com/HackerOS-Linux-System/Hacker-Mode.git /tmp/Hacker-Mode")
    safe_run("hl run /tmp/Hacker-Mode/remove.hacker")
  when "gamescope-session-steam"
    safe_run("flatpak uninstall -y flathub com.valvesoftware.Steam")
    safe_run("flatpak uninstall -y flathub org.freedesktop.Platform.VulkanLayer.gamescope")
    safe_run("git clone https://github.com/HackerOS-Linux-System/gamescope-session-steam.git /tmp/gamescope-session-steam")
    safe_run("hl run /tmp/gamescope-session-steam/remove.hacker")
  when "xanmod"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-xanmod.sh") # Assuming a remove script exists; adjust if needed
  when "liquorix"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-liquorix.sh") # Assuming a remove script exists; adjust if needed
  when "automatic-updates"
    safe_run("sudo systemctl disable hup.service")
    safe_run("sudo rm /etc/systemd/system/hup.service")
    safe_run("sudo systemctl daemon-reload")
  when "alacritty-config"
    safe_run("rm -f ~/.config/alacritty/alacritty.toml")
    puts "#{Colors::GREEN}Alacritty configuration has been removed.#{Colors::RESET}"
  when "hackeros-tv"
    safe_run("git clone https://github.com/HackerOS-Linux-System/HackerOS-TV.git /tmp/HackerOS-TV")
    safe_run("hl run /tmp/HackerOS-TV/remove.hacker")
  when "security-mode"
    safe_run("git clone https://github.com/HackerOS-Linux-System/Security-Mode.git /tmp/Security-Mode")
    safe_run("hl run /tmp/Security-Mode/remove.hacker")
  when "winboat"
    safe_run("sudo apt remove -y winboat")
  when "nvidia-drivers"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-nvidia-drivers.sh") # Assuming a remove script exists; adjust if needed
  when "hl-utils"
    safe_run("sudo rm -f /usr/bin/bytes")
    safe_run("sudo rm -f /usr/bin/hli")
  when "hackerscript"
    safe_run("sudo rm -f /usr/bin/virus")
    safe_run("rm -rf ~/.HackerScript/")
  when "flox"
    safe_run("sudo apt remove -y flox")
  when "hackeros-builder"
    safe_run("sudo rm -f /usr/bin/hackeros-builder")
  when "isolator"
    safe_run("sudo rm -f /usr/bin/isolator")
  else
    puts "#{Colors::RED}Unknown pack subcommand: #{subcommand}#{Colors::RESET}"
    show_pack_help
    exit(1)
  end
end
def show_pack_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Pack subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}add-ons #{Colors::RESET}- Remove wine and related tools"
  puts " #{Colors::GRAY}gs #{Colors::RESET}- Remove gaming and cybersecurity"
  puts " #{Colors::GRAY}devtools #{Colors::RESET}- Remove development tools"
  puts " #{Colors::GRAY}emulators #{Colors::RESET}- Remove emulators"
  puts " #{Colors::GRAY}cybersecurity #{Colors::RESET}- Remove BlackArch container"
  puts " #{Colors::GRAY}select #{Colors::RESET}- Run hacker-select in pack mode"
  puts " #{Colors::GRAY}gaming #{Colors::RESET}- Remove gaming tools"
  puts " #{Colors::GRAY}hacker-mode #{Colors::RESET}- Remove hacker mode tools"
  puts " #{Colors::GRAY}gamescope-session-steam #{Colors::RESET}- Remove gamescope session for Steam"
  puts " #{Colors::GRAY}xanmod #{Colors::RESET}- Remove Xanmod kernel"
  puts " #{Colors::GRAY}liquorix #{Colors::RESET}- Remove Liquorix kernel"
  puts " #{Colors::GRAY}automatic-updates #{Colors::RESET}- Disable automatic updates"
  puts " #{Colors::GRAY}alacritty-config #{Colors::RESET}- Remove Alacritty configuration"
  puts " #{Colors::GRAY}hackeros-tv #{Colors::RESET}- Remove HackerOS TV"
  puts " #{Colors::GRAY}security-mode #{Colors::RESET}- Remove Security Mode"
  puts " #{Colors::GRAY}winboat #{Colors::RESET}- Remove Winboat"
  puts " #{Colors::GRAY}nvidia-drivers #{Colors::RESET}- Remove NVIDIA drivers"
  puts " #{Colors::GRAY}hl-utils #{Colors::RESET}- Remove hl-utils binaries"
  puts " #{Colors::GRAY}hackerscript #{Colors::RESET}- Remove HackerScript"
  puts " #{Colors::GRAY}flox #{Colors::RESET}- Remove Flox"
  puts " #{Colors::GRAY}hackeros-builder #{Colors::RESET}- Remove HackerOS Builder"
  puts " #{Colors::GRAY}isolator #{Colors::RESET}- Remove isolator"
end
