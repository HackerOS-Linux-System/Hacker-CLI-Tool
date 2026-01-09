require "./helpers"

def handle_run(args : Array(String))
  if args.empty?
    show_run_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "update-system"
    safe_run("/usr/share/HackerOS/Scripts/Bin/update-system.sh")
  when "check-updates"
    safe_run("/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh")
  when "steam"
    safe_run("/usr/share/HackerOS/Scripts/Steam/HackerOS-Steam.sh")
  when "hacker-launcher"
    safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher")
  when "hackeros-game-mode"
    safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Game-Mode.AppImage")
  when "update-hackeros"
    safe_run("/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh")
  when "update-wallpapers"
    safe_run("/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh")
  when "remove-debian-kernel"
    safe_run("/usr/share/HackerOS/Scripts/Bin/remove-debian-kernel.sh")
  when "HackerOS-Store"
    safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Store")
  when "HackerOS-Steam"
    safe_run("HackerOS-Steam run")
  when "HackerDeck"
    safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerDeck")
  when "Hacker-Term"
    safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker-Term")
  when "build-hackeros"
    safe_run("sudo /usr/share/HackerOS/Archived/build-hackeros")
  else
    puts "#{Colors::RED}Unknown run subcommand: #{subcommand}#{Colors::RESET}"
    show_run_help
    exit(1)
  end
end

def show_run_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Run subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}update-system #{Colors::RESET}- Update system"
  puts " #{Colors::GRAY}check-updates #{Colors::RESET}- Check for updates"
  puts " #{Colors::GRAY}steam #{Colors::RESET}- Run Steam script"
  puts " #{Colors::GRAY}hacker-launcher #{Colors::RESET}- Run Hacker Launcher"
  puts " #{Colors::GRAY}hackeros-game-mode #{Colors::RESET}- Run Game Mode AppImage"
  puts " #{Colors::GRAY}update-hackeros #{Colors::RESET}- Update HackerOS"
  puts " #{Colors::GRAY}update-wallpapers #{Colors::RESET}- Update wallpapers"
  puts " #{Colors::GRAY}remove-debian-kernel #{Colors::RESET}- Remove Debian kernel"
  puts " #{Colors::GRAY}HackerOS-Store #{Colors::RESET}- Run HackerOS Store"
  puts " #{Colors::GRAY}HackerOS-Steam #{Colors::RESET}- Run HackerOS Steam"
  puts " #{Colors::GRAY}HackerDeck #{Colors::RESET}- Run HackerDeck"
  puts " #{Colors::GRAY}Hacker-Term #{Colors::RESET}- Run Hacker-Term"
  puts " #{Colors::GRAY}build-hackeros #{Colors::RESET}- Build HackerOS"
end
