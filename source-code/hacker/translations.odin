package hackeros

get_translations_main :: proc(lang: string) -> map[string]string {
	trans: map[string]string
	switch lang {
		case "pl":
			trans = pl_translations()
		case "en":
			trans = en_translations()
		case "de":
			trans = de_translations()
		case:
			trans = pl_translations() // default to Polish
	}
	return trans
}

pl_translations :: proc() -> map[string]string {
	trans: map[string]string
	// Translations from env
	trans["env_create_usage"] = "Użycie: hacker env create <plik.hk|plik.yaml>"
	trans["env_remove_usage"] = "Użycie: hacker env remove <nazwa>"
	trans["env_unknown_sub"] = "Nieznana podkomenda env:"
	trans["file_not_exists"] = "Plik nie istnieje:"
	trans["env_missing_fields"] = "Brak wymaganych pól name lub image w pliku konfiguracyjnym"
	trans["env_creating"] = "Tworzenie środowiska"
	trans["env_created"] = "Środowisko zostało utworzone pomyślnie!"
	trans["env_removed"] = "Środowisko zostało usunięte."
	trans["env_list"] = "Lista wszystkich środowisk Hacker env:"
	trans["env_subcommands"] = "Podkomendy env:"
	trans["env_create_desc"] = "Utwórz nowe środowisko z pliku"
	trans["env_remove_desc"] = "Usuń środowisko"
	trans["env_enter_desc"] = "Wejdź do środowiska (z podpiętymi narzędziami)"
	trans["env_docs_desc"] = "Pełny tutorial + przykłady"
	trans["env_settings_desc"] = "Lista wszystkich środowisk"
	trans["env_docs"] = `
	%s=== Hacker env – pełny tutorial ===%s
	1. Utwórz plik konfiguracyjny (np. pentest.hk):
	[env]
	-> name => pentest-env
	-> image => fedora:latest
	-> shell => zsh
	[packages]
	-> -> nmap
	-> -> metasploit-framework
	-> -> burpsuite
	[sync_configs]
	-> -> ~/.zshrc
	-> -> ~/.config/nvim
	[sync_tools]
	-> snap => ["code"]
	-> flatpak => ["com.brave.Browser"]
	-> system => ["~/go/bin/gf"]
	2. Utwórz środowisko:
	hacker env create ./pentest.hk
	3. Wejdź:
	hacker env enter pentest-env
	4. Usuń:
	hacker env remove pentest-env
	Wszystkie środowiska są normalnymi kontenerami podman – możesz używać distrobox enter / podman exec normalnie.
	`

	// Translations from main
	trans["usage_install"] = "Użycie: hacker install <pakiet>"
	trans["usage_remove"] = "Użycie: hacker remove <pakiet>"
	trans["usage_flatpak_install"] = "Użycie: hacker flatpak-install <pakiet>"
	trans["usage_flatpak_remove"] = "Użycie: hacker flatpak-remove <pakiet>"
	trans["usage_enter"] = "Użycie: hacker enter <nazwa>"
	trans["usage_remove_container"] = "Użycie: hacker remove-container <nazwa>"
	trans["usage_restart"] = "Użycie: hacker restart <usługa>"
	trans["how_to_create1"] = "Jak tworzyć własne komendy:"
	trans["how_to_create2"] = "1. Utwórz plik .hacker w ~/.hackeros/custom"
	trans["how_to_create3"] = "2. Dodaj [config] -> exec => komenda do wykonania"
	trans["version_tool"] = "Wersja narzędzia: 2.3"
	trans["version_os"] = "Wersja: HackerOS v4.4"
	trans["file_not_found"] = "Plik nie znaleziono:"
	trans["variant_not_found"] = "Wariant nie znaleziono"
	trans["no_exec_custom"] = "Brak exec w niestandardowej komendzie"
	trans["error_custom"] = "Błąd parsowania niestandardowej komendy"
	trans["unknown_command"] = "Nieznana komenda:"
	trans["system_subcommands"] = "Podkomendy system:"
	trans["logs_desc"] = "Pokaż logi systemu"
	trans["unknown_system"] = "Nieznana podkomenda system:"
	trans["unknown_update_flag"] = "Nieznana flaga update:"
	trans["available_flags"] = "Dostępne flagi: --with-gui"
	trans["tools_index"] = "Indeks narzędzi HackerOS:"
	trans["tool_bytes"] = "Manager pakietów dla Hacker Lang"
	trans["tool_hl"] = "Główne narzędzie Hacker Lang"
	trans["tool_hli"] = "Interaktywna wersja narzędzia hl"
	trans["tool_hacker"] = "Główne narzędzie"
	trans["tool_kernel"] = "Kernel Hacker"
	trans["tool_steam"] = "Steam dla HackerOS"
	trans["tool_welcome"] = "Ekran powitalny"
	trans["tool_app"] = "Aplikacja HackerOS"
	trans["tool_store"] = "Sklep HackerOS"
	trans["tool_security_mode"] = "Tryb bezpieczeństwa"
	trans["tool_hacker_mode"] = "Tryb hackera"
	trans["tool_isolator"] = "Izolator"
	trans["tool_hpm"] = "Hacker Package Manager"
	trans["tool_game_mode"] = "Tryb gry"
	trans["tool_hup"] = "Hacker Update"
	trans["tool_hammer"] = "Hammer"
	trans["tool_games"] = "Gry HackerOS"
	trans["tool_launcher"] = "Launcher"
	trans["tool_virus"] = "Virus simulator"
	trans["tool_builder"] = "Builder"
	trans["tool_blue"] = "Środowisko Blue (BETA)"
	trans["plugins"] = "Pluginy:"
	trans["enabled"] = "włączony"
	trans["disabled"] = "wyłączony"
	trans["invalid"] = "nieprawidłowy"
	trans["usage_plugin_enable"] = "Użycie: hacker plugin enable <nazwa>"
	trans["plugin_not_found"] = "Plugin nie znaleziono"
	trans["enabled_plugin"] = "Włączono plugin"
	trans["usage_plugin_disable"] = "Użycie: hacker plugin disable <nazwa>"
	trans["disabled_plugin"] = "Wyłączono plugin"
	trans["unknown_plugin"] = "Nieznana podkomenda plugin:"
	trans["plugin_subcommands"] = "Podkomendy plugin:"
	trans["list_desc"] = "Lista pluginów"
	trans["enable_desc"] = "Włącz plugin"
	trans["disable_desc"] = "Wyłącz plugin"
	trans["enabled_motd"] = "Włączono MOTD"
	trans["enabled_special_motd"] = "Włączono specjalne MOTD"
	trans["unknown_enable"] = "Nieznana podkomenda enable:"
	trans["enable_subcommands"] = "Podkomendy enable:"
	trans["motd_desc"] = "Włącz MOTD"
	trans["special_motd_desc"] = "Włącz specjalne MOTD"
	trans["disabled_motd"] = "Wyłączono MOTD"
	trans["unknown_disable"] = "Nieznana podkomenda disable:"
	trans["disable_subcommands"] = "Podkomendy disable:"
	trans["current_language"] = "Aktualny język:"
	trans["language_set"] = "Ustawiono język na"
	trans["unsupported_language"] = "Nieobsługiwany język:"
	trans["supported"] = "Obsługiwane:"
	trans["unknown_settings"] = "Nieznana podkomenda settings:"
	trans["settings_subcommands"] = "Podkomendy settings:"
	trans["language_desc"] = "Ustaw lub pokaż język"
	trans["tool_title"] = "Narzędzie Hacker:"
	trans["desc_unpack"] = "Rozpakuj pakiety"
	trans["desc_pack"] = "Spakuj pakiety"
	trans["desc_env"] = "Zarządzaj środowiskami"
	trans["desc_help"] = "Pomoc"
	trans["desc_help_ui"] = "Pomoc UI"
	trans["desc_docs"] = "Dokumentacja"
	trans["desc_install"] = "Instaluj pakiety"
	trans["desc_remove"] = "Usuń pakiety"
	trans["desc_flatpak_install"] = "Instaluj flatpak"
	trans["desc_flatpak_remove"] = "Usuń flatpak"
	trans["desc_system"] = "Komendy systemowe"
	trans["desc_run"] = "Uruchom"
	trans["desc_update"] = "Aktualizuj"
	trans["desc_game"] = "Gra tekstowa"
	trans["desc_hacker_lang"] = "Info o Hacker Lang"
	trans["desc_ascii"] = "Pokaż ASCII art"
	trans["desc_shell"] = "Interaktywna wersja narzędzia hacker"
	trans["desc_enter"] = "Wejdź do kontenera"
	trans["desc_remove_container"] = "Usuń kontener"
	trans["desc_restart"] = "Restart usługi"
	trans["desc_plugin"] = "Zarządzaj pluginami"
	trans["desc_enable"] = "Włącz funkcje"
	trans["desc_disable"] = "Wyłącz funkcje"
	trans["desc_how_to"] = "Jak tworzyć komendy"
	trans["desc_index"] = "Indeks narzędzi"
	trans["desc_info"] = "Info o wersji"
	trans["desc_issue"] = "Zgłoś issue"
	trans["desc_repair"] = "Napraw system"
	trans["desc_settings"] = "Ustawienia"
	trans["custom_commands"] = "Niestandardowe komendy:"
	trans["no_description"] = "Brak opisu"
	trans["invalid_config"] = "Nieprawidłowa konfiguracja"
	trans["plugins_title"] = "Pluginy:"
	trans["hacker_lang_info1"] = "Hacker Lang info 1"
	trans["hacker_lang_info2"] = "Hacker Lang info 2"

	// Translations from unpack
	trans["unpack_downloading"] = "Pobieranie"
	trans["unpack_done"] = "Zakończono"
	trans["unpack_blackarch_info1"] = "Info BlackArch 1"
	trans["unpack_blackarch_info2"] = "Info BlackArch 2"
	trans["unpack_roblox_done"] = "Roblox zainstalowano"
	trans["unpack_alacritty_done"] = "Konfiguracja Alacritty zakończona"
	trans["unpack_hydra_warning"] = "Ostrzeżenie Hydra"
	trans["unpack_title"] = "Rozpakuj:"
	trans["unpack_install"] = "Instaluj HackerLand"
	trans["unpack_add_ons"] = "Dodatki"
	trans["unpack_gs"] = "GS"
	trans["unpack_devtools"] = "Narzędzia deweloperskie"
	trans["unpack_emulators"] = "Emulatory"
	trans["unpack_cybersecurity"] = "Cyberbezpieczeństwo"
	trans["unpack_select"] = "Wybierz"
	trans["unpack_gaming"] = "Gaming"
	trans["unpack_gaming_roblox"] = "Gaming z Roblox"
	trans["unpack_hacker_mode"] = "Tryb hackera"
	trans["unpack_gamescope"] = "Gamescope session steam"
	trans["unpack_xanmod"] = "Xanmod"
	trans["unpack_liquorix"] = "Liquorix"
	trans["unpack_auto_updates"] = "Automatyczne aktualizacje"
	trans["unpack_alacritty"] = "Konfiguracja Alacritty"
	trans["unpack_hackeros_tv"] = "HackerOS TV"
	trans["unpack_security_mode"] = "Tryb bezpieczeństwa"
	trans["unpack_winboat"] = "Winboat"
	trans["unpack_nvidia"] = "Sterowniki Nvidia"
	trans["unpack_hl_utils"] = "HL utils"
	trans["unpack_flox"] = "Flox"
	trans["unpack_builder"] = "Builder"
	trans["unpack_isolator"] = "Isolator"
	trans["unpack_hydra"] = "Hydra"
	trans["unpack_hammer"] = "Hammer"
	trans["unpack_hackerland"] = "HackerLand"
	trans["unpack_hsharp"] = "H#"

	// Translations from pack
	trans["pack_downloading"] = "Usuwanie"
	trans["pack_full_done"] = "Pełne usunięcie zakończone"
	trans["pack_alacritty_done"] = "Konfiguracja Alacritty usunięta"
	trans["pack_done"] = "Zakończono"
	trans["pack_unknown"] = "Nieznana podkomenda pack:"
	trans["pack_title"] = "Spakuj:"
	trans["pack_install"] = "Usuń HackerLand"
	trans["pack_add_ons"] = "Usuń dodatki"
	trans["pack_gs"] = "Usuń GS"
	trans["pack_devtools"] = "Usuń narzędzia deweloperskie"
	trans["pack_emulators"] = "Usuń emulatory"
	trans["pack_cybersecurity"] = "Usuń cybersecurity"
	trans["pack_select"] = "Wybierz do usunięcia"
	trans["pack_gaming"] = "Usuń gaming"
	trans["pack_hacker_mode"] = "Usuń tryb hackera"
	trans["pack_gamescope"] = "Usuń gamescope session steam"
	trans["pack_xanmod"] = "Usuń Xanmod"
	trans["pack_liquorix"] = "Usuń Liquorix"
	trans["pack_auto_updates"] = "Usuń automatyczne aktualizacje"
	trans["pack_alacritty"] = "Usuń konfigurację Alacritty"
	trans["pack_hackeros_tv"] = "Usuń HackerOS TV"
	trans["pack_security_mode"] = "Usuń tryb bezpieczeństwa"
	trans["pack_winboat"] = "Usuń Winboat"
	trans["pack_nvidia"] = "Usuń sterowniki Nvidia"
	trans["pack_hl_utils"] = "Usuń HL utils"
	trans["pack_flox"] = "Usuń Flox"
	trans["pack_builder"] = "Usuń builder"
	trans["pack_isolator"] = "Usuń isolator"
	trans["pack_hammer"] = "Usuń hammer"
	trans["pack_hackerland"] = "Usuń HackerLand"
	trans["pack_hsharp"] = "Usuń H#"
	return trans
}
