package hackeros

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:mem"

main :: proc() {
	lang := load_lang()
	trans := get_translations_main(lang)
	style_file := get_config_path("style.css")
	load_styles(style_file)

	args := os.args[1:]
	if len(args) == 0 || args[0] == "help" {
		show_main_help(lang)
		os.exit(0)
	}

	command := args[0]
	rest := args[1:]

	switch command {
		case "unpack":
			handle_unpack(rest, lang)
		case "pack":
			handle_pack(rest, lang)
		case "env":
			handle_env(rest, lang)
		case "help-ui":
			safe_run("~/.hackeros/hacker/hacker-help")
		case "docs":
			safe_run("~/.hackeros/hacker/hacker-docs")
		case "install":
			if len(rest) == 0 {
				print_error("%s", trans["usage_install"])
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("~/.hackeros/hacker/apt-fronted install %s", pkg))
		case "remove":
			if len(rest) == 0 {
				print_error("%s", trans["usage_remove"])
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("~/.hackeros/hacker/apt-fronted remove %s", pkg))
		case "flatpak-install":
			if len(rest) == 0 {
				print_error("%s", trans["usage_flatpak_install"])
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("flatpak install -y %s", pkg))
		case "flatpak-remove":
			if len(rest) == 0 {
				print_error("%s", trans["usage_flatpak_remove"])
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("flatpak remove -y %s", pkg))
		case "system":
			handle_system(rest, lang)
		case "run":
			handle_run(rest, lang)
		case "update":
			handle_update(rest, lang)
		case "game":
			play_text_game()
		case "hacker-lang":
			fmt.printfln("%s%s%s", Colors.yellow, trans["hacker_lang_info1"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.yellow, trans["hacker_lang_info2"], Colors.reset)
		case "ascii":
			safe_run("cat /usr/share/HackerOS/Config-Files/HackerOS-Ascii")
		case "shell":
			safe_run("source /usr/lib/HackerOS/venv/bin/activate && ~/.hackeros/hacker/hacker-shell")
		case "enter":
			if len(rest) == 0 {
				print_error("%s", trans["usage_enter"])
				os.exit(1)
			}
			safe_run(fmt.tprintf("distrobox enter %s", rest[0]))
		case "remove-container":
			if len(rest) == 0 {
				print_error("%s", trans["usage_remove_container"])
				os.exit(1)
			}
			safe_run(fmt.tprintf("distrobox rm %s", rest[0]))
		case "restart":
			if len(rest) == 0 {
				print_error("%s", trans["usage_restart"])
				os.exit(1)
			}
			safe_run(fmt.tprintf("sudo systemctl restart %s", rest[0]))
		case "plugin":
			handle_plugin(rest, lang)
		case "enable":
			handle_enable(rest, lang)
		case "disable":
			handle_disable(rest, lang)
		case "how-to-create-commands":
			fmt.printfln("%s%s%s", Colors.yellow, trans["how_to_create1"], Colors.reset)
			fmt.println(trans["how_to_create2"])
			fmt.println(trans["how_to_create3"])
		case "index":
			show_hackeros_tools(lang)
		case "--version":
			fmt.printfln("%s%s%s", Colors.green, trans["version_tool"], Colors.reset)
		case "--hackeros":
			fmt.printfln("%s%s%s", Colors.green, trans["version_os"], Colors.reset)
		case "--edition":
			file_path :: "/etc/xdg/kcm-about-distrorc"
			data, err := os.read_entire_file(file_path, context.allocator)
			if err != nil {
				print_error("%s %s", trans["file_not_found"], file_path)
				os.exit(1)
			}
			content := string(data)
			variant := ""
			for line in strings.split_lines_iterator(&content) {
				if strings.has_prefix(line, "Variant=") {
					variant = line[len("Variant="):]
					break
				}
			}
			if variant != "" {
				fmt.printfln("%s%s%s", Colors.green, variant, Colors.reset)
			} else {
				print_error("%s", trans["variant_not_found"])
			}
		case "info":
			fmt.printfln("%s%s%s", Colors.green, trans["version_tool"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.green, trans["version_os"], Colors.reset)
		case "issue":
			browser := "xdg-open"
			if path_exists("/usr/bin/vivaldi") { browser = "vivaldi" }
			safe_run(fmt.tprintf("%s https://github.com/HackerOS-Linux-System/HackerOS-Website/issues/new", browser))
		case "repair":
			repair_path, _ := filepath.join([]string{get_home(), ".hackeros/hacker/hacker-repair"}, context.allocator)
			safe_run(repair_path)
		case "settings":
			handle_settings(rest, lang)
		case "switch":
			handle_switch(rest, lang)
		case:
			// Try custom command
			custom_file := get_custom_command_path(command)
			if path_exists(custom_file) {
				config, ok := parse_hacker_file(custom_file)
				if ok {
					if exec_cmd, has := config["exec"]; has {
						arg_str := strings.join(rest, " ")
						safe_run(fmt.tprintf("%s %s", exec_cmd, arg_str))
					} else {
						print_error("%s", trans["no_exec_custom"])
						os.exit(1)
					}
				} else {
					print_error("%s", trans["error_custom"])
					os.exit(1)
				}
			} else if !try_plugin_command(command, rest, lang) {
				print_error("Unknown command -> %s", command)
				os.exit(1)
			}
	}
}

// ====================== FUNKCJE OBSŁUGI SWITCH ======================

handle_switch :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		show_switch_help(lang)
		os.exit(0)
	}

	switch args[0] {
		case "hacker-mode":
			handle_hacker_mode_switch(lang)
		case "steam-gamemode":
			handle_steam_gamemode_switch(lang)
		case:
			print_error("Unknown switch subcommand -> %s", args[0])
			show_switch_help(lang)
			os.exit(1)
	}
}

show_switch_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["switch_subcommands"], Colors.reset)
	fmt.printfln(" %shacker-mode %s- %s", Colors.gray, Colors.reset, trans["hacker_mode_desc"])
	fmt.printfln(" %ssteam-gamemode %s- %s", Colors.gray, Colors.reset, trans["steam_gamemode_desc"])
}

// Główna logika przełączania na Hacker-Mode
handle_hacker_mode_switch :: proc(lang: string) {
	trans := get_translations_main(lang)

	session_file := "/usr/share/wayland-sessions/Hacker-Mode.desktop"

	// 1. Sprawdzenie czy plik .desktop istnieje
	if !path_exists(session_file) {
		print_error("Plik %s nie został znaleziony!", session_file)
		print_warning("Zainstaluj go za pomocą: hacker unpack hacker-mode")
		os.exit(1)
	}

	// 2. Detekcja aktualnego środowiska graficznego
	de_env := ""
	if v := os.get_env_alloc("XDG_CURRENT_DESKTOP", context.temp_allocator); v != "" {
		de_env = v
	} else if v := os.get_env_alloc("DESKTOP_SESSION", context.temp_allocator); v != "" {
		de_env = v
	}

	de_env_lower := strings.to_lower(de_env)

	current_de := ""
	if strings.contains(de_env_lower, "plasma") || strings.contains(de_env_lower, "kde") {
		current_de = "plasma-desktop"
	} else if strings.contains(de_env_lower, "gnome") {
		current_de = "gnome"
	} else if strings.contains(de_env_lower, "xfce") {
		current_de = "xfce4"
	}

	if current_de == "" {
		print_error("Nie wykryto obsługiwanego środowiska (plasma-desktop / gnome / xfce4).")
		os.exit(1)
	}

	fmt.printfln("%sWykryto środowisko: %s. Wyłączam je...%s", Colors.yellow, current_de, Colors.reset)

	// 3. Wyłączenie aktualnego środowiska graficznego
	switch current_de {
		case "plasma-desktop":
			safe_run("killall -9 plasmashell kwin_wayland kwin_x11 krunner kded5")
		case "gnome":
			safe_run("killall -9 gnome-shell")
		case "xfce4":
			safe_run("killall -9 xfce4-session xfwm4 xfdesktop")
	}

	// 4. Detekcja Display Managera
	dm := detect_display_manager()

	if strings.contains(dm, "lightdm") || strings.contains(dm, "sddm") || strings.contains(dm, "gdm") || strings.contains(dm, "gdm3") {
		fmt.printfln("%sWykryto DM: %s. Uruchamiam sesję Hacker-Mode...%s", Colors.green, dm, Colors.reset)

		exec_cmd := get_desktop_exec(session_file)
		if exec_cmd != "" {
			safe_run(exec_cmd)
		} else {
			print_error("Nie znaleziono linii Exec= w pliku .desktop.")
		}
	} else {
		print_warning("DM (%s) nie jest jednym z lightdm/sddm/gdm. Środowisko wyłączone – zaloguj się ponownie i wybierz Hacker-Mode ręcznie.", dm)
	}
}

// Przełączanie na Steam GameMode (gamescope-session)
handle_steam_gamemode_switch :: proc(lang: string) {
	trans := get_translations_main(lang)

	session_file := "/usr/share/wayland-sessions/gamescope-session-steam.desktop"

	if !path_exists(session_file) {
		print_error("Plik %s nie został znaleziony!", session_file)
		print_warning("Zainstaluj go za pomocą: hacker unpack gamescope-session-steam")
		os.exit(1)
	}

	de_env := ""
	if v := os.get_env_alloc("XDG_CURRENT_DESKTOP", context.temp_allocator); v != "" {
		de_env = v
	} else if v := os.get_env_alloc("DESKTOP_SESSION", context.temp_allocator); v != "" {
		de_env = v
	}

	de_env_lower := strings.to_lower(de_env)

	current_de := ""
	if strings.contains(de_env_lower, "plasma") || strings.contains(de_env_lower, "kde") {
		current_de = "plasma-desktop"
	} else if strings.contains(de_env_lower, "gnome") {
		current_de = "gnome"
	} else if strings.contains(de_env_lower, "xfce") {
		current_de = "xfce4"
	}

	if current_de == "" {
		print_error("Nie wykryto obsługiwanego środowiska (plasma-desktop / gnome / xfce4).")
		os.exit(1)
	}

	fmt.printfln("%sWykryto środowisko: %s. Wyłączam je...%s", Colors.yellow, current_de, Colors.reset)

	switch current_de {
		case "plasma-desktop":
			safe_run("killall -9 plasmashell kwin_wayland kwin_x11 krunner kded5")
		case "gnome":
			safe_run("killall -9 gnome-shell")
		case "xfce4":
			safe_run("killall -9 xfce4-session xfwm4 xfdesktop")
	}

	dm := detect_display_manager()

	if strings.contains(dm, "lightdm") || strings.contains(dm, "sddm") || strings.contains(dm, "gdm") || strings.contains(dm, "gdm3") {
		fmt.printfln("%sWykryto DM: %s. Uruchamiam sesję Steam GameMode...%s", Colors.green, dm, Colors.reset)

		exec_cmd := get_desktop_exec(session_file)
		if exec_cmd != "" {
			safe_run(exec_cmd)
		} else {
			print_error("Nie znaleziono linii Exec= w pliku .desktop.")
		}
	} else {
		print_warning("DM (%s) nie jest jednym z lightdm/sddm/gdm. Środowisko wyłączone – zaloguj się ponownie i wybierz Steam GameMode ręcznie.", dm)
	}
}

// ====================== FUNKCJE POMOCNICZE SWITCH ======================

detect_display_manager :: proc() -> string {
	dm_file := "/etc/X11/default-display-manager"
	if path_exists(dm_file) {
		data, err := os.read_entire_file(dm_file, context.allocator)
		if err == nil {
			return filepath.base(strings.trim_space(string(data)))
		}
	}
	return "unknown"
}

get_desktop_exec :: proc(path: string) -> string {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		return ""
	}
	content := string(data)
	for line in strings.split_lines_iterator(&content) {
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, "Exec=") {
			return strings.trim_prefix(trimmed, "Exec=")
		}
	}
	return ""
}

// ====================== POZOSTAŁE FUNKCJE ======================

handle_system :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["system_subcommands"], Colors.reset)
		fmt.printfln(" %slogs %s- %s", Colors.gray, Colors.reset, trans["logs_desc"])
		os.exit(0)
	}
	switch args[0] {
		case "logs":
			safe_run("journalctl -xe")
		case:
			print_error("Unknown system subcommand -> %s", args[0])
			os.exit(1)
	}
}

handle_update :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		safe_run("~/.hackeros/hacker/HackerOS-Updater")
	} else {
		switch args[0] {
			case "--with-gui":
				safe_run("~/.hackeros/hacker/update-system")
			case:
				print_error("Unknown flag for update -> %s", args[0])
				fmt.println(trans["available_flags"])
				os.exit(1)
		}
	}
}

show_hackeros_tools :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["tools_index"], Colors.reset)
	// Zaktualizowana lista narzędzi
	fmt.printfln(" %s* bit%s - %s", Colors.green, Colors.reset, trans["tool_bit"])
	fmt.printfln(" %s* virus%s - %s", Colors.green, Colors.reset, trans["tool_virus"])
	fmt.printfln(" %s* bytes%s - %s", Colors.green, Colors.reset, trans["tool_bytes"])
	fmt.printfln(" %s* hl%s - %s", Colors.green, Colors.reset, trans["tool_hl"])
	fmt.printfln(" %s* hackerc%s - %s", Colors.green, Colors.reset, trans["tool_hackerc"])
	fmt.printfln(" %s* hacker%s - %s", Colors.green, Colors.reset, trans["tool_hacker"])
	fmt.printfln(" %s* Hacker Kernel%s - %s", Colors.green, Colors.reset, trans["tool_kernel"])
	fmt.printfln(" %s* HackerOS Steam%s - %s", Colors.green, Colors.reset, trans["tool_steam"])
	fmt.printfln(" %s* HackerOS Welcome%s - %s", Colors.green, Colors.reset, trans["tool_welcome"])
	fmt.printfln(" %s* HackerOS App%s - %s", Colors.green, Colors.reset, trans["tool_app"])
	fmt.printfln(" %s* Hacker Mode%s - %s", Colors.green, Colors.reset, trans["tool_hacker_mode"])
	fmt.printfln(" %s* isolator%s - %s", Colors.green, Colors.reset, trans["tool_isolator"])
	fmt.printfln(" %s* hpm%s - %s", Colors.green, Colors.reset, trans["tool_hpm"])
	fmt.printfln(" %s* HackerOS Game Mode%s - %s", Colors.green, Colors.reset, trans["tool_game_mode"])
	fmt.printfln(" %s* hup%s - %s", Colors.green, Colors.reset, trans["tool_hup"])
	fmt.printfln(" %s* hammer%s - %s", Colors.green, Colors.reset, trans["tool_hammer"])
	fmt.printfln(" %s* HackerOS Games%s - %s", Colors.green, Colors.reset, trans["tool_games"])
	fmt.printfln(" %s* HackerOS Cockpit (archiwum)%s - %s", Colors.green, Colors.reset, trans["tool_cockpit"])
	fmt.printfln(" %s* Hacker Launcher%s - %s", Colors.green, Colors.reset, trans["tool_launcher"])
	fmt.printfln(" %s* lpm%s - %s", Colors.green, Colors.reset, trans["tool_lpm"])
	fmt.printfln(" %s* hedit%s - %s", Colors.green, Colors.reset, trans["tool_hedit"])
	fmt.printfln(" %s* ngt%s - %s", Colors.green, Colors.reset, trans["tool_ngt"])
	fmt.printfln(" %s* hbuild%s - %s", Colors.green, Colors.reset, trans["tool_hbuild"])
	fmt.printfln(" %s* HackerDeck%s - %s", Colors.green, Colors.reset, trans["tool_hackerdeck"])
	fmt.printfln(" %s* Hacker Term%s - %s", Colors.green, Colors.reset, trans["tool_hackerterm"])
	fmt.printfln(" %s* HackerOS Store%s - %s", Colors.green, Colors.reset, trans["tool_store"])
	fmt.printfln(" %s* hsh%s - %s", Colors.green, Colors.reset, trans["tool_hsh"])
	fmt.printfln(" %s* getit%s - %s", Colors.green, Colors.reset, trans["tool_getit"])
	fmt.printfln(" %s* HackerOS Builder%s - %s", Colors.green, Colors.reset, trans["tool_builder"])
	fmt.printfln(" %s* HexAi%s - %s", Colors.green, Colors.reset, trans["tool_hexai"])
	fmt.printfln(" %s* chker%s - %s", Colors.green, Colors.reset, trans["tool_chker"])
	fmt.printfln(" %s* anvil%s - %s", Colors.green, Colors.reset, trans["tool_anvil"])
	fmt.printfln(" %s* Blue Environment (BETA - niestabilne)%s - %s", Colors.green, Colors.reset, trans["tool_blue"])
}

handle_plugin :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		show_plugin_help(lang)
		os.exit(0)
	}
	switch args[0] {
		case "list":
			fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["plugins"], Colors.reset)
			plugin_dir := get_plugin_dir()
			for f in glob_dir(plugin_dir, ".hacker") {
				config, ok := parse_hacker_file(f)
				name := filepath.base(f)
				name = strings.trim_suffix(name, ".hacker")
				if ok {
					if n, has := config["name"]; has { name = n }
					enabled := config["enabled"] == "true"
					if enabled {
						fmt.printfln(" %s - %s%s%s", name, Colors.green, trans["enabled"], Colors.reset)
					} else {
						fmt.printfln(" %s - %s%s%s", name, Colors.red, trans["disabled"], Colors.reset)
					}
				} else {
					fmt.printfln(" %s - %s%s%s", name, Colors.red, trans["invalid"], Colors.reset)
				}
			}
		case "enable":
			if len(args) < 2 {
				print_error("%s", trans["usage_plugin_enable"])
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				print_error("%s", trans["plugin_not_found"])
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if ok {
				config["enabled"] = "true"
				write_hacker_file(plugin_file, config)
				fmt.printfln("%s%s '%s'.%s", Colors.green, trans["enabled_plugin"], args[1], Colors.reset)
			}
		case "disable":
			if len(args) < 2 {
				print_error("%s", trans["usage_plugin_disable"])
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				print_error("%s", trans["plugin_not_found"])
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if ok {
				config["enabled"] = "false"
				write_hacker_file(plugin_file, config)
				fmt.printfln("%s%s '%s'.%s", Colors.green, trans["disabled_plugin"], args[1], Colors.reset)
			}
		case:
			print_error("Unknown plugin subcommand -> %s", args[0])
			show_plugin_help(lang)
			os.exit(1)
	}
}

show_plugin_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["plugin_subcommands"], Colors.reset)
	fmt.printfln(" %slist %s- %s", Colors.gray, Colors.reset, trans["list_desc"])
	fmt.printfln(" %senable %s- %s", Colors.gray, Colors.reset, trans["enable_desc"])
	fmt.printfln(" %sdisable %s- %s", Colors.gray, Colors.reset, trans["disable_desc"])
}

handle_enable :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		show_enable_help(lang)
		os.exit(0)
	}
	switch args[0] {
		case "motd":
			safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-motd /usr/libexec/")
			safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
			fmt.printfln("%s%s%s", Colors.green, trans["enabled_motd"], Colors.reset)
		case "special-motd":
			safe_run("sudo cp -r /usr/share/HackerOS/Archived/hackeros-special-motd /usr/libexec/hackeros-motd")
			safe_run("sudo chmod a+x /usr/libexec/hackeros-motd")
			fmt.printfln("%s%s%s", Colors.green, trans["enabled_special_motd"], Colors.reset)
		case:
			print_error("Unknown enable subcommand -> %s", args[0])
			show_enable_help(lang)
			os.exit(1)
	}
}

show_enable_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["enable_subcommands"], Colors.reset)
	fmt.printfln(" %smotd %s- %s", Colors.gray, Colors.reset, trans["motd_desc"])
	fmt.printfln(" %sspecial-motd %s- %s", Colors.gray, Colors.reset, trans["special_motd_desc"])
}

handle_disable :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		show_disable_help(lang)
		os.exit(0)
	}
	switch args[0] {
		case "motd", "special-motd":
			safe_run("sudo rm -rf /usr/libexec/hackeros-motd")
			fmt.printfln("%s%s%s", Colors.green, trans["disabled_motd"], Colors.reset)
		case:
			print_error("Unknown disable subcommand -> %s", args[0])
			show_disable_help(lang)
			os.exit(1)
	}
}

show_disable_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["disable_subcommands"], Colors.reset)
	fmt.printfln(" %smotd %s- %s", Colors.gray, Colors.reset, trans["motd_desc"])
	fmt.printfln(" %sspecial-motd %s- %s", Colors.gray, Colors.reset, trans["special_motd_desc"])
}

// ====================== POPRAWIONA FUNKCJA handle_settings ======================

handle_settings :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	supported_languages := []string{"pl","en","de","fr","es","it","ru","zh","ja","ko","pt","ar","hi"}
	if len(args) == 0 {
		show_settings_help(lang)
		os.exit(0)
	}
	switch args[0] {
		case "language":
			if len(args) < 2 {
				current := load_lang()
				fmt.printfln("%s%s %s%s", Colors.green, trans["current_language"], current, Colors.reset)
				os.exit(0)
			}
			new_lang := strings.to_lower(args[1])
			found := false
			for sl in supported_languages {
				if sl == new_lang { found = true; break }
			}
			if found {
				save_language(new_lang)
				fmt.printfln("%s%s %s.%s", Colors.green, trans["language_set"], new_lang, Colors.reset)
				os.exit(0) // <- KLUCZOWE: kończy program, aby nowy język został załadowany przy następnym uruchomieniu
			} else {
				print_error("%s %s. %s %s", trans["unsupported_language"], new_lang, trans["supported"], strings.join(supported_languages, ", "))
				os.exit(1)
			}
		case:
			print_error("Unknown settings subcommand -> %s", args[0])
			show_settings_help(lang)
			os.exit(1)
	}
}

show_settings_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["settings_subcommands"], Colors.reset)
	fmt.printfln(" %slanguage [ ] %s- %s", Colors.gray, Colors.reset, trans["language_desc"])
}

show_main_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["tool_title"], Colors.reset)
	cmds := [][2]string{
		{"unpack", trans["desc_unpack"]},
		{"pack", trans["desc_pack"]},
		{"env", trans["desc_env"]},
		{"help", trans["desc_help"]},
		{"help-ui",trans["desc_help_ui"]},
		{"docs", trans["desc_docs"]},
		{"install ", trans["desc_install"]},
		{"remove ", trans["desc_remove"]},
		{"flatpak-install ", trans["desc_flatpak_install"]},
		{"flatpak-remove ", trans["desc_flatpak_remove"]},
		{"system", trans["desc_system"]},
		{"run", trans["desc_run"]},
		{"update [ --with-gui ]", trans["desc_update"]},
		{"game", trans["desc_game"]},
		{"hacker-lang", trans["desc_hacker_lang"]},
		{"ascii", trans["desc_ascii"]},
		{"shell", trans["desc_shell"]},
		{"enter ", trans["desc_enter"]},
		{"remove-container ",trans["desc_remove_container"]},
		{"restart ", trans["desc_restart"]},
		{"plugin", trans["desc_plugin"]},
		{"enable", trans["desc_enable"]},
		{"disable",trans["desc_disable"]},
		{"how-to-create-commands", trans["desc_how_to"]},
		{"index", trans["desc_index"]},
		{"info", trans["desc_info"]},
		{"issue", trans["desc_issue"]},
		{"repair", trans["desc_repair"]},
		{"settings", trans["desc_settings"]},
		{"switch", trans["desc_switch"]},
	}
	for c in cmds {
		fmt.printfln(" %s%s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
	// Custom commands
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["custom_commands"], Colors.reset)
	for f in glob_dir(get_custom_dir(), ".hacker") {
		name := strings.trim_suffix(filepath.base(f), ".hacker")
		config, ok := parse_hacker_file(f)
		if ok {
			desc := trans["no_description"]
			if d, has := config["description"]; has { desc = d }
			fmt.printfln(" %s%s %s- %s", Colors.gray, name, Colors.reset, desc)
		} else {
			fmt.printfln(" %s%s %s- %s", Colors.gray, name, Colors.reset, trans["invalid_config"])
		}
	}
	// Plugin commands
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["plugins_title"], Colors.reset)
	for f in glob_dir(get_plugin_dir(), ".hacker") {
		config, ok := parse_hacker_file(f)
		if !ok { continue }
		if config["enabled"] != "true" { continue }
		for k, v in config {
			if k == "enabled" || k == "name" { continue }
			fmt.printfln(" %s%s %s- %s", Colors.gray, k, Colors.reset, trans["no_description"])
		}
	}
}
