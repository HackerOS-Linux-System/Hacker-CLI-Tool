require "./helpers"
require "./unpack_commands"
require "./run_commands"
require "./game"
def main
  if ARGV.empty? || ARGV[0] == "help"
    show_main_help
    exit(0)
  end
  command = ARGV[0]
  case command
  when "unpack"
    handle_unpack(ARGV[1..])
  when "help-ui"
    safe_run("~/.hackeros/hacker/hacker-help")
  when "docs"
    safe_run("~/.hackeros/hacker/hacker-docs")
  when "install"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker install <package>#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("sudo apt install -y #{package}")
  when "remove"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker remove <package>#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("sudo apt remove -y #{package}")
  when "flatpak-install"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker flatpak-install <package>#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("flatpak install -y #{package}")
  when "flatpak-remove"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker flatpak-remove <package>#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("flatpak remove -y #{package}")
  when "system"
    handle_system(ARGV[1..])
  when "run"
    handle_run(ARGV[1..])
  when "update"
    safe_run("~/.hackeros/hacker/HackerOS-Updater")
  when "game"
    play_text_game
  when "hacker-lang"
    puts "#{Colors::YELLOW}To use the hacker programming language for files/scripts with .hacker extension,#{Colors::RESET}"
    puts "#{Colors::YELLOW}use the command 'hackerc' to compile or run them.#{Colors::RESET}"
    puts "#{Colors::YELLOW}Note: This is for advanced users. Ensure hackerc is installed separately.#{Colors::RESET}"
  when "ascii"
    safe_run("cat /usr/share/HackerOS/Config-Files/HackerOS-Ascii")
  when "shell"
    safe_run("~/.hackeros/hacker/hacker-shell")
  when "enter"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker enter <container>#{Colors::RESET}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox enter #{container}")
  when "remove-container"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker remove-container <container>#{Colors::RESET}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox rm #{container}")
  when "restart"
    if ARGV.size < 2
      puts "#{Colors::RED}Usage: hacker restart <service>#{Colors::RESET}"
      exit(1)
    end
    service = ARGV[1]
    safe_run("sudo systemctl restart #{service}")
  else
    puts "#{Colors::RED}Unknown command: #{command}#{Colors::RESET}"
    show_main_help
    exit(1)
  end
end
def show_main_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}HackerOS Tool - Available commands:#{Colors::RESET}"
  puts " #{Colors::GRAY}unpack #{Colors::RESET}- Unpack and install various components (use 'hacker unpack' for subcommands)"
  puts " #{Colors::GRAY}help #{Colors::RESET}- Show this help"
  puts " #{Colors::GRAY}help-ui #{Colors::RESET}- Show help UI"
  puts " #{Colors::GRAY}docs #{Colors::RESET}- Show documentation"
  puts " #{Colors::GRAY}install <pkg> #{Colors::RESET}- Install APT package"
  puts " #{Colors::GRAY}remove <pkg> #{Colors::RESET}- Remove APT package"
  puts " #{Colors::GRAY}flatpak-install <pkg> #{Colors::RESET}- Install Flatpak package"
  puts " #{Colors::GRAY}flatpak-remove <pkg> #{Colors::RESET}- Remove Flatpak package"
  puts " #{Colors::GRAY}system #{Colors::RESET}- System-related commands (use 'hacker system' for subcommands)"
  puts " #{Colors::GRAY}run #{Colors::RESET}- Run scripts and tools (use 'hacker run' for subcommands)"
  puts " #{Colors::GRAY}update #{Colors::RESET}- Run HackerOS updater"
  puts " #{Colors::GRAY}game #{Colors::RESET}- Play a text-based game"
  puts " #{Colors::GRAY}hacker-lang #{Colors::RESET}- Info about hacker language"
  puts " #{Colors::GRAY}ascii #{Colors::RESET}- Display ASCII art"
  puts " #{Colors::GRAY}shell #{Colors::RESET}- Run hacker shell"
  puts " #{Colors::GRAY}enter <container> #{Colors::RESET}- Enter Distrobox container"
  puts " #{Colors::GRAY}remove-container <container> #{Colors::RESET}- Remove Distrobox container"
  puts " #{Colors::GRAY}restart <service> #{Colors::RESET}- Restart system service"
end
def handle_system(args : Array(String))
  if args.empty?
    puts "#{Colors::BOLD}#{Colors::MAGENTA}System subcommands:#{Colors::RESET}"
    puts " #{Colors::GRAY}logs #{Colors::RESET}- Display system logs"
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "logs"
    safe_run("journalctl -xe")
  else
    puts "#{Colors::RED}Unknown system subcommand: #{subcommand}#{Colors::RESET}"
    exit(1)
  end
end
main
