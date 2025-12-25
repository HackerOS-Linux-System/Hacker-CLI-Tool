require "./helpers"
require "./unpack_commands"
require "./pack_commands"
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
  when "pack"
    handle_pack(ARGV[1..])
  when "help-ui"
    safe_run("~/.hackeros/hacker/hacker-help")
  when "docs"
    safe_run("~/.hackeros/hacker/hacker-docs")
  when "install"
    if ARGV.size < 2
      puts "#{Colors::RED}Please use 'hpm install <package>'#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    puts "please use hpm install #{package}"
    exit(0)
  when "remove"
    if ARGV.size < 2
      puts "#{Colors::RED}Please use 'hpm remove <package>'#{Colors::RESET}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    puts "please use hpm remove #{package}"
    exit(0)
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
    handle_update(ARGV[1..])
  when "game"
    play_text_game
  when "hacker-lang"
     puts "#{Colors::YELLOW}To use the hacker programming language for files/scripts with the .hacker extension, #{Colors::RESET}"
     puts "#{Colors::YELLOW}use the \"hackerc\" command, or for larger projects, \"hli\" and \"bytes\" to download dependencies, to compile or run them.#{Colors::RESET}"
     puts "#{Colors::YELLOW}Note: This command is intended for advanced users. Make sure the hackerc program is installed separately.#{Colors::RESET}"
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
  when "plugin"
    handle_plugin(ARGV[1..])
  when "enable"
    handle_enable(ARGV[1..])
  when "disable"
    handle_disable(ARGV[1..])
  when "how-to-create-commands"
    puts "#{Colors::YELLOW}To create a custom command:#{Colors::RESET}"
    puts "Create a file {command-name}.hacker in ~/.config/hackeros/hacker/custom-commands/"
    puts "An example file for a custom command can be found at: https://github.com/HackerOS-Linux-System/Hacker-CLI-Tool/blob/main/hacker/config-files/custom-commands/example.hacker"
  when "index"
    show_hackeros_tools
  when "--version"
    puts "#{Colors::GREEN}Latest version of the hacker tool: 2.1#{Colors::RESET}"
  when "--hackeros"
    puts "#{Colors::GREEN}Latest version of HackerOS: 4.1#{Colors::RESET}"
  when "info"
    puts "#{Colors::GREEN}Latest version of the hacker tool: 2.1#{Colors::RESET}"
    puts "#{Colors::GREEN}Latest version of HackerOS: 4.1#{Colors::RESET}"
  else
    custom_file = CUSTOM_DIR / "#{command}.hacker"
    if File.exists?(custom_file)
      begin
        config = parse_hacker_file(custom_file.to_s)
        exec_cmd = config["exec"]?.as?(String)
        if exec_cmd
          safe_run("#{exec_cmd} #{ARGV[1..].join(" ")}")
        else
          puts "#{Colors::RED}No 'exec' defined in custom command file.#{Colors::RESET}"
          exit(1)
        end
      rescue ex
        puts "#{Colors::RED}Error processing custom command: #{ex.message}#{Colors::RESET}"
        exit(1)
      end
    else
      found = false
      Dir.glob((PLUGIN_DIR / "*.hacker").to_s).each do |f_path|
        begin
          config = parse_hacker_file(f_path)
          next unless config["enabled"]? == "true"
          commands = config["commands"]?.as?(Config)
          next unless commands
          sub_config = commands[command]?.as?(Config)
          next unless sub_config
          exec_cmd = sub_config["exec"]?.as?(String)
          if exec_cmd
            safe_run("#{exec_cmd} #{ARGV[1..].join(" ")}")
            found = true
            break
          end
        rescue
          # Skip invalid plugins
        end
      end
      unless found
        puts "#{Colors::RED}Unknown command: #{command}#{Colors::RESET}"
        show_main_help
        exit(1)
      end
    end
  end
end
def handle_update(args : Array(String))
  updater_path = "~/.hackeros/hacker/HackerOS-Updater"
  better_updater_path = "~/.hackeros/hacker/HackerOS-Update-Better"
  if args.empty?
    safe_run(updater_path)
  else
    flag = args[0]
    case flag
    when "--with-gui"
      safe_run("#{updater_path} --with-gui")
    when "--gui-mode"
      safe_run("#{updater_path} --gui-mode")
    when "--better"
      safe_run(better_updater_path)
    else
      puts "#{Colors::RED}Unknown flag for update: #{flag}#{Colors::RESET}"
      puts "Available flags: --with-gui, --gui-mode, --better"
      exit(1)
    end
  end
end
def show_hackeros_tools
  puts "#{Colors::BOLD}#{Colors::MAGENTA}HackerOS Tools Index:#{Colors::RESET}"
  puts " * bytes - manager pakietow dla hacker lang"
  puts " * hli - narzedzie dla duzych projektow w hacker lang"
  puts " * hackerc - narzedzie na malych projektow/skrytpow w hacker lang"
  puts " * hacker - glownie narzedzie cli hackeros"
  puts " * Hacker Kernel - jadro hackeros jezeli chcesz rozwijac skontaktuj sie na: gmail - hackeros068@gmail.com lub https://github.com/orgs/HackerOS-Linux-System/discussions"
  puts " * HackerOS Steam - kontner dla steam"
  puts " * HackerOS Welcome - Aplikacja powitalna hackeros"
  puts " * HackerOS App - interfejs gui dla narzedzia hacker + sklep z programami"
  puts " * Security Mode - tryb do testow penetracyjnych"
  puts " * Hacker Mode - tryb gry"
  puts " * isolator - narzedzie cli do instalacji pakietow w izolowanych srodowiskach podman"
  puts " * hpm - fronted dla apt + graficzna instalacja pakietow flatpak, apt, snap"
  puts " * HackerOS Game Mode - tryb gry inspirowany asus armoury crate"
  puts " * hup - system automatycznych aktualizacji"
  puts " * hroot - system do atomowego systemu instacji pakietow/aktualizacji"
  puts " * HackerOS Games - gui do uruchamiania gier: starblaster, bit-jump"
  puts " * HackerOS Cockpit (archiwum) - centrum sterowania systemem w przegladarce"
  puts " * Hacker Launcher - Uruchamiaj gry windows za pomoca tej aplikacji"
  puts " * Blue Enviroment (BETA - niestabilne) - jezeli chcesz pomoc w rozwoju srodowiska graficznego hackeros skontaktuj sie na gmail - hackeros068@gmail.com lub https://github.com/orgs/HackerOS-Linux-System/discussions"
end
def show_main_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}HackerOS Tool - Available commands:#{Colors::RESET}"
  puts " #{Colors::GRAY}unpack #{Colors::RESET}- Unpack and install various components (use 'hacker unpack' for subcommands)"
  puts " #{Colors::GRAY}pack #{Colors::RESET}- Pack and remove various components (use 'hacker pack' for subcommands)"
  puts " #{Colors::GRAY}help #{Colors::RESET}- Show this help"
  puts " #{Colors::GRAY}help-ui #{Colors::RESET}- Show help UI"
  puts " #{Colors::GRAY}docs #{Colors::RESET}- Show documentation"
  puts " #{Colors::GRAY}flatpak-install <pkg> #{Colors::RESET}- Install Flatpak package"
  puts " #{Colors::GRAY}flatpak-remove <pkg> #{Colors::RESET}- Remove Flatpak package"
  puts " #{Colors::GRAY}system #{Colors::RESET}- System-related commands (use 'hacker system' for subcommands)"
  puts " #{Colors::GRAY}run #{Colors::RESET}- Run scripts and tools (use 'hacker run' for subcommands)"
  puts " #{Colors::GRAY}update [ --with-gui | --gui-mode | --better ] #{Colors::RESET}- Run HackerOS updater (with optional flags)"
  puts " #{Colors::GRAY}game #{Colors::RESET}- Play a text-based game"
  puts " #{Colors::GRAY}hacker-lang #{Colors::RESET}- Info about hacker language"
  puts " #{Colors::GRAY}ascii #{Colors::RESET}- Display ASCII art"
  puts " #{Colors::GRAY}shell #{Colors::RESET}- Run hacker shell"
  puts " #{Colors::GRAY}enter <container> #{Colors::RESET}- Enter Distrobox container"
  puts " #{Colors::GRAY}remove-container <container> #{Colors::RESET}- Remove Distrobox container"
  puts " #{Colors::GRAY}restart <service> #{Colors::RESET}- Restart system service"
  puts " #{Colors::GRAY}plugin #{Colors::RESET}- Manage plugins (use 'hacker plugin' for subcommands)"
  puts " #{Colors::GRAY}enable #{Colors::RESET}- Enable features (use 'hacker enable' for subcommands)"
  puts " #{Colors::GRAY}disable #{Colors::RESET}- Disable features (use 'hacker disable' for subcommands)"
  puts " #{Colors::GRAY}how-to-create-commands #{Colors::RESET}- Show how to create custom commands"
  puts " #{Colors::GRAY}index #{Colors::RESET}- Show index of all HackerOS tools"
  puts " #{Colors::GRAY}info #{Colors::RESET}- Show versions of tool and HackerOS"
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Custom commands:#{Colors::RESET}"
  Dir.glob((CUSTOM_DIR / "*.hacker").to_s).sort.each do |f|
    name = File.basename(f, ".hacker")
    begin
      config = parse_hacker_file(f)
      desc = if description = config["description"]?
               if description.is_a?(String)
                 description
               else
                 "No description"
               end
             else
               "No description"
             end
      puts " #{Colors::GRAY}#{name} #{Colors::RESET}- #{desc}"
    rescue
      puts " #{Colors::GRAY}#{name} #{Colors::RESET}- Invalid config"
    end
  end
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Plugin commands:#{Colors::RESET}"
  Dir.glob((PLUGIN_DIR / "*.hacker").to_s).sort.each do |f|
    begin
      config = parse_hacker_file(f)
      next unless config["enabled"]? == "true"
      commands = config["commands"]?.as?(Config)
      next unless commands
      commands.each do |cmd_name, cmd_config|
        next unless cmd_config.is_a?(String | Config)
        next unless cmd_config.is_a?(Config)
        desc = if description = cmd_config["description"]?
                 if description.is_a?(String)
                   description
                 else
                   "No description"
                 end
               else
                 "No description"
               end
        puts " #{Colors::GRAY}#{cmd_name} #{Colors::RESET}- #{desc}"
      end
    rescue
      # Skip
    end
  end
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
def handle_plugin(args : Array(String))
  if args.empty?
    show_plugin_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "list"
    puts "#{Colors::BOLD}#{Colors::MAGENTA}Plugins:#{Colors::RESET}"
    Dir.glob((PLUGIN_DIR / "*.hacker").to_s).each do |f|
      begin
        config = parse_hacker_file(f)
        name = if name_val = config["name"]?
                 if name_val.is_a?(String)
                   name_val
                 else
                   File.basename(f, ".hacker")
                 end
               else
                 File.basename(f, ".hacker")
               end
        enabled = config["enabled"]? == "true"
        puts " #{name} - #{enabled ? "#{Colors::GREEN}enabled#{Colors::RESET}" : "#{Colors::RED}disabled#{Colors::RESET}"}"
      rescue
        puts " #{File.basename(f, ".hacker")} - #{Colors::RED}invalid#{Colors::RESET}"
      end
    end
  when "enable"
    if args.size < 2
      puts "#{Colors::RED}Usage: hacker plugin enable <plugin-name>#{Colors::RESET}"
      exit(1)
    end
    name = args[1]
    file = PLUGIN_DIR / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "true"
        write_hacker_file(file.to_s, config)
        puts "#{Colors::GREEN}Enabled plugin '#{name}'.#{Colors::RESET}"
      rescue ex
        puts "#{Colors::RED}Error enabling plugin: #{ex.message}#{Colors::RESET}"
      end
    else
      puts "#{Colors::RED}Plugin '#{name}' not found.#{Colors::RESET}"
    end
  when "disable"
    if args.size < 2
      puts "#{Colors::RED}Usage: hacker plugin disable <plugin-name>#{Colors::RESET}"
      exit(1)
    end
    name = args[1]
    file = PLUGIN_DIR / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "false"
        write_hacker_file(file.to_s, config)
        puts "#{Colors::GREEN}Disabled plugin '#{name}'.#{Colors::RESET}"
      rescue ex
        puts "#{Colors::RED}Error disabling plugin: #{ex.message}#{Colors::RESET}"
      end
    else
      puts "#{Colors::RED}Plugin '#{name}' not found.#{Colors::RESET}"
    end
  else
    puts "#{Colors::RED}Unknown plugin subcommand: #{subcommand}#{Colors::RESET}"
    show_plugin_help
    exit(1)
  end
end
def show_plugin_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Plugin subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}list #{Colors::RESET}- List all plugins and their status"
  puts " #{Colors::GRAY}enable <name> #{Colors::RESET}- Enable a plugin"
  puts " #{Colors::GRAY}disable <name> #{Colors::RESET}- Disable a plugin"
end
def handle_enable(args : Array(String))
  if args.empty?
    show_enable_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "motd"
    safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-motd /usr/libexec/")
    safe_run("sudo cp /usr/share/HackerOS/Archived/user-motd.sh /etc/profile.d/")
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    safe_run("sudo chmod a+x /etc/profile.d/user-motd.sh")
    puts "#{Colors::GREEN}Enabled MOTD.#{Colors::RESET}"
  when "special-motd"
    safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-special-motd /usr/libexec/hackeros-motd")
    safe_run("sudo cp /usr/share/HackerOS/Archived/user-motd.sh /etc/profile.d/")
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    safe_run("sudo chmod a+x /etc/profile.d/user-motd.sh")
    puts "#{Colors::GREEN}Enabled special MOTD.#{Colors::RESET}"
  else
    puts "#{Colors::RED}Unknown enable subcommand: #{subcommand}#{Colors::RESET}"
    show_enable_help
    exit(1)
  end
end
def show_enable_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Enable subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}motd #{Colors::RESET}- Enable standard MOTD"
  puts " #{Colors::GRAY}special-motd #{Colors::RESET}- Enable special MOTD"
end
def handle_disable(args : Array(String))
  if args.empty?
    show_disable_help
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "motd", "special-motd"
    safe_run("sudo rm -rf /usr/libexec/hackeros-motd")
    safe_run("sudo rm -f /etc/profile.d/user-motd.sh")
    puts "#{Colors::GREEN}Disabled MOTD.#{Colors::RESET}"
  else
    puts "#{Colors::RED}Unknown disable subcommand: #{subcommand}#{Colors::RESET}"
    show_disable_help
    exit(1)
  end
end
def show_disable_help
  puts "#{Colors::BOLD}#{Colors::MAGENTA}Disable subcommands:#{Colors::RESET}"
  puts " #{Colors::GRAY}motd #{Colors::RESET}- Disable MOTD"
  puts " #{Colors::GRAY}special-motd #{Colors::RESET}- Disable special MOTD"
end
main
