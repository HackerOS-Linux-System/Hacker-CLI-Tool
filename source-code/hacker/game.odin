require "./helpers"
require "json"
require "random"

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

def play_text_game
  lang = load_lang
  translations = get_translations_game
  if lang != "pl" && lang != "en" && lang != "de"
    lang = "en"
  end
  trans = translations[lang]

  puts "#{Colors.bold}#{Colors.green}#{trans["welcome"]}#{Colors.reset}"
  puts "#{Colors.white}#{trans["description"]}#{Colors.reset}"
  puts "#{Colors.white}#{trans["choose_mode"]}#{Colors.reset}"
  puts " #{Colors.cyan}1. #{trans["easy_mode"]}#{Colors.reset}"
  puts " #{Colors.cyan}2. #{trans["normal_mode"]}#{Colors.reset}"
  puts " #{Colors.cyan}3. #{trans["hard_mode"]}#{Colors.reset}"
  puts "#{Colors.yellow}#{trans["enter_mode"]}#{Colors.reset}"
  mode_input = gets.not_nil!.strip
  mode = case mode_input
         when "1" then :easy
         when "2" then :normal
         when "3" then :hard
         else
           puts "#{Colors.red}#{trans["invalid_mode"]}#{Colors.reset}"
           :normal
         end
  locations = {
    "entrance" => {
      "description" => trans["entrance_desc"],
      "north" => "server_room",
      "east" => "firewall_chamber",
      "west" => "security_office",
      "south" => "data_vault",
      "items" => [] of String,
      "puzzle" => nil
    },
    "server_room" => {
      "description" => trans["server_room_desc"],
      "south" => "entrance",
      "north" => "core_chamber",
      "items" => ["usb_drive"],
      "puzzle" => trans["server_puzzle"]
    },
    "firewall_chamber" => {
      "description" => trans["firewall_chamber_desc"],
      "west" => "entrance",
      "east" => "maintenance_tunnel",
      "items" => [] of String,
      "puzzle" => trans["firewall_puzzle"]
    },
    "security_office" => {
      "description" => trans["security_office_desc"],
      "east" => "entrance",
      "items" => ["keycard"],
      "puzzle" => nil
    },
    "data_vault" => {
      "description" => trans["data_vault_desc"],
      "north" => "entrance",
      "south" => "backup_generator",
      "items" => ["password_note"],
      "puzzle" => nil
    },
    "core_chamber" => {
      "description" => trans["core_chamber_desc"],
      "south" => "server_room",
      "items" => [] of String,
      "puzzle" => trans["core_puzzle"]
    },
    "maintenance_tunnel" => {
      "description" => trans["maintenance_tunnel_desc"],
      "west" => "firewall_chamber",
      "east" => "hidden_lab",
      "items" => [] of String,
      "puzzle" => trans["maintenance_puzzle"]
    },
    "hidden_lab" => {
      "description" => trans["hidden_lab_desc"],
      "west" => "maintenance_tunnel",
      "items" => ["decryption_tool"],
      "puzzle" => nil
    },
    "backup_generator" => {
      "description" => trans["backup_generator_desc"],
      "north" => "data_vault",
      "items" => [] of String,
      "puzzle" => trans["generator_puzzle"]
    }
  }
  current_location = "entrance"
  inventory = [] of String
  hints_used = 0
  max_hints = case mode
              when :easy then 5
              when :normal then 3
              when :hard then 1
              else 3
              end
  trapped = false
  puts "#{Colors.yellow}#{trans["commands"]}#{Colors.reset}"
  loop do
    location_data = locations[current_location]
    puts "#{Colors.magenta}#{location_data["description"]}#{Colors.reset}"
    if location_data["puzzle"]
      puts "#{Colors.yellow}#{trans["puzzle"]}: #{location_data["puzzle"]}#{Colors.reset}" if mode == :easy || (mode == :normal && Random.rand < 0.5)
    end
    if !(location_data["items"].as(Array(String))).empty?
      puts "#{Colors.green}#{trans["items_here"]}: #{(location_data["items"].as(Array(String))).join(", ")}#{Colors.reset}"
    end
    input = gets.not_nil!.strip.downcase
    inputs = input.split(" ")
    command = inputs[0]?
    arg = inputs[1]? if inputs.size > 1
    case command
    when "north", "south", "east", "west"
      direction = command.not_nil!
      next_location = location_data[direction]?
      if next_location
        if current_location == "firewall_chamber" && direction == "east" && !inventory.includes?("keycard")
          puts "#{Colors.red}#{trans["firewall_block"]}#{Colors.reset}"
        elsif current_location == "server_room" && direction == "north" && !inventory.includes?("password_note")
          puts "#{Colors.red}#{trans["core_locked"]}#{Colors.reset}"
        elsif current_location == "maintenance_tunnel" && mode == :hard && Random.rand < 0.3
          puts "#{Colors.red}#{trans["trap_triggered"]}#{Colors.reset}"
          exit(0)
        else
          current_location = next_location
        end
      else
        puts "#{Colors.red}#{trans["cant_go"]}#{Colors.reset}"
      end
    when "take"
      if arg && (location_data["items"].as(Array(String))).includes?(arg)
        inventory << arg
        (location_data["items"].as(Array(String))).delete(arg)
        puts "#{Colors.green}#{trans["took_item"]} #{arg}.#{Colors.reset}"
      else
        puts "#{Colors.red}#{trans["no_item"]}#{Colors.reset}"
      end
    when "use"
      if arg && inventory.includes?(arg)
        case arg
        when "keycard"
          if current_location == "firewall_chamber"
            puts "#{Colors.green}#{trans["used_keycard"]}#{Colors.reset}"
          else
            puts "#{Colors.red}#{trans["no_use"]}#{Colors.reset}"
          end
        when "decryption_tool"
          if current_location == "core_chamber"
            puts "#{Colors.green}#{trans["used_decryption"]}#{Colors.reset}"
          else
            puts "#{Colors.red}#{trans["no_use"]}#{Colors.reset}"
          end
        else
          puts "#{Colors.red}#{trans["cant_use"]}#{Colors.reset}"
        end
      else
        puts "#{Colors.red}#{trans["no_item_inventory"]}#{Colors.reset}"
      end
    when "inventory"
      puts "#{Colors.green}#{trans["inventory"]}: #{inventory.join(", ") || trans["empty"]}#{Colors.reset}"
    when "hack"
      if current_location == "core_chamber" && inventory.includes?("usb_drive") && inventory.includes?("password_note") && inventory.includes?("decryption_tool")
        puts "#{Colors.green}#{trans["hack_success"]}#{Colors.reset}"
        exit(0)
      elsif current_location == "core_chamber"
        puts "#{Colors.red}#{trans["need_items_hack"]}#{Colors.reset}"
      else
        puts "#{Colors.red}#{trans["nothing_hack"]}#{Colors.reset}"
      end
    when "sabotage"
      if current_location == "backup_generator"
        puts "#{Colors.green}#{trans["sabotaged"]}#{Colors.reset}"
      else
        puts "#{Colors.red}#{trans["nothing_sabotage"]}#{Colors.reset}"
      end
    when "help"
      puts "#{Colors.yellow}#{trans["available_commands"]}#{Colors.reset}"
      puts trans["move_desc"]
      puts trans["take_desc"]
      puts trans["use_desc"]
      puts trans["inventory_desc"]
      puts trans["hack_desc"]
      puts trans["sabotage_desc"]
      puts trans["hint_desc"]
      puts trans["quit_desc"]
    when "hint"
      if hints_used < max_hints
        hints_used += 1
        hint = case current_location
               when "entrance" then trans["hint_entrance"]
               when "server_room" then trans["hint_server_room"]
               when "firewall_chamber" then trans["hint_firewall"]
               when "security_office" then trans["hint_security"]
               when "data_vault" then trans["hint_data_vault"]
               when "core_chamber" then trans["hint_core"]
               when "maintenance_tunnel" then trans["hint_maintenance"]
               when "hidden_lab" then trans["hint_hidden_lab"]
               when "backup_generator" then trans["hint_backup"]
               else trans["no_hint"]
               end
        puts "#{Colors.blue}#{trans["hint"]}: #{hint} (#{trans["hints_used"]}: #{hints_used}/#{max_hints})#{Colors.reset}"
      else
        puts "#{Colors.red}#{trans["no_more_hints"]}#{Colors.reset}"
      end
    when "quit"
      puts "#{Colors.yellow}#{trans["goodbye"]}#{Colors.reset}"
      exit(0)
    else
      puts "#{Colors.red}#{trans["unknown_command"]}#{Colors.reset}"
    end
  end
end

def get_translations_game : Hash(String, Hash(String, String))
  {
    "pl" => {
      "welcome" => "Witaj w HackerOS Text Adventure!",
      "description" => "Jesteś elitarnym hakerem w cyfrowej fortecy o wysokim poziomie bezpieczeństwa. Twoja misja: włam się do głównego komputera i wyodrębnij poufne dane.",
      "choose_mode" => "Wybierz tryb gry:",
      "easy_mode" => "Easy Mode - Więcej podpowiedzi, mniej przeszkód.",
      "normal_mode" => "Normal Mode - Zrównoważone wyzwanie.",
      "hard_mode" => "Hard Mode - Ograniczona liczba podpowiedzi, więcej pułapek i zagadek.",
      "enter_mode" => "Wpisz numer trybu (1-3):",
      "invalid_mode" => "Nieprawidłowy tryb. Domyślny: Normal.",
      "entrance_desc" => "Jesteś przy głównym wejściu cyfrowej fortecy. Ścieżki prowadzą na północ do serwerowni, na wschód do komnaty firewall, na zachód do biura ochrony i na południe do skarbca danych.",
      "server_room_desc" => "Jesteś w serwerowni. Terminale buczą z aktywnością. Jest tu zablokowana konsola. Na północ prowadzi do komory rdzenia.",
      "server_puzzle" => "Konsola wymaga hasła. Podpowiedź: Jest związane z nazwą firmy.",
      "firewall_chamber_desc" => "Jesteś w komnacie firewall. Ogromna cyfrowa ściana blokuje dalszy dostęp. Na wschód prowadzi tunel konserwacyjny.",
      "firewall_puzzle" => "Firewall musi być ominięty za pomocą karty kluczowej.",
      "security_office_desc" => "Jesteś w biurze ochrony. Monitory pokazują strumienie nadzoru. Na biurku jest karta kluczowa.",
      "data_vault_desc" => "Jesteś w skarbcu danych. Otaczają cię archiwa informacji. Na południe prowadzi do generatora zapasowego.",
      "core_chamber_desc" => "Jesteś w komorze rdzenia. Główny komputer jest tu, mocno strzeżony. To twój cel.",
      "core_puzzle" => "Aby zhakować główny komputer, potrzebujesz pendrive'a USB i hasła.",
      "maintenance_tunnel_desc" => "Jesteś w wąskim tunelu konserwacyjnym. Jest ciemno i ciasno. Na zachód z powrotem do firewall, na wschód do ukrytego laboratorium.",
      "maintenance_puzzle" => "Drzwi pułapki wymagają kodu. W trybie hard jest trudne.",
      "hidden_lab_desc" => "Jesteś w ukrytym laboratorium. Wokół leży eksperymentalna technologia. Jest tu narzędzie deszyfrujące.",
      "backup_generator_desc" => "Jesteś w pokoju generatora zapasowego. Czasami występują skoki mocy. Na północ z powrotem do skarbca danych.",
      "generator_puzzle" => "Generator może być sabotowany, aby spowodować rozproszenie.",
      "commands" => "Komendy: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit",
      "puzzle" => "Zagadka",
      "items_here" => "Przedmioty tutaj",
      "firewall_block" => "Firewall cię blokuje. Potrzebujesz karty kluczowej do ominięcia.",
      "core_locked" => "Drzwi do rdzenia są zablokowane. Potrzebujesz hasła.",
      "trap_triggered" => "Uruchomiłeś pułapkę! Gra skończona.",
      "cant_go" => "Nie możesz iść w tym kierunku.",
      "took_item" => "Wziąłeś",
      "no_item" => "Brak takiego przedmiotu tutaj.",
      "used_keycard" => "Użyłeś karty kluczowej do ominięcia firewall. Ścieżka na wschód jest otwarta.",
      "no_use" => "Brak użycia dla tego tutaj.",
      "cant_use" => "Nie możesz tego użyć.",
      "no_item_inventory" => "Nie masz tego przedmiotu.",
      "inventory" => "Inwentarz",
      "empty" => "pusty",
      "hack_success" => "Pomyślnie zhakowałeś główny komputer i wyodrębniłeś dane! Wygrywasz!",
      "need_items_hack" => "Potrzebujesz pendrive'a USB, hasła i narzędzia deszyfrującego do hakowania tutaj.",
      "nothing_hack" => "Nic do hakowania tutaj.",
      "sabotaged" => "Sabotowałeś generator, powodując wahania mocy, które wyłączają część ochrony.",
      "nothing_sabotage" => "Nic do sabotowania tutaj.",
      "available_commands" => "Dostępne komendy:",
      "move_desc" => " north, south, east, west - Przesuń się w tym kierunku",
      "take_desc" => " take <item> - Podnieś przedmiot",
      "use_desc" => " use <item> - Użyj przedmiotu z inwentarza",
      "inventory_desc" => " inventory - Pokaż swoje przedmioty",
      "hack_desc" => " hack - Próba hakowania terminala lub głównego komputera",
      "sabotage_desc" => " sabotage - Sabotaż maszynerii (w określonych miejscach)",
      "hint_desc" => " hint - Pobierz podpowiedź (ograniczona przez tryb)",
      "quit_desc" => " quit - Wyjdź z gry",
      "hint" => "Podpowiedź",
      "hints_used" => "Użyte podpowiedzi",
      "no_more_hints" => "Brak więcej podpowiedzi dostępnych w tym trybie.",
      "unknown_command" => "Nieznana komenda. Wpisz 'help' po komendy.",
      "hint_entrance" => "Eksploruj wszystkie kierunki, aby znaleźć przydatne przedmioty.",
      "hint_server_room" => "Hasło może być w skarbcu danych.",
      "hint_firewall" => "Znajdź kartę kluczową w biurze ochrony.",
      "hint_security" => "Weź kartę kluczową.",
      "hint_data_vault" => "Weź notatkę z hasłem.",
      "hint_core" => "Potrzebujesz trzech przedmiotów do sukcesu hakowania.",
      "hint_maintenance" => "Uważaj na pułapki w trybie hard.",
      "hint_hidden_lab" => "Narzędzie deszyfrujące jest kluczowe dla ostatecznego hakowania.",
      "hint_backup" => "Sabotaż tutaj może pomóc w rozproszeniu ochrony.",
      "no_hint" => "Brak podpowiedzi tutaj.",
      "goodbye" => "Do widzenia, hakerze!"
    },
    "en" => {
      "welcome" => "Welcome to HackerOS Text Adventure!",
      "description" => "You are an elite hacker in a high-security digital fortress. Your mission: breach the central mainframe and extract classified data.",
      "choose_mode" => "Choose your game mode:",
      "easy_mode" => "Easy Mode - More hints, fewer obstacles.",
      "normal_mode" => "Normal Mode - Balanced challenge.",
      "hard_mode" => "Hard Mode - Limited hints, more traps and puzzles.",
      "enter_mode" => "Enter mode number (1-3):",
      "invalid_mode" => "Invalid mode. Defaulting to Normal.",
      "entrance_desc" => "You are at the main entrance of the digital fortress. Pathways lead north to the server room, east to the firewall chamber, west to the security office, and south to the data vault.",
      "server_room_desc" => "You are in the server room. Terminals hum with activity. There's a locked console here. North leads to the core chamber.",
      "server_puzzle" => "The console requires a password. Hint: It's related to the company name.",
      "firewall_chamber_desc" => "You are in the firewall chamber. A massive digital wall blocks further access. East leads to a maintenance tunnel.",
      "firewall_puzzle" => "The firewall needs to be bypassed with a keycard.",
      "security_office_desc" => "You are in the security office. Monitors show surveillance feeds. There's a keycard on the desk.",
      "data_vault_desc" => "You are in the data vault. Archives of information surround you. South leads to the backup generator.",
      "core_chamber_desc" => "You are in the core chamber. The mainframe is here, heavily guarded. This is your target.",
      "core_puzzle" => "To hack the mainframe, you need the USB drive and the password.",
      "maintenance_tunnel_desc" => "You are in a narrow maintenance tunnel. It's dark and cramped. West back to firewall, east to a hidden lab.",
      "maintenance_puzzle" => "A trap door requires a code. In hard mode, it's tricky.",
      "hidden_lab_desc" => "You are in a hidden lab. Experimental tech lies around. There's a decryption tool here.",
      "backup_generator_desc" => "You are in the backup generator room. Power surges occasionally. North back to data vault.",
      "generator_puzzle" => "The generator can be sabotaged to cause a distraction.",
      "commands" => "Commands: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit",
      "puzzle" => "Puzzle",
      "items_here" => "Items here",
      "firewall_block" => "The firewall blocks you. You need a keycard to bypass.",
      "core_locked" => "The door to the core is locked. You need the password.",
      "trap_triggered" => "You triggered a trap! Game over.",
      "cant_go" => "Can't go that way.",
      "took_item" => "You took the",
      "no_item" => "No such item here.",
      "used_keycard" => "You used the keycard to bypass the firewall. Path east is open.",
      "no_use" => "No use for that here.",
      "cant_use" => "Can't use that.",
      "no_item_inventory" => "You don't have that item.",
      "inventory" => "Inventory",
      "empty" => "empty",
      "hack_success" => "You successfully hacked the mainframe and extracted the data! You win!",
      "need_items_hack" => "You need the USB drive, password, and decryption tool to hack here.",
      "nothing_hack" => "Nothing to hack here.",
      "sabotaged" => "You sabotaged the generator, causing a power fluctuation that disables some security.",
      "nothing_sabotage" => "Nothing to sabotage here.",
      "available_commands" => "Available commands:",
      "move_desc" => " north, south, east, west - Move in that direction",
      "take_desc" => " take <item> - Pick up an item",
      "use_desc" => " use <item> - Use an item from inventory",
      "inventory_desc" => " inventory - Show your items",
      "hack_desc" => " hack - Attempt to hack a terminal or mainframe",
      "sabotage_desc" => " sabotage - Sabotage machinery (in specific locations)",
      "hint_desc" => " hint - Get a hint (limited by mode)",
      "quit_desc" => " quit - Exit the game",
      "hint" => "Hint",
      "hints_used" => "Hints used",
      "no_more_hints" => "No more hints available in this mode.",
      "unknown_command" => "Unknown command. Type 'help' for commands.",
      "hint_entrance" => "Explore all directions to find useful items.",
      "hint_server_room" => "The password might be in the data vault.",
      "hint_firewall" => "Find a keycard in the security office.",
      "hint_security" => "Take the keycard.",
      "hint_data_vault" => "Grab the password note.",
      "hint_core" => "You need three items to hack successfully.",
      "hint_maintenance" => "Watch out for traps in hard mode.",
      "hint_hidden_lab" => "The decryption tool is crucial for the final hack.",
      "hint_backup" => "Sabotaging here can help distract security.",
      "no_hint" => "No hint available here.",
      "goodbye" => "Goodbye, hacker!"
    },
    "de" => {
      "welcome" => "Willkommen zu HackerOS Text Adventure!",
      "description" => "Du bist ein Elite-Hacker in einer hochgesicherten digitalen Festung. Deine Mission: Breche in den zentralen Mainframe ein und extrahiere klassifizierte Daten.",
      "choose_mode" => "Wähle deinen Spielmodus:",
      "easy_mode" => "Easy Mode - Mehr Hinweise, weniger Hindernisse.",
      "normal_mode" => "Normal Mode - Ausgeglichene Herausforderung.",
      "hard_mode" => "Hard Mode - Begrenzte Hinweise, mehr Fallen und Rätsel.",
      "enter_mode" => "Modusnummer eingeben (1-3):",
      "invalid_mode" => "Ungültiger Modus. Standard: Normal.",
      "entrance_desc" => "Du bist am Haupteingang der digitalen Festung. Pfade führen nordwärts zum Serverraum, ostwärts zur Firewall-Kammer, westwärts zum Sicherheitsbüro und südwärts zum Datentresor.",
      "server_room_desc" => "Du bist im Serverraum. Terminals summen vor Aktivität. Hier ist eine verschlossene Konsole. Nordwärts führt zur Kernkammer.",
      "server_puzzle" => "Die Konsole erfordert ein Passwort. Hinweis: Es ist mit dem Firmennamen verbunden.",
      "firewall_chamber_desc" => "Du bist in der Firewall-Kammer. Eine massive digitale Wand blockiert weiteren Zugang. Ostwärts führt zu einem Wartungstunnel.",
      "firewall_puzzle" => "Die Firewall muss mit einer Keycard umgangen werden.",
      "security_office_desc" => "Du bist im Sicherheitsbüro. Monitore zeigen Überwachungsfeeds. Auf dem Schreibtisch liegt eine Keycard.",
      "data_vault_desc" => "Du bist im Datentresor. Archive von Informationen umgeben dich. Südwärts führt zum Backup-Generator.",
      "core_chamber_desc" => "Du bist in der Kernkammer. Der Mainframe ist hier, stark bewacht. Das ist dein Ziel.",
      "core_puzzle" => "Um den Mainframe zu hacken, brauchst du den USB-Stick und das Passwort.",
      "maintenance_tunnel_desc" => "Du bist in einem engen Wartungstunnel. Es ist dunkel und eng. Westwärts zurück zur Firewall, ostwärts zu einem versteckten Labor.",
      "maintenance_puzzle" => "Eine Falltür erfordert einen Code. Im Hard-Modus ist es knifflig.",
      "hidden_lab_desc" => "Du bist in einem versteckten Labor. Experimentelle Tech liegt herum. Hier ist ein Dekryptionswerkzeug.",
      "backup_generator_desc" => "Du bist im Raum des Backup-Generators. Stromstöße treten gelegentlich auf. Nordwärts zurück zum Datentresor.",
      "generator_puzzle" => "Der Generator kann sabotiert werden, um eine Ablenkung zu verursachen.",
      "commands" => "Befehle: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit",
      "puzzle" => "Rätsel",
      "items_here" => "Items hier",
      "firewall_block" => "Die Firewall blockiert dich. Du brauchst eine Keycard zum Umgehen.",
      "core_locked" => "Die Tür zum Kern ist verschlossen. Du brauchst das Passwort.",
      "trap_triggered" => "Du hast eine Falle ausgelöst! Spiel vorbei.",
      "cant_go" => "Kann nicht in diese Richtung gehen.",
      "took_item" => "Du hast den",
      "no_item" => "Kein solcher Item hier.",
      "used_keycard" => "Du hast die Keycard verwendet, um die Firewall zu umgehen. Pfad ostwärts ist offen.",
      "no_use" => "Keine Verwendung dafür hier.",
      "cant_use" => "Kann das nicht verwenden.",
      "no_item_inventory" => "Du hast diesen Item nicht.",
      "inventory" => "Inventar",
      "empty" => "leer",
      "hack_success" => "Du hast den Mainframe erfolgreich gehackt und die Daten extrahiert! Du gewinnst!",
      "need_items_hack" => "Du brauchst den USB-Stick, Passwort und Dekryptionswerkzeug zum Hacken hier.",
      "nothing_hack" => "Nichts zum Hacken hier.",
      "sabotaged" => "Du hast den Generator sabotiert, was eine Stromschwankung verursacht, die einige Sicherheiten deaktiviert.",
      "nothing_sabotage" => "Nichts zum Sabotieren hier.",
      "available_commands" => "Verfügbare Befehle:",
      "move_desc" => " north, south, east, west - Bewege dich in diese Richtung",
      "take_desc" => " take <item> - Nimm einen Item auf",
      "use_desc" => " use <item> - Verwende einen Item aus dem Inventar",
      "inventory_desc" => " inventory - Zeige deine Items",
      "hack_desc" => " hack - Versuch, einen Terminal oder Mainframe zu hacken",
      "sabotage_desc" => " sabotage - Sabotiere Maschinerie (in spezifischen Orten)",
      "hint_desc" => " hint - Hole einen Hinweis (begrenzt durch Modus)",
      "quit_desc" => " quit - Verlasse das Spiel",
      "hint" => "Hinweis",
      "hints_used" => "Verwendete Hinweise",
      "no_more_hints" => "Keine weiteren Hinweise in diesem Modus verfügbar.",
      "unknown_command" => "Unbekannter Befehl. Tippe 'help' für Befehle.",
      "hint_entrance" => "Erkunde alle Richtungen, um nützliche Items zu finden.",
      "hint_server_room" => "Das Passwort könnte im Datentresor sein.",
      "hint_firewall" => "Finde eine Keycard im Sicherheitsbüro.",
      "hint_security" => "Nimm die Keycard.",
      "hint_data_vault" => "Greife die Passwortnotiz.",
      "hint_core" => "Du brauchst drei Items für einen erfolgreichen Hack.",
      "hint_maintenance" => "Achte auf Fallen im Hard-Modus.",
      "hint_hidden_lab" => "Das Dekryptionswerkzeug ist entscheidend für den finalen Hack.",
      "hint_backup" => "Sabotage hier kann helfen, die Sicherheit abzulenken.",
      "no_hint" => "Kein Hinweis hier verfügbar.",
      "goodbye" => "Auf Wiedersehen, Hacker!"
    },
  }
end
