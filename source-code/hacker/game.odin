package hackeros

import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/rand"
import "core:slice"

get_game_translations :: proc(lang: string) -> map[string]string {
	pl := make(map[string]string)
	pl["welcome"] = "Witaj w HackerOS Text Adventure!"
	pl["description"] = "Jesteś elitarnym hakerem w cyfrowej fortecy. Twoja misja: włam się do głównego komputera i wyodrębnij poufne dane."
	pl["choose_mode"] = "Wybierz tryb gry:"
	pl["easy_mode"] = "Easy Mode - Więcej podpowiedzi, mniej przeszkód."
	pl["normal_mode"] = "Normal Mode - Zrównoważone wyzwanie."
	pl["hard_mode"] = "Hard Mode - Ograniczone podpowiedzi, więcej pułapek."
	pl["enter_mode"] = "Wpisz numer trybu (1-3):"
	pl["invalid_mode"] = "Nieprawidłowy tryb. Domyślny: Normal."
	pl["commands"] = "Komendy: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit"
	pl["puzzle"] = "Zagadka"
	pl["items_here"] = "Przedmioty tutaj"
	pl["firewall_block"] = "Firewall cię blokuje. Potrzebujesz karty kluczowej."
	pl["core_locked"] = "Drzwi do rdzenia są zablokowane. Potrzebujesz hasła."
	pl["trap_triggered"] = "Uruchomiłeś pułapkę! Gra skończona."
	pl["cant_go"] = "Nie możesz iść w tym kierunku."
	pl["took_item"] = "Wziąłeś"
	pl["no_item"] = "Brak takiego przedmiotu tutaj."
	pl["used_keycard"] = "Użyłeś karty kluczowej. Ścieżka na wschód otwarta."
	pl["used_decryption"] = "Użyłeś narzędzia deszyfrującego."
	pl["no_use"] = "Brak użycia dla tego tutaj."
	pl["cant_use"] = "Nie możesz tego użyć."
	pl["no_item_inventory"] = "Nie masz tego przedmiotu."
	pl["inventory"] = "Inwentarz"
	pl["empty"] = "pusty"
	pl["hack_success"] = "Pomyślnie zhakowałeś komputer i wyodrębniłeś dane! Wygrywasz!"
	pl["need_items_hack"] = "Potrzebujesz pendrive USB, hasła i narzędzia deszyfrującego."
	pl["nothing_hack"] = "Nic do hakowania tutaj."
	pl["sabotaged"] = "Sabotowałeś generator, wyłączając część ochrony."
	pl["nothing_sabotage"] = "Nic do sabotowania tutaj."
	pl["available_commands"] = "Dostępne komendy:"
	pl["move_desc"] = " north/south/east/west - Przemieść się"
	pl["take_desc"] = " take <item> - Podnieś przedmiot"
	pl["use_desc"] = " use <item> - Użyj przedmiotu"
	pl["inventory_desc"] = " inventory - Pokaż przedmioty"
	pl["hack_desc"] = " hack - Hakuj terminal lub komputer"
	pl["sabotage_desc"] = " sabotage - Sabotuj maszynę"
	pl["hint_desc"] = " hint - Pobierz podpowiedź"
	pl["quit_desc"] = " quit - Wyjdź z gry"
	pl["hint"] = "Podpowiedź"
	pl["hints_used"] = "Użyte podpowiedzi"
	pl["no_more_hints"] = "Brak więcej podpowiedzi w tym trybie."
	pl["unknown_command"] = "Nieznana komenda. Wpisz 'help'."
	pl["hint_entrance"] = "Eksploruj wszystkie kierunki."
	pl["hint_server_room"] = "Hasło może być w skarbcu danych."
	pl["hint_firewall"] = "Znajdź kartę kluczową w biurze ochrony."
	pl["hint_security"] = "Weź kartę kluczową."
	pl["hint_data_vault"] = "Weź notatkę z hasłem."
	pl["hint_core"] = "Potrzebujesz trzech przedmiotów."
	pl["hint_maintenance"] = "Uważaj na pułapki w trybie hard."
	pl["hint_hidden_lab"] = "Narzędzie deszyfrujące jest kluczowe."
	pl["hint_backup"] = "Sabotaż tu może pomóc."
	pl["no_hint"] = "Brak podpowiedzi tutaj."
	pl["goodbye"] = "Do widzenia, hakerze!"
	pl["entrance_desc"] = "Jesteś przy głównym wejściu fortecy. Ścieżki prowadzą na północ do serwerowni, wschód do komnaty firewall, zachód do biura ochrony, południe do skarbca danych."
	pl["server_room_desc"] = "Jesteś w serwerowni. Terminale buczą z aktywnością. Na północ prowadzi do komory rdzenia."
	pl["firewall_chamber_desc"] = "Jesteś w komnacie firewall. Ogromna cyfrowa ściana blokuje dostęp. Na wschód tunel konserwacyjny."
	pl["security_office_desc"] = "Jesteś w biurze ochrony. Monitory pokazują strumienie nadzoru. Na biurku karta kluczowa."
	pl["data_vault_desc"] = "Jesteś w skarbcu danych. Archiwa otaczają cię. Na południe generator zapasowy."
	pl["core_chamber_desc"] = "Jesteś w komorze rdzenia. Główny komputer jest tu, mocno strzeżony. To twój cel."
	pl["maintenance_tunnel_desc"] = "Jesteś w wąskim tunelu konserwacyjnym. Ciemno i ciasno. Na wschód ukryte laboratorium."
	pl["hidden_lab_desc"] = "Jesteś w ukrytym laboratorium. Eksperymentalna technologia. Jest tu narzędzie deszyfrujące."
	pl["backup_generator_desc"] = "Jesteś w pokoju generatora zapasowego. Na północ skarbiec danych."
	pl["server_puzzle"] = "Konsola wymaga hasła. Podpowiedź: związane z nazwą firmy."
	pl["firewall_puzzle"] = "Firewall musi być ominięty kartą kluczową."
	pl["core_puzzle"] = "Aby zhakować komputer, potrzebujesz pendrive USB, hasła i narzędzia deszyfrującego."
	pl["maintenance_puzzle"] = "Drzwi pułapki wymagają kodu. W trybie hard jest trudne."
	pl["generator_puzzle"] = "Generator może być sabotowany dla rozproszenia."
	en := make(map[string]string)
	en["welcome"] = "Welcome to HackerOS Text Adventure!"
	en["description"] = "You are an elite hacker in a high-security digital fortress. Your mission: breach the central mainframe and extract classified data."
	en["choose_mode"] = "Choose your game mode:"
	en["easy_mode"] = "Easy Mode - More hints, fewer obstacles."
	en["normal_mode"] = "Normal Mode - Balanced challenge."
	en["hard_mode"] = "Hard Mode - Limited hints, more traps and puzzles."
	en["enter_mode"] = "Enter mode number (1-3):"
	en["invalid_mode"] = "Invalid mode. Defaulting to Normal."
	en["commands"] = "Commands: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit"
	en["puzzle"] = "Puzzle"
	en["items_here"] = "Items here"
	en["firewall_block"] = "The firewall blocks you. You need a keycard to bypass."
	en["core_locked"] = "The door to the core is locked. You need the password."
	en["trap_triggered"] = "You triggered a trap! Game over."
	en["cant_go"] = "Can't go that way."
	en["took_item"] = "You took the"
	en["no_item"] = "No such item here."
	en["used_keycard"] = "You used the keycard. Path east is open."
	en["used_decryption"] = "You used the decryption tool."
	en["no_use"] = "No use for that here."
	en["cant_use"] = "Can't use that."
	en["no_item_inventory"] = "You don't have that item."
	en["inventory"] = "Inventory"
	en["empty"] = "empty"
	en["hack_success"] = "You successfully hacked the mainframe and extracted the data! You win!"
	en["need_items_hack"] = "You need the USB drive, password, and decryption tool to hack here."
	en["nothing_hack"] = "Nothing to hack here."
	en["sabotaged"] = "You sabotaged the generator, disabling some security."
	en["nothing_sabotage"] = "Nothing to sabotage here."
	en["available_commands"] = "Available commands:"
	en["move_desc"] = " north/south/east/west - Move in direction"
	en["take_desc"] = " take <item> - Pick up an item"
	en["use_desc"] = " use <item> - Use an item"
	en["inventory_desc"] = " inventory - Show items"
	en["hack_desc"] = " hack - Attempt to hack"
	en["sabotage_desc"] = " sabotage - Sabotage machinery"
	en["hint_desc"] = " hint - Get a hint"
	en["quit_desc"] = " quit - Exit the game"
	en["hint"] = "Hint"
	en["hints_used"] = "Hints used"
	en["no_more_hints"] = "No more hints available in this mode."
	en["unknown_command"] = "Unknown command. Type 'help'."
	en["hint_entrance"] = "Explore all directions to find useful items."
	en["hint_server_room"] = "The password might be in the data vault."
	en["hint_firewall"] = "Find a keycard in the security office."
	en["hint_security"] = "Take the keycard."
	en["hint_data_vault"] = "Grab the password note."
	en["hint_core"] = "You need three items to hack successfully."
	en["hint_maintenance"] = "Watch out for traps in hard mode."
	en["hint_hidden_lab"] = "The decryption tool is crucial for the final hack."
	en["hint_backup"] = "Sabotaging here can help distract security."
	en["no_hint"] = "No hint available here."
	en["goodbye"] = "Goodbye, hacker!"
	en["entrance_desc"] = "You are at the main entrance of the digital fortress. Paths lead north to the server room, east to the firewall chamber, west to the security office, south to the data vault."
	en["server_room_desc"] = "You are in the server room. Terminals hum with activity. North leads to the core chamber."
	en["firewall_chamber_desc"] = "You are in the firewall chamber. A massive digital wall blocks access. East leads to a maintenance tunnel."
	en["security_office_desc"] = "You are in the security office. Monitors show surveillance feeds. There's a keycard on the desk."
	en["data_vault_desc"] = "You are in the data vault. Archives of information surround you. South leads to the backup generator."
	en["core_chamber_desc"] = "You are in the core chamber. The mainframe is here, heavily guarded. This is your target."
	en["maintenance_tunnel_desc"] = "You are in a narrow maintenance tunnel. Dark and cramped. East leads to a hidden lab."
	en["hidden_lab_desc"] = "You are in a hidden lab. Experimental tech lies around. There's a decryption tool here."
	en["backup_generator_desc"] = "You are in the backup generator room. North leads back to the data vault."
	en["server_puzzle"] = "The console requires a password. Hint: It's related to the company name."
	en["firewall_puzzle"] = "The firewall needs to be bypassed with a keycard."
	en["core_puzzle"] = "To hack the mainframe, you need the USB drive, the password, and the decryption tool."
	en["maintenance_puzzle"] = "A trap door requires a code. In hard mode, it's tricky."
	en["generator_puzzle"] = "The generator can be sabotaged to cause a distraction."
	de := make(map[string]string)
	de["welcome"] = "Willkommen zu HackerOS Text Adventure!"
	de["description"] = "Du bist ein Elite-Hacker in einer hochgesicherten digitalen Festung. Deine Mission: Mainframe hacken und Daten extrahieren."
	de["choose_mode"] = "Wähle deinen Spielmodus:"
	de["easy_mode"] = "Easy Mode - Mehr Hinweise, weniger Hindernisse."
	de["normal_mode"] = "Normal Mode - Ausgeglichene Herausforderung."
	de["hard_mode"] = "Hard Mode - Begrenzte Hinweise, mehr Fallen."
	de["enter_mode"] = "Modusnummer eingeben (1-3):"
	de["invalid_mode"] = "Ungültiger Modus. Standard: Normal."
	de["commands"] = "Befehle: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit"
	de["puzzle"] = "Rätsel"
	de["items_here"] = "Items hier"
	de["firewall_block"] = "Die Firewall blockiert dich. Du brauchst eine Keycard."
	de["core_locked"] = "Die Tür zum Kern ist verschlossen. Du brauchst das Passwort."
	de["trap_triggered"] = "Du hast eine Falle ausgelöst! Spiel vorbei."
	de["cant_go"] = "Kann nicht in diese Richtung."
	de["took_item"] = "Du hast den"
	de["no_item"] = "Kein solches Item hier."
	de["used_keycard"] = "Du hast die Keycard verwendet. Pfad nach Osten offen."
	de["used_decryption"] = "Du hast das Dekryptionswerkzeug verwendet."
	de["no_use"] = "Keine Verwendung dafür hier."
	de["cant_use"] = "Kann das nicht verwenden."
	de["no_item_inventory"] = "Du hast dieses Item nicht."
	de["inventory"] = "Inventar"
	de["empty"] = "leer"
	de["hack_success"] = "Du hast den Mainframe gehackt und die Daten extrahiert! Du gewinnst!"
	de["need_items_hack"] = "Du brauchst USB-Stick, Passwort und Dekryptionswerkzeug."
	de["nothing_hack"] = "Nichts zum Hacken hier."
	de["sabotaged"] = "Du hast den Generator sabotiert und damit etwas Sicherheit deaktiviert."
	de["nothing_sabotage"] = "Nichts zum Sabotieren hier."
	de["available_commands"] = "Verfügbare Befehle:"
	de["move_desc"] = " north/south/east/west - Richtung bewegen"
	de["take_desc"] = " take <item> - Item aufnehmen"
	de["use_desc"] = " use <item> - Item verwenden"
	de["inventory_desc"] = " inventory - Items anzeigen"
	de["hack_desc"] = " hack - Hack versuchen"
	de["sabotage_desc"] = " sabotage - Maschine sabotieren"
	de["hint_desc"] = " hint - Hinweis holen"
	de["quit_desc"] = " quit - Spiel beenden"
	de["hint"] = "Hinweis"
	de["hints_used"] = "Verwendete Hinweise"
	de["no_more_hints"] = "Keine weiteren Hinweise in diesem Modus."
	de["unknown_command"] = "Unbekannter Befehl. Tippe 'help'."
	de["hint_entrance"] = "Erkunde alle Richtungen."
	de["hint_server_room"] = "Das Passwort könnte im Datentresor sein."
	de["hint_firewall"] = "Finde eine Keycard im Sicherheitsbüro."
	de["hint_security"] = "Nimm die Keycard."
	de["hint_data_vault"] = "Greife die Passwortnotiz."
	de["hint_core"] = "Du brauchst drei Items."
	de["hint_maintenance"] = "Achte auf Fallen im Hard-Modus."
	de["hint_hidden_lab"] = "Das Dekryptionswerkzeug ist entscheidend."
	de["hint_backup"] = "Sabotage hier kann helfen."
	de["no_hint"] = "Kein Hinweis hier."
	de["goodbye"] = "Auf Wiedersehen, Hacker!"
	de["entrance_desc"] = "Du bist am Haupteingang der digitalen Festung. Pfade führen nördlich zum Serverraum, östlich zur Firewall-Kammer, westlich zum Sicherheitsbüro, südlich zum Datentresor."
	de["server_room_desc"] = "Du bist im Serverraum. Terminals summen. Nördlich zur Kernkammer."
	de["firewall_chamber_desc"] = "Du bist in der Firewall-Kammer. Eine digitale Wand blockiert. Östlich ein Wartungstunnel."
	de["security_office_desc"] = "Du bist im Sicherheitsbüro. Überwachungsmonitore. Auf dem Schreibtisch eine Keycard."
	de["data_vault_desc"] = "Du bist im Datentresor. Archive umgeben dich. Südlich der Backup-Generator."
	de["core_chamber_desc"] = "Du bist in der Kernkammer. Der Mainframe ist hier. Das ist dein Ziel."
	de["maintenance_tunnel_desc"] = "Du bist in einem engen Wartungstunnel. Dunkel und eng. Östlich ein verstecktes Labor."
	de["hidden_lab_desc"] = "Du bist in einem versteckten Labor. Experimentelle Technologie. Hier ist ein Dekryptionswerkzeug."
	de["backup_generator_desc"] = "Du bist im Backup-Generator-Raum. Nördlich zurück zum Datentresor."
	de["server_puzzle"] = "Die Konsole erfordert ein Passwort. Hinweis: Firmenname."
	de["firewall_puzzle"] = "Die Firewall braucht eine Keycard."
	de["core_puzzle"] = "Zum Hacken brauchst du USB-Stick, Passwort und Dekryptionswerkzeug."
	de["maintenance_puzzle"] = "Eine Falltür erfordert einen Code. Im Hard-Modus knifflig."
	de["generator_puzzle"] = "Der Generator kann sabotiert werden."
	switch lang {
		case "de": return de
		case "en": return en
		case: return pl
	}
}

GameMode :: enum { Easy, Normal, Hard }

Location :: struct {
	desc_key: string,
	north, south, east, west: string,
	items: [dynamic]string,
	puzzle_key: string,
}

play_text_game :: proc() {
	lang := load_lang()
	trans := get_game_translations(lang)
	defer delete(trans)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.green, trans["welcome"], Colors.reset)
	fmt.printfln("%s%s%s", Colors.white, trans["description"], Colors.reset)
	fmt.printfln("%s%s%s", Colors.white, trans["choose_mode"], Colors.reset)
	fmt.printfln(" %s1. %s%s", Colors.cyan, trans["easy_mode"], Colors.reset)
	fmt.printfln(" %s2. %s%s", Colors.cyan, trans["normal_mode"], Colors.reset)
	fmt.printfln(" %s3. %s%s", Colors.cyan, trans["hard_mode"], Colors.reset)
	fmt.printfln("%s%s%s", Colors.yellow, trans["enter_mode"], Colors.reset)
	mode_line := read_line()
	mode: GameMode
	switch strings.trim_space(mode_line) {
		case "1": mode = .Easy
		case "3": mode = .Hard
		case "2": mode = .Normal
		case:
			fmt.printfln("%s%s%s", Colors.red, trans["invalid_mode"], Colors.reset)
			mode = .Normal
	}
	max_hints := 3
	switch mode {
		case .Easy: max_hints = 5
		case .Normal: max_hints = 3
		case .Hard: max_hints = 1
	}
	locations := make(map[string]Location)
	locations["entrance"] = Location{
		desc_key = "entrance_desc",
		north = "server_room",
		east = "firewall_chamber",
		west = "security_office",
		south = "data_vault",
		items = make([dynamic]string),
		puzzle_key = "",
	}
	locations["server_room"] = Location{
		desc_key = "server_room_desc",
		south = "entrance",
		north = "core_chamber",
		items = make_items("usb_drive"),
		puzzle_key = "server_puzzle",
	}
	locations["firewall_chamber"] = Location{
		desc_key = "firewall_chamber_desc",
		west = "entrance",
		east = "maintenance_tunnel",
		items = make([dynamic]string),
		puzzle_key = "firewall_puzzle",
	}
	locations["security_office"] = Location{
		desc_key = "security_office_desc",
		east = "entrance",
		items = make_items("keycard"),
		puzzle_key = "",
	}
	locations["data_vault"] = Location{
		desc_key = "data_vault_desc",
		north = "entrance",
		south = "backup_generator",
		items = make_items("password_note"),
		puzzle_key = "",
	}
	locations["core_chamber"] = Location{
		desc_key = "core_chamber_desc",
		south = "server_room",
		items = make([dynamic]string),
		puzzle_key = "core_puzzle",
	}
	locations["maintenance_tunnel"] = Location{
		desc_key = "maintenance_tunnel_desc",
		west = "firewall_chamber",
		east = "hidden_lab",
		items = make([dynamic]string),
		puzzle_key = "maintenance_puzzle",
	}
	locations["hidden_lab"] = Location{
		desc_key = "hidden_lab_desc",
		west = "maintenance_tunnel",
		items = make_items("decryption_tool"),
		puzzle_key = "",
	}
	locations["backup_generator"] = Location{
		desc_key = "backup_generator_desc",
		north = "data_vault",
		items = make([dynamic]string),
		puzzle_key = "generator_puzzle",
	}
	defer {
		for _, loc in locations {
			delete(loc.items)
		}
		delete(locations)
	}
	current_location := "entrance"
	inventory: [dynamic]string
	defer delete(inventory)
	hints_used := 0
	fmt.printfln("%s%s%s", Colors.yellow, trans["commands"], Colors.reset)
	for {
		loc := &locations[current_location]
		fmt.printfln("%s%s%s", Colors.magenta, trans[loc.desc_key], Colors.reset)
		if loc.puzzle_key != "" {
			show_puzzle := false
			switch mode {
				case .Easy: show_puzzle = true
				case .Normal: show_puzzle = rand.float32() < 0.5
				case .Hard: show_puzzle = false
			}
			if show_puzzle {
				fmt.printfln("%s%s: %s%s", Colors.yellow, trans["puzzle"], trans[loc.puzzle_key], Colors.reset)
			}
		}
		if len(loc.items) > 0 {
			items_str := strings.join(loc.items[:], ", ")
			fmt.printfln("%s%s: %s%s", Colors.green, trans["items_here"], items_str, Colors.reset)
		}
		input := strings.trim_space(strings.to_lower(read_line()))
		parts := strings.fields(input)
		if len(parts) == 0 { continue }
		command := parts[0]
		arg := "" if len(parts) < 2 else parts[1]
		switch command {
			case "north", "south", "east", "west":
				next := ""
				switch command {
					case "north": next = loc.north
					case "south": next = loc.south
					case "east": next = loc.east
					case "west": next = loc.west
				}
				if next == "" {
					fmt.printfln("%s%s%s", Colors.red, trans["cant_go"], Colors.reset)
					continue
				}
				blocked := false
				if current_location == "firewall_chamber" && command == "east" && !has_item(inventory[:], "keycard") {
					fmt.printfln("%s%s%s", Colors.red, trans["firewall_block"], Colors.reset)
					blocked = true
				}
				if current_location == "server_room" && command == "north" && !has_item(inventory[:], "password_note") {
					fmt.printfln("%s%s%s", Colors.red, trans["core_locked"], Colors.reset)
					blocked = true
				}
				if current_location == "maintenance_tunnel" && mode == .Hard && rand.float32() < 0.3 {
					fmt.printfln("%s%s%s", Colors.red, trans["trap_triggered"], Colors.reset)
					os.exit(0)
				}
				if !blocked {
					current_location = next
				}
					case "take":
						if arg == "" {
							fmt.printfln("%s%s%s", Colors.red, trans["no_item"], Colors.reset)
							continue
						}
						idx := find_item(loc.items[:], arg)
						if idx < 0 {
							fmt.printfln("%s%s%s", Colors.red, trans["no_item"], Colors.reset)
						} else {
							append(&inventory, arg)
							manual_ordered_remove(&loc.items, idx)
							fmt.printfln("%s%s %s.%s", Colors.green, trans["took_item"], arg, Colors.reset)
						}
					case "use":
						if !has_item(inventory[:], arg) {
							fmt.printfln("%s%s%s", Colors.red, trans["no_item_inventory"], Colors.reset)
							continue
						}
						switch arg {
							case "keycard":
								if current_location == "firewall_chamber" {
									fmt.printfln("%s%s%s", Colors.green, trans["used_keycard"], Colors.reset)
								} else {
									fmt.printfln("%s%s%s", Colors.red, trans["no_use"], Colors.reset)
								}
							case "decryption_tool":
								if current_location == "core_chamber" {
									fmt.printfln("%s%s%s", Colors.green, trans["used_decryption"], Colors.reset)
								} else {
									fmt.printfln("%s%s%s", Colors.red, trans["no_use"], Colors.reset)
								}
							case:
								fmt.printfln("%s%s%s", Colors.red, trans["cant_use"], Colors.reset)
						}
							case "inventory":
								if len(inventory) == 0 {
									fmt.printfln("%s%s: %s%s", Colors.green, trans["inventory"], trans["empty"], Colors.reset)
								} else {
									fmt.printfln("%s%s: %s%s", Colors.green, trans["inventory"], strings.join(inventory[:], ", "), Colors.reset)
								}
							case "hack":
								if current_location == "core_chamber" {
									if has_item(inventory[:], "usb_drive") &&
										has_item(inventory[:], "password_note") &&
										has_item(inventory[:], "decryption_tool") {
											fmt.printfln("%s%s%s", Colors.green, trans["hack_success"], Colors.reset)
											os.exit(0)
										} else {
											fmt.printfln("%s%s%s", Colors.red, trans["need_items_hack"], Colors.reset)
										}
								} else {
									fmt.printfln("%s%s%s", Colors.red, trans["nothing_hack"], Colors.reset)
								}
							case "sabotage":
								if current_location == "backup_generator" {
									fmt.printfln("%s%s%s", Colors.green, trans["sabotaged"], Colors.reset)
								} else {
									fmt.printfln("%s%s%s", Colors.red, trans["nothing_sabotage"], Colors.reset)
								}
							case "help":
								fmt.printfln("%s%s%s", Colors.yellow, trans["available_commands"], Colors.reset)
								help_keys := []string{
									"move_desc", "take_desc", "use_desc", "inventory_desc",
									"hack_desc", "sabotage_desc", "hint_desc", "quit_desc",
								}
								for key in help_keys {
									fmt.println(trans[key])
								}
							case "hint":
								if hints_used >= max_hints {
									fmt.printfln("%s%s%s", Colors.red, trans["no_more_hints"], Colors.reset)
									continue
								}
								hints_used += 1
								hint_key := fmt.tprintf("hint_%s", current_location)
								hint, ok := trans[hint_key]
								if !ok { hint = trans["no_hint"] }
								fmt.printfln("%s%s: %s (%s: %d/%d)%s",
											 Colors.blue, trans["hint"], hint,
					 trans["hints_used"], hints_used, max_hints,
					 Colors.reset)
							case "quit":
								fmt.printfln("%s%s%s", Colors.yellow, trans["goodbye"], Colors.reset)
								os.exit(0)
							case:
								fmt.printfln("%s%s%s", Colors.red, trans["unknown_command"], Colors.reset)
		}
	}
}

make_items :: proc(items: ..string) -> [dynamic]string {
	d: [dynamic]string
	for i in items {
		append(&d, i)
	}
	return d
}

has_item :: proc(inv: []string, item: string) -> bool {
	for i in inv {
		if i == item {
			return true
		}
	}
	return false
}

find_item :: proc(items: []string, item: string) -> int {
	for i, idx in items {
		if i == item {
			return idx
		}
	}
	return -1
}

read_line :: proc() -> string {
	buf: [512]u8
	n, _ := os.read(os.stdin, buf[:])
	if n <= 0 {
		return ""
	}
	line := string(buf[:n])
	return strings.trim_right(line, "\n\r")
}

manual_ordered_remove :: proc(array: ^[dynamic]$T, index: int) {
	if array == nil || index < 0 || index >= len(array) {
		return
	}
	copy(array[index:], array[index+1:])
	resize(array, len(array)-1)
}
