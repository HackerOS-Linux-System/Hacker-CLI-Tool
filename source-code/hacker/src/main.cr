require "./helpers"
require "./unpack_commands"
require "./pack_commands"
require "./run_commands"
require "./game"
require "json"
require "path"

module HackerPaths
  def self.custom_dir
    Path.home / ".config" / "hackeros" / "hacker" / "custom-commands"
  end

  def self.plugin_dir
    Path.home / ".config" / "hackeros" / "hacker" / "plugins"
  end
end

module Colors
  @@red = "\e[31m"
  @@yellow = "\e[33m"
  @@green = "\e[32m"
  @@magenta = "\e[35m"
  @@gray = "\e[90m"
  @@bold = "\e[1m"
  @@reset = "\e[0m"
  @@blue = "\e[34m"
  @@cyan = "\e[36m"
  @@white = "\e[37m"
  def self.red; @@red; end
  def self.red=(value : String); @@red = value; end
  def self.yellow; @@yellow; end
  def self.yellow=(value : String); @@yellow = value; end
  def self.green; @@green; end
  def self.green=(value : String); @@green = value; end
  def self.magenta; @@magenta; end
  def self.magenta=(value : String); @@magenta = value; end
  def self.gray; @@gray; end
  def self.gray=(value : String); @@gray = value; end
  def self.bold; @@bold; end
  def self.bold=(value : String); @@bold = value; end
  def self.reset; @@reset; end
  def self.reset=(value : String); @@reset = value; end
  def self.blue; @@blue; end
  def self.blue=(value : String); @@blue = value; end
  def self.cyan; @@cyan; end
  def self.cyan=(value : String); @@cyan = value; end
  def self.white; @@white; end
  def self.white=(value : String); @@white = value; end
end

def load_styles(file : String)
  if File.exists?(file)
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
          when "red" then Colors.red = ansi
          when "yellow" then Colors.yellow = ansi
          when "green" then Colors.green = ansi
          when "magenta" then Colors.magenta = ansi
          when "gray" then Colors.gray = ansi
          end
        end
      end
    end
  end
end

def load_lang : String
  config_dir = Path.home / ".config" / "hackeros" / "hacker"
  language_file = config_dir / "language.json"
  if File.exists?(language_file)
    begin
      json = JSON.parse(File.read(language_file))
      json["language"]?.try(&.as_s?) || "pl"
    rescue
      "pl"
    end
  else
    "pl"
  end
end

def save_language(file : String, lang : String)
  data = {"language" => lang}
  File.write(file, data.to_json)
end

def load_language(file : String) : String?
  if File.exists?(file)
    content = File.read(file)
    json = JSON.parse(content)
    json["language"]?.try(&.as_s?)
  else
    nil
  end
end

def main
  lang = load_lang
  translations = get_translations_main
  # Fallback to 'pl' if loaded language is not in our dictionary
  if !translations.has_key?(lang)
    lang = "pl"
  end

  trans = translations[lang]
  style_file = Path.home / ".config" / "hackeros" / "hacker" / "style.css"
  load_styles(style_file.to_s)

  if ARGV.empty? || ARGV[0] == "help"
    show_main_help(lang)
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
      puts "#{Colors.red}#{trans["usage_install"]}#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("~/.hackeros/hacker/apt-fronted install #{package}")
  when "remove"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_remove"]}#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("~/.hackeros/hacker/apt-fronted remove #{package}")
  when "flatpak-install"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_flatpak_install"]}#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("flatpak install -y #{package}")
  when "flatpak-remove"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_flatpak_remove"]}#{Colors.reset}"
      exit(1)
    end
    package = ARGV[1..].join(" ")
    safe_run("flatpak remove -y #{package}")
  when "system"
    handle_system(ARGV[1..], lang)
  when "run"
    handle_run(ARGV[1..])
  when "update"
    handle_update(ARGV[1..], lang)
  when "game"
    play_text_game
  when "hacker-lang"
    puts "#{Colors.yellow}#{trans["hacker_lang_info1"]}#{Colors.reset}"
    puts "#{Colors.yellow}#{trans["hacker_lang_info2"]}#{Colors.reset}"
  when "ascii"
    safe_run("cat /usr/share/HackerOS/Config-Files/HackerOS-Ascii")
  when "shell"
    safe_run("source /usr/lib/HackerOS/venv/bin/activate && ~/.hackeros/hacker/hacker-shell")
  when "enter"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_enter"]}#{Colors.reset}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox enter #{container}")
  when "remove-container"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_remove_container"]}#{Colors.reset}"
      exit(1)
    end
    container = ARGV[1]
    safe_run("distrobox rm #{container}")
  when "restart"
    if ARGV.size < 2
      puts "#{Colors.red}#{trans["usage_restart"]}#{Colors.reset}"
      exit(1)
    end
    service = ARGV[1]
    safe_run("sudo systemctl restart #{service}")
  when "plugin"
    handle_plugin(ARGV[1..], lang)
  when "enable"
    handle_enable(ARGV[1..], lang)
  when "disable"
    handle_disable(ARGV[1..], lang)
  when "how-to-create-commands"
    puts "#{Colors.yellow}#{trans["how_to_create1"]}#{Colors.reset}"
    puts trans["how_to_create2"]
    puts trans["how_to_create3"]
  when "index"
    show_hackeros_tools(lang)
  when "--version"
    puts "#{Colors.green}#{trans["version_tool"]}#{Colors.reset}"
  when "--hackeros"
    puts "#{Colors.green}#{trans["version_os"]}#{Colors.reset}"
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
        puts "#{Colors.red}#{trans["variant_not_found"]}#{Colors.reset}"
      end
    else
      puts "#{Colors.red}#{trans["file_not_found"]} #{file_path}#{Colors.reset}"
    end
  when "info"
    puts "#{Colors.green}#{trans["version_tool"]}#{Colors.reset}"
    puts "#{Colors.green}#{trans["version_os"]}#{Colors.reset}"
  when "issue"
    browser = `which vivaldi`.strip.empty? ? "xdg-open" : "vivaldi"
    safe_run("#{browser} https://github.com/HackerOS-Linux-System/HackerOS-Website/issues/new")
  when "repair"
    safe_run("#{Path.home}/.hackeros/hacker/hacker-repair")
  when "settings"
    handle_settings(ARGV[1..], lang)
  else
    custom_file = HackerPaths.custom_dir / "#{command}.hacker"
    if File.exists?(custom_file)
      begin
        config = parse_hacker_file(custom_file.to_s)
        exec_cmd = config["exec"]?.as?(String)
        if exec_cmd
          safe_run("#{exec_cmd} #{ARGV[1..].join(" ")}")
        else
          puts "#{Colors.red}#{trans["no_exec_custom"]}#{Colors.reset}"
          exit(1)
        end
      rescue ex
        puts "#{Colors.red}#{trans["error_custom"]} #{ex.message}#{Colors.reset}"
        exit(1)
      end
    else
      found = false
      Dir.glob((HackerPaths.plugin_dir / "*.hacker").to_s).each do |f_path|
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
        puts "#{Colors.red}#{trans["unknown_command"]} #{command}#{Colors.reset}"
        show_main_help(lang)
        exit(1)
      end
    end
  end
end

def get_translations_main : Hash(String, Hash(String, String))
  {
    "pl" => {
      "tool_title" => "HackerOS Tool - Dostępne komendy:",
      "desc_unpack" => "Rozpakuj i zainstaluj różne komponenty (użyj 'hacker unpack' dla podkomend)",
      "desc_pack" => "Spakuj i usuń różne komponenty (użyj 'hacker pack' dla podkomend)",
      "desc_help" => "Pokaż tę pomoc",
      "desc_help_ui" => "Pokaż UI pomocy",
      "desc_docs" => "Pokaż dokumentację",
      "desc_install" => "Zainstaluj pakiet używając apt-fronted",
      "desc_remove" => "Usuń pakiet używając apt-fronted",
      "desc_flatpak_install" => "Zainstaluj pakiet Flatpak",
      "desc_flatpak_remove" => "Usuń pakiet Flatpak",
      "desc_system" => "Komendy systemowe (użyj 'hacker system' dla podkomend)",
      "desc_run" => "Uruchom skrypty i narzędzia (użyj 'hacker run' dla podkomend)",
      "desc_update" => "Uruchom aktualizator HackerOS (z opcjonalnymi flagami)",
      "desc_game" => "Zagraj w grę tekstową",
      "desc_hacker_lang" => "Info o języku hacker",
      "desc_ascii" => "Wyświetl ASCII art",
      "desc_shell" => "Uruchom hacker shell",
      "desc_enter" => "Wejdź do kontenera Distrobox",
      "desc_remove_container" => "Usuń kontener Distrobox",
      "desc_restart" => "Zrestartuj usługę systemową",
      "desc_plugin" => "Zarządzaj pluginami (użyj 'hacker plugin' dla podkomend)",
      "desc_enable" => "Włącz funkcje (użyj 'hacker enable' dla podkomend)",
      "desc_disable" => "Wyłącz funkcje (użyj 'hacker disable' dla podkomend)",
      "desc_how_to" => "Pokaż jak tworzyć własne komendy",
      "desc_index" => "Pokaż indeks wszystkich narzędzi HackerOS",
      "desc_info" => "Pokaż wersje narzędzia i HackerOS",
      "desc_issue" => "Otwórz nowe zgłoszenie na GitHub w przeglądarce (preferuje Vivaldi)",
      "desc_repair" => "Uruchom narzędzie naprawcze hacker",
      "desc_settings" => "Zarządzaj ustawieniami (użyj 'hacker settings' dla podkomend)",
      "usage_install" => "Użycie: hacker install <pakiet>",
      "usage_remove" => "Użycie: hacker remove <pakiet>",
      "usage_flatpak_install" => "Użycie: hacker flatpak-install <pakiet>",
      "usage_flatpak_remove" => "Użycie: hacker flatpak-remove <pakiet>",
      "hacker_lang_info1" => "Aby używać języka programowania hacker dla plików/skryptów z rozszerzeniem .hacker,",
      "hacker_lang_info2" => "użyj komendy \"hl\" i \"bytes\" do pobierania zależności, do kompilowania lub uruchamiania ich.",
      "usage_enter" => "Użycie: hacker enter <kontener>",
      "usage_remove_container" => "Użycie: hacker remove-container <kontener>",
      "usage_restart" => "Użycie: hacker restart <usługa>",
      "how_to_create1" => "Aby stworzyć własną komendę:",
      "how_to_create2" => "Utwórz plik {nazwa-komendy}.hacker w ~/.config/hackeros/hacker/custom-commands/",
      "how_to_create3" => "Przykładowy plik dla własnej komendy można znaleźć na: <https://github.com/HackerOS-Linux-System/Hacker-CLI-Tool/blob/main/hacker/config-files/custom-commands/example.hacker>",
      "version_tool" => "Najnowsza wersja narzędzia hacker: 2.3",
      "version_os" => "Najnowsza wersja HackerOS: 4.4",
      "variant_not_found" => "Wariant nie znaleziony w pliku.",
      "file_not_found" => "Plik nie znaleziony:",
      "no_exec_custom" => "Brak 'exec' zdefiniowanego w pliku własnej komendy.",
      "error_custom" => "Błąd przetwarzania własnej komendy:",
      "unknown_command" => "Nieznana komenda:",
      "no_description" => "Brak opisu",
      "invalid_config" => "Nieprawidłowa konfiguracja",
      "plugins_title" => "Komendy pluginów:",
      "custom_commands" => "Własne komendy:",
      "system_subcommands" => "Subkomendy system:",
      "logs_desc" => "Wyświetl logi systemowe",
      "unknown_system" => "Nieznana subkomenda system:",
      "unknown_update_flag" => "Nieznana flaga dla update:",
      "available_flags" => "Dostępne flagi: --with-gui, --gui-mode, --better",
      "tools_index" => "Indeks narzędzi HackerOS:",
      "plugin_subcommands" => "Subkomendy plugin:",
      "list_desc" => "Lista wszystkich pluginów i ich statusu",
      "enable_desc" => "Włącz plugin",
      "disable_desc" => "Wyłącz plugin",
      "plugins" => "Pluginy:",
      "enabled" => "włączony",
      "disabled" => "wyłączony",
      "invalid" => "nieprawidłowy",
      "usage_plugin_enable" => "Użycie: hacker plugin enable <nazwa-pluginu>",
      "enabled_plugin" => "Włączono plugin",
      "error_enabling" => "Błąd włączania pluginu:",
      "plugin_not_found" => "Plugin nie znaleziono.",
      "usage_plugin_disable" => "Użycie: hacker plugin disable <nazwa-pluginu>",
      "disabled_plugin" => "Wyłączono plugin",
      "error_disabling" => "Błąd wyłączania pluginu:",
      "unknown_plugin" => "Nieznana subkomenda plugin:",
      "enable_subcommands" => "Subkomendy enable:",
      "motd_desc" => "Włącz standardowy MOTD",
      "special_motd_desc" => "Włącz specjalny MOTD",
      "enabled_motd" => "Włączono MOTD.",
      "enabled_special_motd" => "Włączono specjalny MOTD.",
      "unknown_enable" => "Nieznana subkomenda enable:",
      "disable_subcommands" => "Subkomendy disable:",
      "disabled_motd" => "Wyłączono MOTD.",
      "unknown_disable" => "Nieznana subkomenda disable:",
      "settings_subcommands" => "Subkomendy settings:",
      "language_desc" => "Pobierz lub ustaw język (wspierane: pl, en, de, fr, es, it, ru, zh, ja, ko, pt, ar, hi)",
      "current_language" => "Aktualny język:",
      "language_set" => "Język ustawiony na",
      "unsupported_language" => "Nieobsługiwany język:",
      "supported" => "Wspierane:",
      "unknown_settings" => "Nieznana subkomenda settings:",
    },
    "en" => {
      "tool_title" => "HackerOS Tool - Available commands:",
      "desc_unpack" => "Unpack and install various components (use 'hacker unpack' for subcommands)",
      "desc_pack" => "Pack and remove various components (use 'hacker pack' for subcommands)",
      "desc_help" => "Show this help",
      "desc_help_ui" => "Show help UI",
      "desc_docs" => "Show documentation",
      "desc_install" => "Install package using apt-fronted",
      "desc_remove" => "Remove package using apt-fronted",
      "desc_flatpak_install" => "Install Flatpak package",
      "desc_flatpak_remove" => "Remove Flatpak package",
      "desc_system" => "System-related commands (use 'hacker system' for subcommands)",
      "desc_run" => "Run scripts and tools (use 'hacker run' for subcommands)",
      "desc_update" => "Run HackerOS updater (with optional flags)",
      "desc_game" => "Play a text-based game",
      "desc_hacker_lang" => "Info about hacker language",
      "desc_ascii" => "Display ASCII art",
      "desc_shell" => "Run hacker shell",
      "desc_enter" => "Enter Distrobox container",
      "desc_remove_container" => "Remove Distrobox container",
      "desc_restart" => "Restart system service",
      "desc_plugin" => "Manage plugins (use 'hacker plugin' for subcommands)",
      "desc_enable" => "Enable features (use 'hacker enable' for subcommands)",
      "desc_disable" => "Disable features (use 'hacker disable' for subcommands)",
      "desc_how_to" => "Show how to create custom commands",
      "desc_index" => "Show index of all HackerOS tools",
      "desc_info" => "Show versions of tool and HackerOS",
      "desc_issue" => "Open new issue on GitHub in browser (prefers Vivaldi)",
      "desc_repair" => "Run hacker repair tool",
      "desc_settings" => "Manage settings (use 'hacker settings' for subcommands)",
      "usage_install" => "Usage: hacker install <package>",
      "usage_remove" => "Usage: hacker remove <package>",
      "usage_flatpak_install" => "Usage: hacker flatpak-install <package>",
      "usage_flatpak_remove" => "Usage: hacker flatpak-remove <package>",
      "hacker_lang_info1" => "To use the hacker programming language for files/scripts with the .hacker extension,",
      "hacker_lang_info2" => "use the \"hl\" command and \"bytes\" to download dependencies, to compile or run them.",
      "usage_enter" => "Usage: hacker enter <container>",
      "usage_remove_container" => "Usage: hacker remove-container <container>",
      "usage_restart" => "Usage: hacker restart <service>",
      "how_to_create1" => "To create a custom command:",
      "how_to_create2" => "Create a file {command-name}.hacker in ~/.config/hackeros/hacker/custom-commands/",
      "how_to_create3" => "An example file for a custom command can be found at: <https://github.com/HackerOS-Linux-System/Hacker-CLI-Tool/blob/main/hacker/config-files/custom-commands/example.hacker>",
      "version_tool" => "Latest version of the hacker tool: 2.3",
      "version_os" => "Latest version of HackerOS: 4.4",
      "variant_not_found" => "Variant not found in file.",
      "file_not_found" => "File not found:",
      "no_exec_custom" => "No 'exec' defined in custom command file.",
      "error_custom" => "Error processing custom command:",
      "unknown_command" => "Unknown command:",
      "no_description" => "No description",
      "invalid_config" => "Invalid config",
      "plugins_title" => "Plugin commands:",
      "custom_commands" => "Custom commands:",
      "system_subcommands" => "System subcommands:",
      "logs_desc" => "Display system logs",
      "unknown_system" => "Unknown system subcommand:",
      "unknown_update_flag" => "Unknown flag for update:",
      "available_flags" => "Available flags: --with-gui, --gui-mode, --better",
      "tools_index" => "HackerOS Tools Index:",
      "plugin_subcommands" => "Plugin subcommands:",
      "list_desc" => "List all plugins and their status",
      "enable_desc" => "Enable a plugin",
      "disable_desc" => "Disable a plugin",
      "plugins" => "Plugins:",
      "enabled" => "enabled",
      "disabled" => "disabled",
      "invalid" => "invalid",
      "usage_plugin_enable" => "Usage: hacker plugin enable <plugin-name>",
      "enabled_plugin" => "Enabled plugin",
      "error_enabling" => "Error enabling plugin:",
      "plugin_not_found" => "Plugin not found.",
      "usage_plugin_disable" => "Usage: hacker plugin disable <plugin-name>",
      "disabled_plugin" => "Disabled plugin",
      "error_disabling" => "Error disabling plugin:",
      "unknown_plugin" => "Unknown plugin subcommand:",
      "enable_subcommands" => "Enable subcommands:",
      "motd_desc" => "Enable standard MOTD",
      "special_motd_desc" => "Enable special MOTD",
      "enabled_motd" => "Enabled MOTD.",
      "enabled_special_motd" => "Enabled special MOTD.",
      "unknown_enable" => "Unknown enable subcommand:",
      "disable_subcommands" => "Disable subcommands:",
      "disabled_motd" => "Disabled MOTD.",
      "unknown_disable" => "Unknown disable subcommand:",
      "settings_subcommands" => "Settings subcommands:",
      "language_desc" => "Get or set the language (supported: pl, en, de, fr, es, it, ru, zh, ja, ko, pt, ar, hi)",
      "current_language" => "Current language:",
      "language_set" => "Language set to",
      "unsupported_language" => "Unsupported language:",
      "supported" => "Supported:",
      "unknown_settings" => "Unknown settings subcommand:",
    },
    "de" => {
      "tool_title" => "HackerOS Tool - Verfügbare Befehle:",
      "desc_unpack" => "Entpacken und installieren verschiedener Komponenten (nutze 'hacker unpack' für Unterbefehle)",
      "desc_pack" => "Packen und entfernen verschiedener Komponenten (nutze 'hacker pack' für Unterbefehle)",
      "desc_help" => "Zeige diese Hilfe",
      "desc_help_ui" => "Zeige Hilfe-UI",
      "desc_docs" => "Zeige Dokumentation",
      "desc_install" => "Installiere Paket mit apt-fronted",
      "desc_remove" => "Entferne Paket mit apt-fronted",
      "desc_flatpak_install" => "Installiere Flatpak-Paket",
      "desc_flatpak_remove" => "Entferne Flatpak-Paket",
      "desc_system" => "Systembezogene Befehle (nutze 'hacker system' für Unterbefehle)",
      "desc_run" => "Führe Skripte und Tools aus (nutze 'hacker run' für Unterbefehle)",
      "desc_update" => "Starte HackerOS Updater (mit optionalen Flags)",
      "desc_game" => "Spiele ein textbasiertes Spiel",
      "desc_hacker_lang" => "Info über Hacker-Sprache",
      "desc_ascii" => "Zeige ASCII Art",
      "desc_shell" => "Starte Hacker Shell",
      "desc_enter" => "Betrete Distrobox Container",
      "desc_remove_container" => "Entferne Distrobox Container",
      "desc_restart" => "Starte Systemdienst neu",
      "desc_plugin" => "Verwalte Plugins (nutze 'hacker plugin' für Unterbefehle)",
      "desc_enable" => "Aktiviere Funktionen (nutze 'hacker enable' für Unterbefehle)",
      "desc_disable" => "Deaktiviere Funktionen (nutze 'hacker disable' für Unterbefehle)",
      "desc_how_to" => "Zeige, wie man eigene Befehle erstellt",
      "desc_index" => "Zeige Index aller HackerOS Tools",
      "desc_info" => "Zeige Versionen von Tool und HackerOS",
      "desc_issue" => "Öffne neues Issue auf GitHub im Browser (bevorzugt Vivaldi)",
      "desc_repair" => "Starte Hacker Repair Tool",
      "desc_settings" => "Verwalte Einstellungen (nutze 'hacker settings' für Unterbefehle)",
      "usage_install" => "Verwendung: hacker install <paket>",
      "usage_remove" => "Verwendung: hacker remove <paket>",
      "usage_flatpak_install" => "Verwendung: hacker flatpak-install <paket>",
      "usage_flatpak_remove" => "Verwendung: hacker flatpak-remove <paket>",
      "hacker_lang_info1" => "Um die Hacker-Programmiersprache für Dateien/Skripte mit der .hacker-Erweiterung zu verwenden,",
      "hacker_lang_info2" => "verwenden Sie den \"hl\"-Befehl und \"bytes\", um Abhängigkeiten herunterzuladen, zu kompilieren oder auszuführen.",
      "usage_enter" => "Verwendung: hacker enter <container>",
      "usage_remove_container" => "Verwendung: hacker remove-container <container>",
      "usage_restart" => "Verwendung: hacker restart <service>",
      "how_to_create1" => "Um einen benutzerdefinierten Befehl zu erstellen:",
      "how_to_create2" => "Erstellen Sie eine Datei {command-name}.hacker in ~/.config/hackeros/hacker/custom-commands/",
      "how_to_create3" => "Eine Beispieldatei für einen benutzerdefinierten Befehl finden Sie unter: <https://github.com/HackerOS-Linux-System/Hacker-CLI-Tool/blob/main/hacker/config-files/custom-commands/example.hacker>",
      "version_tool" => "Neueste Version des Hacker-Tools: 2.3",
      "version_os" => "Neueste Version von HackerOS: 4.4",
      "variant_not_found" => "Variante nicht in der Datei gefunden.",
      "file_not_found" => "Datei nicht gefunden:",
      "no_exec_custom" => "Kein 'exec' in der benutzerdefinierten Befehlsdatei definiert.",
      "error_custom" => "Fehler bei der Verarbeitung des benutzerdefinierten Befehls:",
      "unknown_command" => "Unbekannter Befehl:",
      "no_description" => "Keine Beschreibung",
      "invalid_config" => "Ungültige Konfig",
      "plugins_title" => "Plugin-Befehle:",
      "custom_commands" => "Benutzerdefinierte Befehle:",
      "system_subcommands" => "System-Unterbefehle:",
      "logs_desc" => "Systemprotokolle anzeigen",
      "unknown_system" => "Unbekannter System-Unterbefehl:",
      "unknown_update_flag" => "Unbekannte Flagge für Update:",
      "available_flags" => "Verfügbare Flaggen: --with-gui, --gui-mode, --better",
      "tools_index" => "HackerOS Tools Index:",
      "plugin_subcommands" => "Plugin-Unterbefehle:",
      "list_desc" => "Alle Plugins und ihren Status auflisten",
      "enable_desc" => "Ein Plugin aktivieren",
      "disable_desc" => "Ein Plugin deaktivieren",
      "plugins" => "Plugins:",
      "enabled" => "aktiviert",
      "disabled" => "deaktiviert",
      "invalid" => "ungültig",
      "usage_plugin_enable" => "Verwendung: hacker plugin enable <plugin-name>",
      "enabled_plugin" => "Plugin aktiviert",
      "error_enabling" => "Fehler beim Aktivieren des Plugins:",
      "plugin_not_found" => "Plugin nicht gefunden.",
      "usage_plugin_disable" => "Verwendung: hacker plugin disable <plugin-name>",
      "disabled_plugin" => "Plugin deaktiviert",
      "error_disabling" => "Fehler beim Deaktivieren des Plugins:",
      "unknown_plugin" => "Unbekannter Plugin-Unterbefehl:",
      "enable_subcommands" => "Enable-Unterbefehle:",
      "motd_desc" => "Standard-MOTD aktivieren",
      "special_motd_desc" => "Spezial-MOTD aktivieren",
      "enabled_motd" => "MOTD aktiviert.",
      "enabled_special_motd" => "Spezial-MOTD aktiviert.",
      "unknown_enable" => "Unbekannter Enable-Unterbefehl:",
      "disable_subcommands" => "Disable-Unterbefehle:",
      "disabled_motd" => "MOTD deaktiviert.",
      "unknown_disable" => "Unbekannter Disable-Unterbefehl:",
      "settings_subcommands" => "Settings-Unterbefehle:",
      "language_desc" => "Sprache abrufen oder setzen (unterstützt: pl, en, de, fr, es, it, ru, zh, ja, ko, pt, ar, hi)",
      "current_language" => "Aktuelle Sprache:",
      "language_set" => "Sprache auf",
      "unsupported_language" => "Nicht unterstützte Sprache:",
      "supported" => "Unterstützt:",
      "unknown_settings" => "Unbekannter Settings-Unterbefehl:",
    },
  }
end

def show_main_help(lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["tool_title"]}#{Colors.reset}"
  puts " #{Colors.gray}unpack #{Colors.reset}- #{trans["desc_unpack"]}"
  puts " #{Colors.gray}pack #{Colors.reset}- #{trans["desc_pack"]}"
  puts " #{Colors.gray}help #{Colors.reset}- #{trans["desc_help"]}"
  puts " #{Colors.gray}help-ui #{Colors.reset}- #{trans["desc_help_ui"]}"
  puts " #{Colors.gray}docs #{Colors.reset}- #{trans["desc_docs"]}"
  puts " #{Colors.gray}install <pkg> #{Colors.reset}- #{trans["desc_install"]}"
  puts " #{Colors.gray}remove <pkg> #{Colors.reset}- #{trans["desc_remove"]}"
  puts " #{Colors.gray}flatpak-install <pkg> #{Colors.reset}- #{trans["desc_flatpak_install"]}"
  puts " #{Colors.gray}flatpak-remove <pkg> #{Colors.reset}- #{trans["desc_flatpak_remove"]}"
  puts " #{Colors.gray}system #{Colors.reset}- #{trans["desc_system"]}"
  puts " #{Colors.gray}run #{Colors.reset}- #{trans["desc_run"]}"
  puts " #{Colors.gray}update [ --with-gui | --gui-mode | --better ] #{Colors.reset}- #{trans["desc_update"]}"
  puts " #{Colors.gray}game #{Colors.reset}- #{trans["desc_game"]}"
  puts " #{Colors.gray}hacker-lang #{Colors.reset}- #{trans["desc_hacker_lang"]}"
  puts " #{Colors.gray}ascii #{Colors.reset}- #{trans["desc_ascii"]}"
  puts " #{Colors.gray}shell #{Colors.reset}- #{trans["desc_shell"]}"
  puts " #{Colors.gray}enter <container> #{Colors.reset}- #{trans["desc_enter"]}"
  puts " #{Colors.gray}remove-container <container> #{Colors.reset}- #{trans["desc_remove_container"]}"
  puts " #{Colors.gray}restart <service> #{Colors.reset}- #{trans["desc_restart"]}"
  puts " #{Colors.gray}plugin #{Colors.reset}- #{trans["desc_plugin"]}"
  puts " #{Colors.gray}enable #{Colors.reset}- #{trans["desc_enable"]}"
  puts " #{Colors.gray}disable #{Colors.reset}- #{trans["desc_disable"]}"
  puts " #{Colors.gray}how-to-create-commands #{Colors.reset}- #{trans["desc_how_to"]}"
  puts " #{Colors.gray}index #{Colors.reset}- #{trans["desc_index"]}"
  puts " #{Colors.gray}info #{Colors.reset}- #{trans["desc_info"]}"
  puts " #{Colors.gray}issue #{Colors.reset}- #{trans["desc_issue"]}"
  puts " #{Colors.gray}repair #{Colors.reset}- #{trans["desc_repair"]}"
  puts " #{Colors.gray}settings #{Colors.reset}- #{trans["desc_settings"]}"

  # Custom commands section
  puts "#{Colors.bold}#{Colors.magenta}#{trans["custom_commands"]}#{Colors.reset}"
  Dir.glob((HackerPaths.custom_dir / "*.hacker").to_s).sort.each do |f|
    name = File.basename(f, ".hacker")
    begin
      config = parse_hacker_file(f)
      desc = config["description"]?.as?(String) || trans["no_description"]
      puts " #{Colors.gray}#{name} #{Colors.reset}- #{desc}"
    rescue
      puts " #{Colors.gray}#{name} #{Colors.reset}- #{trans["invalid_config"]}"
    end
  end

  # Plugin commands section
  puts "#{Colors.bold}#{Colors.magenta}#{trans["plugins_title"]}#{Colors.reset}"
  Dir.glob((HackerPaths.plugin_dir / "*.hacker").to_s).sort.each do |f|
    begin
      config = parse_hacker_file(f)
      next unless config["enabled"]? == "true"
      commands = config["commands"]?.as?(Config)
      next unless commands
      commands.each do |cmd_name, cmd_config|
        next unless cmd_config.is_a?(Config)
        desc = cmd_config["description"]?.as?(String) || trans["no_description"]
        puts " #{Colors.gray}#{cmd_name} #{Colors.reset}- #{desc}"
      end
    rescue
      # Skip
    end
  end
end

def handle_system(args : Array(String), lang : String)
  trans = get_translations_main[lang]
  if args.empty?
    puts "#{Colors.bold}#{Colors.magenta}#{trans["system_subcommands"]}#{Colors.reset}"
    puts " #{Colors.gray}logs #{Colors.reset}- #{trans["logs_desc"]}"
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "logs"
    safe_run("journalctl -xe")
  else
    puts "#{Colors.red}#{trans["unknown_system"]} #{subcommand}#{Colors.reset}"
    exit(1)
  end
end

def handle_update(args : Array(String), lang : String)
  trans = get_translations_main[lang]
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
      puts "#{Colors.red}#{trans["unknown_update_flag"]} #{flag}#{Colors.reset}"
      puts trans["available_flags"]
      exit(1)
    end
  end
end

def show_hackeros_tools(lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["tools_index"]}#{Colors.reset}"
  puts " * bytes - manager pakietów dla hacker lang"
  puts " * hl - uruchamiaj kompiluj programy napisane w .hl lub pliki konfiguracyjne .hk lub .hacker"
  puts " * hli - interaktywna wersja dla narzędzia hl"
  puts " * hacker - glównie narzędzie cli HackerOS"
  puts " * Hacker Kernel - jądro HackerOS jezeli chcesz rozwijac skontaktuj sie na: gmail - <hackeros068@gmail.com> lub <https://github.com/orgs/HackerOS-Linux-System/discussions>"
  puts " * HackerOS Steam - kontner dla steam"
  puts " * HackerOS Welcome - Aplikacja powitalna HackerOS"
  puts " * HackerOS App - aplikacja dla androida (wersje HackerOS oraz możesz pobrać tapety)"
  puts " * HackerOS Store - sklep dla launcherów do gier, narzędzi do testów penetracyjnych oraz apliakcji"
  puts " * Security Mode - tryb do testow penetracyjnych"
  puts " * Hacker Mode - tryb gry"
  puts " * isolator - narzedzie cli do instalacji pakietów z specjalnego repo w kontnerach distrobox"
  puts " * hpm - specialne repozytorium pakietów dla HackerOS (kazdy pakiet jest w izolowanych środowiskach)"
  puts " * HackerOS Game Mode - tryb gry inspirowany asus armoury crate"
  puts " * hup - system automatycznych aktualizacji"
  puts " * hammer - system z atomowym podejściem do systemu (snapshoty btrfs)"
  puts " * HackerOS Games - gui do uruchamiania gier: starblaster, bit-jump, bark squadron"
  puts " * HackerOS Cockpit (archiwum) - centrum sterowania systemem w przegladarce"
  puts " * Hacker Launcher - Uruchamiaj gry windows za pomoca tej aplikacji"
  puts " * virus - narzędzie cli inspirowane cargo dla języka programowania Hacker Lang Advanced"
  puts " * HackerOS Builder - specjalna nakładka dla live build"
  puts " * Blue Enviroment (BETA - niestabilne) - jezeli chcesz pomoc w rozwoju srodowiska graficznego HackerOS skontaktuj sie na gmail - <hackeros068@gmail.com> lub <https://github.com/orgs/HackerOS-Linux-System/discussions>"
end

def handle_plugin(args : Array(String), lang : String)
  trans = get_translations_main[lang]
  if args.empty?
    show_plugin_help(lang)
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "list"
    puts "#{Colors.bold}#{Colors.magenta}#{trans["plugins"]}#{Colors.reset}"
    Dir.glob((HackerPaths.plugin_dir / "*.hacker").to_s).each do |f|
      begin
        config = parse_hacker_file(f)
        name = config["name"]?.as?(String) || File.basename(f, ".hacker")
        enabled = config["enabled"]? == "true"
        puts " #{name} - #{enabled ? "#{Colors.green}#{trans["enabled"]}#{Colors.reset}" : "#{Colors.red}#{trans["disabled"]}#{Colors.reset}"}"
      rescue
        puts " #{File.basename(f, ".hacker")} - #{Colors.red}#{trans["invalid"]}#{Colors.reset}"
      end
    end
  when "enable"
    if args.size < 2
      puts "#{Colors.red}#{trans["usage_plugin_enable"]}#{Colors.reset}"
      exit(1)
    end
    name = args[1]
    file = HackerPaths.plugin_dir / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "true"
        write_hacker_file(file.to_s, config)
        puts "#{Colors.green}#{trans["enabled_plugin"]} '#{name}'.#{Colors.reset}"
      rescue ex
        puts "#{Colors.red}#{trans["error_enabling"]} #{ex.message}#{Colors.reset}"
      end
    else
      puts "#{Colors.red}#{trans["plugin_not_found"]} '#{name}'.#{Colors.reset}"
    end
  when "disable"
    if args.size < 2
      puts "#{Colors.red}#{trans["usage_plugin_disable"]}#{Colors.reset}"
      exit(1)
    end
    name = args[1]
    file = HackerPaths.plugin_dir / "#{name}.hacker"
    if File.exists?(file)
      begin
        config = parse_hacker_file(file.to_s)
        config["enabled"] = "false"
        write_hacker_file(file.to_s, config)
        puts "#{Colors.green}#{trans["disabled_plugin"]} '#{name}'.#{Colors.reset}"
      rescue ex
        puts "#{Colors.red}#{trans["error_disabling"]} #{ex.message}#{Colors.reset}"
      end
    else
      puts "#{Colors.red}#{trans["plugin_not_found"]} '#{name}'.#{Colors.reset}"
    end
  else
    puts "#{Colors.red}#{trans["unknown_plugin"]} #{subcommand}#{Colors.reset}"
    show_plugin_help(lang)
    exit(1)
  end
end

def show_plugin_help(lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["plugin_subcommands"]}#{Colors.reset}"
  puts " #{Colors.gray}list #{Colors.reset}- #{trans["list_desc"]}"
  puts " #{Colors.gray}enable <name> #{Colors.reset}- #{trans["enable_desc"]}"
  puts " #{Colors.gray}disable <name> #{Colors.reset}- #{trans["disable_desc"]}"
end

def handle_enable(args : Array(String), lang : String)
  trans = get_translations_main[lang]
  if args.empty?
    show_enable_help(lang)
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "motd"
    safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-motd /usr/libexec/")
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    puts "#{Colors.green}#{trans["enabled_motd"]}#{Colors.reset}"
  when "special-motd"
    safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-special-motd /usr/libexec/hackeros-motd")
    safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
    puts "#{Colors.green}#{trans["enabled_special_motd"]}#{Colors.reset}"
  else
    puts "#{Colors.red}#{trans["unknown_enable"]} #{subcommand}#{Colors.reset}"
    show_enable_help(lang)
    exit(1)
  end
end

def show_enable_help(lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["enable_subcommands"]}#{Colors.reset}"
  puts " #{Colors.gray}motd #{Colors.reset}- #{trans["motd_desc"]}"
  puts " #{Colors.gray}special-motd #{Colors.reset}- #{trans["special_motd_desc"]}"
end

def handle_disable(args : Array(String), lang : String)
  trans = get_translations_main[lang]
  if args.empty?
    show_disable_help(lang)
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "motd", "special-motd"
    safe_run("sudo rm -rf /usr/libexec/hackeros-motd")
    puts "#{Colors.green}#{trans["disabled_motd"]}#{Colors.reset}"
  else
    puts "#{Colors.red}#{trans["unknown_disable"]} #{subcommand}#{Colors.reset}"
    show_disable_help(lang)
    exit(1)
  end
end

def show_disable_help(lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["disable_subcommands"]}#{Colors.reset}"
  puts " #{Colors.gray}motd #{Colors.reset}- #{trans["motd_desc"]}"
  puts " #{Colors.gray}special-motd #{Colors.reset}- #{trans["special_motd_desc"]}"
end

def handle_settings(args : Array(String), lang : String)
  trans = get_translations_main[lang]
  config_dir = Path.home / ".config" / "hackeros" / "hacker"
  language_file = config_dir / "language.json"
  Dir.mkdir_p(config_dir.to_s) unless Dir.exists?(config_dir.to_s)
  supported_languages = ["pl", "en", "de", "fr", "es", "it", "ru", "zh", "ja", "ko", "pt", "ar", "hi"]
  if args.empty?
    show_settings_help(supported_languages, lang)
    exit(0)
  end
  subcommand = args[0]
  case subcommand
  when "language"
    if args.size < 2
      current_lang = load_language(language_file.to_s) || "pl"
      puts "#{Colors.green}#{trans["current_language"]} #{current_lang}#{Colors.reset}"
      exit(0)
    end
    new_lang = args[1].downcase
    if supported_languages.includes?(new_lang)
      save_language(language_file.to_s, new_lang)
      puts "#{Colors.green}#{trans["language_set"]} #{new_lang}.#{Colors.reset}"
    else
      puts "#{Colors.red}#{trans["unsupported_language"]} #{new_lang}. #{trans["supported"]} #{supported_languages.join(", ")}#{Colors.reset}"
      exit(1)
    end
  else
    puts "#{Colors.red}#{trans["unknown_settings"]} #{subcommand}#{Colors.reset}"
    show_settings_help(supported_languages, lang)
    exit(1)
  end
end

def show_settings_help(supported_languages : Array(String), lang : String)
  trans = get_translations_main[lang]
  puts "#{Colors.bold}#{Colors.magenta}#{trans["settings_subcommands"]}#{Colors.reset}"
  puts " #{Colors.gray}language [ <lang> ] #{Colors.reset}- #{trans["language_desc"]}"
end

main
