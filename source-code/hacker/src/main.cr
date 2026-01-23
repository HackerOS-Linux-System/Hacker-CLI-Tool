require "./helpers"
require "./unpack_commands"
require "./pack_commands"
require "./run_commands"
require "./game"

module Colors
  @@red : String = "\e[31m"
  @@yellow : String = "\e[33m"
  @@green : String = "\e[32m"
  @@magenta : String = "\e[35m"
  @@gray : String = "\e[90m"
  @@bold : String = "\e[1m"
  @@reset : String = "\e[0m"

  def self.red; @@red end
  def self.yellow; @@yellow end
  def self.green; @@green end
  def self.magenta; @@magenta end
  def self.gray; @@gray end
  def self.bold; @@bold end
  def self.reset; @@reset end

  def self.set_red(value : String); @@red = value end
  def self.set_yellow(value : String); @@yellow = value end
  def self.set_green(value : String); @@green = value end
  def self.set_magenta(value : String); @@magenta = value end
  def self.set_gray(value : String); @@gray = value end
  def self.set_bold(value : String); @@bold = value end
  def self.set_reset(value : String); @@reset = value end
end

def load_styles(file : String)
  content = File.read(file)
  if match = content.match(/:root\s*\{([^}]*)\}/)
    css = match[1]
    css.split(';').each do |decl|
      decl = decl.strip
      next if decl.empty?
      if decl =~ /--([\w-]+):\s*(#[0-9a-fA-F]{6})/
        var_name = $1.downcase
        hex = $2
        r = hex[1..2].to_i(16)
        g = hex[3..4].to_i(16)
        b = hex[5..6].to_i(16)
        ansi = "\e[38;2;#{r};#{g};#{b}m"
        case var_name
        when "red"
          Colors.set_red(ansi)
        when "yellow"
          Colors.set_yellow(ansi)
        when "green"
          Colors.set_green(ansi)
        when "magenta"
          Colors.set_magenta(ansi)
        when "gray"
          Colors.set_gray(ansi)
        end
      end
    end
  end
end

def main
  style_file = Path.home / ".config" / "hackeros" / "hacker" / "style.css"
  if File.exists?(style_file)
    load_styles(style_file.to_s)
  end

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
      puts "#{Colors.red}Usage: hacker install <package>#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("~/.hackeros/hacker/apt-fronted install #{package}")
  when "remove"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker remove <package>#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("~/.hackeros/hacker/apt-fronted remove #{package}")
  when "flatpak-install"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker flatpak-install <package>#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("flatpak install -y #{package}")
  when "flatpak-remove"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker flatpak-remove <package>#{Colors.reset}"
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
     puts "#{Colors.yellow}To use the hacker programming language for files/scripts with the .hacker extension, #{Colors.reset}"
     puts "#{Colors.yellow}use the \"hl\" command and \"bytes\" to download dependencies, to compile or run them.#{Colors.reset}"
  when "ascii"
    safe_run("cat /usr/share/HackerOS/Config-Files/HackerOS-Ascii")
  when "shell"
    safe_run("~/.hackeros/hacker/hacker-shell")
  when "enter"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker enter <container>#{Colors.reset}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox enter #{container}")
  when "remove-container"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker remove-container <container>#{Colors.reset}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox rm #{container}")
  when "restart"
    if ARGV.size < 2
      puts "#{Colors.red}Usage: hacker restart <service>#{Colors.reset}"
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
    puts "#{Colors.yellow}To create a custom command:#{Colors.reset}"
    puts "Create a file {command-name}.hacker in ~/.config/hackeros/hacker/custom-commands/"
    puts "An example file for a custom command can be found at: <https://github.com/HackerOS-Linux-System/Hacker-CLI-Tool/blob/main/hacker/config-files/custom-commands/example.hacker>"
  when "index"
    show_hackeros_tools
  when "--version"
    puts "#{Colors.green}Latest version of the hacker tool: 2.2#{Colors.reset}"
  when "--hackeros"
    puts "#{Colors.green}Latest version of HackerOS: 4.3#{Colors.reset}"
  when "--edition"
    file_path = "/etc/xdg/kcm-about-distrorc"
    if File.exists?(file_path)
      content = File.read(file_path)
      variant = nil
      content.each_line do |line|
        if line.starts_with?("Variant=")
          variant = line.split("=", 2)[1].strip
          break
        end
      end
      if variant
        puts "#{Colors.green}#{variant}#{Colors.reset}"
      else
        puts "#{Colors.red}Variant not found in file.#{Colors.reset}"
      end
    else
      puts "#{Colors.red}File not found: #{file_path}#{Colors.reset}"
    end
  when "info"
    puts "#{Colors.green}Latest version of the hacker tool: 2.1#{Colors.reset}"
    puts "#{Colors.green}Latest version of HackerOS: 4.1#{Colors.reset}"
  when "issue"
    browser = `which vivaldi`.strip.empty? ? "xdg-open" : "vivaldi"
    safe_run("#{browser} https://github.com/HackerOS-Linux-System/HackerOS-Website/issues/new")
  when "repair"
    safe_run("#{Path.home}/.hackeros/hacker/hacker-repair")
  else
    custom_file = CUSTOM_DIR / "#{command}.hacker"
    if File.exists?(custom_file)
      begin
        config = parse_hacker_file(custom_file.to_s)
        exec_cmd = config["exec"]?.as?(String)
        if exec_cmd
          safe_run("#{exec_cmd} #{ARGV[1..].join(" ")}")
        else
          puts "#{Colors.red}No 'exec' defined in custom command file.#{Colors.reset}"
          exit(1)
        end
      rescue ex
        puts "#{Colors.red}Error processing custom command: #{ex.message}#{Colors.reset}"
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
        puts "#{Colors.red}Unknown command: #{command}#{Colors.reset}"
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
      puts "#{Colors.red}Unknown flag for update: #{flag}#{Colors.reset}"
      puts "Available flags: --with-gui, --gui-mode, --better"
      exit(1)
    end
  end
end
def show_hackeros_tools
  puts "#{Colors.bold}#{Colors.magenta}HackerOS Tools Index:#{Colors.reset}"
  puts " * bytes - manager pakietów dla hacker lang"
  puts " * hl - uruchamiaj kompiluj programy napisane w .hl lub pliki konfiguracyjne .hk lub .hacker"
  puts " * hli - interaktywna wersja dla narzędzia hl"
  puts " * hacker - glównie narzędzie cli HackerOS"
  puts " * Hacker Kernel - jądro HackerOS jezeli chcesz rozwijac skontaktuj sie na: gmail - <hackeros068@gmail.com> lub <https://github.com/orgs/HackerOS-Linux-System/discussions>"
  puts " * HackerOS Steam - kontner dla steam"
  puts " * HackerOS Welcome - Aplikacja powitalna hackeros"
  puts " * HackerOS App - aplikacja dla androida (wersje HackerOS oraz możesz pobrać tapety)"
  puts " * HackerOS Store - sklep dla launcherów do gier, narzędzi do testów penetracyjnych oraz apliakcji"
  puts " * Security Mode - tryb do testow penetracyjnych"
  puts " * Hacker Mode - tryb gry"
  puts " * isolator - narzedzie cli do instalacji pakietów z specjalnego repo w kontnerach distrobox"
  puts " * hpm - specialne repozytorium pakietów dla HackerOS (kazdy pakiet jest s izolowanym środowiski)"
  puts " * HackerOS Game Mode - tryb gry inspirowany asus armoury crate"
  puts " * hup - system automatycznych aktualizacji"
  puts " * hammer - system z atomowym podejściem do systemu (snapshoty btrfs)"
  puts " * HackerOS Games - gui do uruchamiania gier: starblaster, bit-jump"
  puts " * HackerOS Cockpit (archiwum) - centrum sterowania systemem w przegladarce"
  puts " * Hacker Launcher - Uruchamiaj gry windows za pomoca tej aplikacji"
  puts " * virus - narzędzie cli inspirowane cargo dla języka programowania H# (dawniej nazywany HackerScript)"
  puts " * hcs - głowne narzędzie cli dla języka programowania H# (dawniej nazwyany HackerScript)"
  puts " * HackerOS Builder - specjalna nakładka dla live build"
  puts " * Blue Enviroment (BETA - niestabilne) - jezeli chcesz pomoc w rozwoju srodowiska graficznego HackerOS skontaktuj sie na gmail - <hackeros068@gmail.com> lub <https://github.com/orgs/HackerOS-Linux-System/discussions>"
end
def show_main_help
  puts "#{Colors.bold}#{Colors.magenta}HackerOS Tool - Available commands:#{Colors.reset}"
  puts " #{Colors.gray}unpack #{Colors.reset}- Unpack and install various components (use 'hacker unpack' for subcommands)"
  puts " #{Colors.gray}pack #{Colors.reset}- Pack and remove various components (use 'hacker pack' for subcommands)"
  puts " #{Colors.gray}help #{Colors.reset}- Show this help"
  puts " #{Colors.gray}help-ui #{Colors.reset}- Show help UI"
  puts " #{Colors.gray}docs #{Colors.reset}- Show documentation"
  puts " #{Colors.gray}install <pkg> #{Colors.reset}- Install package using apt-fronted"
  puts " #{Colors.gray}remove <pkg> #{Colors.reset}- Remove package using apt-fronted"
  puts " #{Colors.gray}flatpak-install <pkg> #{Colors.reset}- Install Flatpak package"
  puts " #{Colors.gray}flatpak-remove <pkg> #{Colors.reset}- Remove Flatpak package"
  puts " #{Colors.gray}system #{Colors.reset}- System-related commands (use 'hacker system' for subcommands)"
  puts " #{Colors.gray}run #{Colors.reset}- Run scripts and tools (use 'hacker run' for subcommands)"
  puts " #{Colors.gray}update [ --with-gui | --gui-mode | --better ] #{Colors.reset}- Run HackerOS updater (with optional flags)"
  puts " #{Colors.gray}game #{Colors.reset}- Play a text-based game"
  puts " #{Colors.gray}hacker-lang #{Colors.reset}- Info about hacker language"
  puts " #{Colors.gray}ascii #{Colors.reset}- Display ASCII art"
  puts " #{Colors.gray}shell #{Colors.reset}- Run hacker shell"
  puts " #{Colors.gray}enter <container> #{Colors.reset}- Enter Distrobox container"
  puts " #{Colors.gray}remove-container <container> #{Colors.reset}- Remove Distrobox container"
  puts " #{Colors.gray}restart <service> #{Colors.reset}- Restart system service"
  puts " #{Colors.gray}plugin #{Colors.reset}- Manage plugins (use 'hacker plugin' for subcommands)"
  puts " #{Colors.gray}enable #{Colors.reset}- Enable features (use 'hacker enable' for subcommands)"
  puts " #{Colors.gray}disable #{Colors.reset}- Disable features (use 'hacker disable' for subcommands)"
  puts " #{Colors.gray}how-to-create-commands #{Colors.reset}- Show how to create custom commands"
  puts " #{Colors.gray}index #{Colors.reset}- Show index of all HackerOS tools"
  puts " #{Colors.gray}info #{Colors.reset}- Show versions of tool and HackerOS"
  puts " #{Colors.gray}issue #{Colors.reset}- Open new issue on GitHub in browser (prefers Vivaldi)"
  puts " #{Colors.gray}repair #{Colors.reset}- Run hacker repair tool"
  puts "#{Colors.bold}#{Colors.magenta}Custom commands:#{Colors.reset}"
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
      puts " #{Colors.gray}#{name} #{Colors.reset}- #{desc}"
    rescue
      puts " #{Colors.gray}#{name} #{Colors.reset}- Invalid config"
    end
  end
  puts "#{Colors.bold}#{Colors.magenta}Plugin commands:#{Colors.reset}"
  Dir.glob((PLUGIN_DIR / "*.hacker").to_s).sort.each do |f|
    begin
      config = parse_hacker_file(f)
      next unless config["enabled"]? == "true"
      commands = config["commands"]?.as?(Config)
      next unless commands
      commands.each do |cmd_name, cmd_config|
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
        puts " #{Colors.gray}#{cmd_name} #{Colors.reset}- #{desc}"
      end
    rescue
      # Skip
    end
  end
end
def handle_system(args : Array(String))
  if args.empty?
    puts "#{Colors.bold}#{Colors.magenta}System subcommands:#{Colors.reset}"
    puts " #{Colors.gray}logs #{Colors.reset}- Display system logs"
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "logs"
    safe_run("journalctl -xe")
  else
    puts "#{Colors.red}Unknown system subcommand: #{subcommand}#{Colors.reset}"
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
    puts "#{Colors.bold}#{Colors.magenta}Plugins:#{Colors.reset}"
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
        puts " #{name} - #{enabled ? "#{Colors.green}enabled#{Colors.reset}" : "#{Colors.red}disabled#{Colors.reset}"}"
      rescue
        puts " #{File.basename(f, ".hacker")} - #{Colors.red}invalid#{Colors.reset}"
      end
    end
  when "enable"
    if args.size < 2
      puts "#{Colors.red}Usage: hacker plugin enable <plugin-name>#{Colors.reset}"
      exit(1)
    end
    name = args[1]
    file = PLUGIN_DIR / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "true"
        write_hacker_file(file.to_s, config)
        puts "#{Colors.green}Enabled plugin '#{name}'.#{Colors.reset}"
      rescue ex
        puts "#{Colors.red}Error enabling plugin: #{ex.message}#{Colors.reset}"
      end
    else
      puts "#{Colors.red}Plugin '#{name}' not found.#{Colors.reset}"
    end
  when "disable"
    if args.size < 2
      puts "#{Colors.red}Usage: hacker plugin disable <plugin-name>#{Colors.reset}"
      exit(1)
    end
    name = args[1]
    file = PLUGIN_DIR / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "false"
        write_hacker_file(file.to_s, config)
        puts "#{Colors.green}Disabled plugin '#{name}'.#{Colors.reset}"
      rescue ex
        puts "#{Colors.red}Error disabling plugin: #{ex.message}#{Colors.reset}"
      end
    else
      puts "#{Colors.red}Plugin '#{name}' not found.#{Colors.reset}"
    end
  else
    puts "#{Colors.red}Unknown plugin subcommand: #{subcommand}#{Colors.reset}"
    show_plugin_help
    exit(1)
  end
end
def show_plugin_help
  puts "#{Colors.bold}#{Colors.magenta}Plugin subcommands:#{Colors.reset}"
  puts " #{Colors.gray}list #{Colors.reset}- List all plugins and their status"
  puts " #{Colors.gray}enable <name> #{Colors.reset}- Enable a plugin"
  puts " #{Colors.gray}disable <name> #{Colors.reset}- Disable a plugin"
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
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    puts "#{Colors.green}Enabled MOTD.#{Colors.reset}"
  when "special-motd"
    safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-special-motd /usr/libexec/hackeros-motd")
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    puts "#{Colors.green}Enabled special MOTD.#{Colors.reset}"
  else
    puts "#{Colors.red}Unknown enable subcommand: #{subcommand}#{Colors.reset}"
    show_enable_help
    exit(1)
  end
end
def show_enable_help
  puts "#{Colors.bold}#{Colors.magenta}Enable subcommands:#{Colors.reset}"
  puts " #{Colors.gray}motd #{Colors.reset}- Enable standard MOTD"
  puts " #{Colors.gray}special-motd #{Colors.reset}- Enable special MOTD"
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
    puts "#{Colors.green}Disabled MOTD.#{Colors.reset}"
  else
    puts "#{Colors.red}Unknown disable subcommand: #{subcommand}#{Colors.reset}"
    show_disable_help
    exit(1)
  end
end
def show_disable_help
  puts "#{Colors.bold}#{Colors.magenta}Disable subcommands:#{Colors.reset}"
  puts " #{Colors.gray}motd #{Colors.reset}- Disable MOTD"
  puts " #{Colors.gray}special-motd #{Colors.reset}- Disable special MOTD"
end
main
