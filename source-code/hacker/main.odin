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
	// Załaduj look.json jeśli istnieje
	look_file := get_config_path("look.json")
	load_look_from_file(look_file)

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
		case "languages":
			handle_languages(lang)
		case "hacker-lang":
			// alias dla kompatybilności wstecznej
			handle_languages(lang)
		case "ascii":
			safe_run("cat /usr/share/HackerOS/Config-Files/HackerOS-Ascii")
		case "shell":
			safe_run("source /usr/lib/HackerOS/venv/bin/activate && ~/.hackeros/hacker/hacker-shell")
		case "interactive":
			// Nowa powłoka TUI oparta na Go + Bubble Tea
			interactive_bin := get_home_path(".hackeros/hacker/hacker-interactive")
			if path_exists(interactive_bin) {
				safe_run(interactive_bin)
			} else {
				print_error("%s", trans["interactive_not_found"])
				fmt.printfln("%s%s%s", Colors.yellow, trans["interactive_hint"], Colors.reset)
				os.exit(1)
			}
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
			fmt.printfln("%s%s%s", Colors.green, read_hackeros_version(), Colors.reset)
		case "--hackeros":
			fmt.printfln("%s%s%s", Colors.green, read_hackeros_version(), Colors.reset)
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
			fmt.printfln("%s%s%s", Colors.green, read_hackeros_version(), Colors.reset)
		case "issue":
			browser := "xdg-open"
			if path_exists("/usr/bin/vivaldi") { browser = "vivaldi" }
			safe_run(fmt.tprintf("%s https://github.com/HackerOS-Linux-System/HackerOS-Website/issues/new", browser))
		case "doctor":
			// Brama do narzędzia repair — wymagana jako pierwszy krok
			handle_doctor(lang)
		case "repair":
			// repair dostępny tylko po przejściu przez doctor
			// Bezpośrednie wywołanie hacker repair wyświetla komunikat o konieczności użycia doctor
			fmt.printfln("%s%s%s", Colors.yellow, trans["repair_use_doctor"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.cyan, trans["repair_doctor_hint"], Colors.reset)
		case "network":
			// Ukryta komenda — nie widoczna w help
			handle_network(lang)
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

// ─── Odczyt wersji HackerOS z pliku release-info.json ────────────────────────
//
// Format pliku /usr/share/HackerOS/Config-Files/release-info.json:
// { "version": "4.5 -> HackerOS 4.5" }
//
// Zwraca zawartość pola "version" lub fallback jeśli plik niedostępny.

RELEASE_INFO_PATH :: "/usr/share/HackerOS/Config-Files/release-info.json"

read_hackeros_version :: proc() -> string {
	data, err := os.read_entire_file(RELEASE_INFO_PATH, context.allocator)
	if err != nil {
		// Plik niedostępny — wróć do wartości z tłumaczeń
		return "HackerOS (wersja nieznana)"
	}

	content := string(data)

	// Prosta ekstrakcja wartości "version" bez biblioteki JSON
	// Szukamy: "version": "WARTOŚĆ"
	search := `"version"`
	idx := strings.index(content, search)
	if idx < 0 {
		return "HackerOS (błąd odczytu wersji)"
	}

	// Znajdź pierwszy cudzysłów po ":"
	rest := content[idx + len(search):]
	colon := strings.index(rest, ":")
	if colon < 0 {
		return "HackerOS (błąd odczytu wersji)"
	}

	rest = rest[colon + 1:]
	// Znajdź otwierający cudzysłów wartości
	open := strings.index(rest, `"`)
	if open < 0 {
		return "HackerOS (błąd odczytu wersji)"
	}

	rest = rest[open + 1:]
	// Znajdź zamykający cudzysłów
	close := strings.index(rest, `"`)
	if close < 0 {
		return "HackerOS (błąd odczytu wersji)"
	}

	version_str := rest[:close]

	// Plik zawiera np. "4.5 -> HackerOS 4.5"
	// Wyciągamy część po " -> " jeśli istnieje, inaczej cały string
	arrow := strings.index(version_str, " -> ")
	if arrow >= 0 {
		return strings.trim_space(version_str[arrow + 4:])
	}

	return strings.trim_space(version_str)
}

// ─── doctor ───────────────────────────────────────────────────────────────────

handle_doctor :: proc(lang: string) {
	trans := get_translations_main(lang)

	fmt.printfln("%s%s%s", Colors.bold, Colors.magenta, "╔══════════════════════════════════════╗")
	fmt.printfln("║   %sHackerOS Doctor%s — Diagnoza systemu    ║", Colors.cyan, Colors.magenta)
	fmt.printfln("╚══════════════════════════════════════╝%s", Colors.reset)
	fmt.println()

	fmt.printfln("%s%s%s", Colors.yellow, trans["doctor_intro"], Colors.reset)
	fmt.println()

	// Prosta diagnostyka przed uruchomieniem repair
	fmt.printfln("%s[1/4]%s %s", Colors.cyan, Colors.reset, trans["doctor_check_dpkg"])
	dpkg_ok := safe_run("dpkg --audit 2>&1 | head -5")
	if dpkg_ok {
		fmt.printfln("      %s✓ dpkg OK%s", Colors.green, Colors.reset)
	} else {
		fmt.printfln("      %s⚠ Wykryto problemy dpkg%s", Colors.yellow, Colors.reset)
	}

	fmt.printfln("%s[2/4]%s %s", Colors.cyan, Colors.reset, trans["doctor_check_disk"])
	safe_run("df -h / | tail -1")

	fmt.printfln("%s[3/4]%s %s", Colors.cyan, Colors.reset, trans["doctor_check_net"])
	net_ok := safe_run("ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1")
	if net_ok {
		fmt.printfln("      %s✓ Sieć OK%s", Colors.green, Colors.reset)
	} else {
		fmt.printfln("      %s⚠ Brak połączenia z internetem%s", Colors.yellow, Colors.reset)
	}

	fmt.printfln("%s[4/4]%s %s", Colors.cyan, Colors.reset, trans["doctor_check_services"])
	safe_run("systemctl is-failed --quiet 2>/dev/null && systemctl list-units --state=failed --no-pager 2>/dev/null | head -5 || echo 'Brak awarii usług'")

	fmt.println()
	fmt.printfln("%s%s%s", Colors.bold, trans["doctor_prompt"], Colors.reset)
	fmt.printfln("%s  y / t%s — %s", Colors.green, Colors.reset, trans["doctor_yes"])
	fmt.printfln("%s  n / q%s — %s", Colors.red, Colors.reset, trans["doctor_no"])
	fmt.print(fmt.tprintf("%s❯%s ", Colors.magenta, Colors.reset))

	buf: [8]u8
	n, _ := os.read(os.stdin, buf[:])
	answer := strings.to_lower(strings.trim_space(string(buf[:n])))

	if answer == "y" || answer == "t" || answer == "yes" || answer == "tak" {
		repair_bin := get_home_path(".hackeros/hacker/hacker-repair")
		if path_exists(repair_bin) {
			fmt.printfln("%s%s%s", Colors.green, trans["doctor_launching_repair"], Colors.reset)
			safe_run(repair_bin)
		} else {
			print_error("%s", trans["repair_not_found"])
			fmt.printfln("%s%s%s", Colors.yellow, trans["repair_install_hint"], Colors.reset)
		}
	} else {
		fmt.printfln("%s%s%s", Colors.gray, trans["doctor_cancelled"], Colors.reset)
	}
}

// ─── network (hidden) ─────────────────────────────────────────────────────────

handle_network :: proc(lang: string) {
	network_bin := get_home_path(".hackeros/hacker/hacker-network")
	if path_exists(network_bin) {
		safe_run(network_bin)
	} else {
		trans := get_translations_main(lang)
		print_error("%s", trans["network_not_found"])
		fmt.printfln("%s%s%s", Colors.yellow, trans["network_hint"], Colors.reset)
		os.exit(1)
	}
}

// ─── helper: get path relative to home ───────────────────────────────────────

get_home_path :: proc(rel: string) -> string {
	home := get_home()
	return strings.join([]string{home, rel}, "/")
}

// ─── switch ───────────────────────────────────────────────────────────────────

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

handle_hacker_mode_switch :: proc(lang: string) {
	trans := get_translations_main(lang)
	session_file := "/usr/share/wayland-sessions/Hacker-Mode.desktop"
	if !path_exists(session_file) {
		print_error("Plik %s nie został znaleziony!", session_file)
		print_warning("Zainstaluj go za pomocą: hacker unpack hacker-mode")
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
	if err != nil { return "" }
	content := string(data)
	for line in strings.split_lines_iterator(&content) {
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, "Exec=") {
			return strings.trim_prefix(trimmed, "Exec=")
		}
	}
	return ""
}

// ─── system ───────────────────────────────────────────────────────────────────

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
		run_plugin_update_hooks("pre_update")
		safe_run("~/.hackeros/hacker/HackerOS-Updater")
		run_plugin_update_hooks("post_update")
	} else {
		switch args[0] {
			case "--with-gui":
				run_plugin_update_hooks("pre_update")
				safe_run("~/.hackeros/hacker/HackerOS-Updater --with-gui")
				run_plugin_update_hooks("post_update")
			case:
				print_error("Unknown flag for update -> %s", args[0])
				fmt.println(trans["available_flags"])
				os.exit(1)
		}
	}
}

// ─── languages ────────────────────────────────────────────────────────────────

handle_languages :: proc(lang: string) {
	trans := get_translations_main(lang)
	// Nagłówek
	fmt.printfln("%s%s╔══════════════════════════════════════════════╗%s", Colors.bold, Colors.magenta, Colors.reset)
	fmt.printfln("%s%s║   HackerOS — Języki programowania ekosystemu  ║%s", Colors.bold, Colors.magenta, Colors.reset)
	fmt.printfln("%s%s╚══════════════════════════════════════════════╝%s", Colors.bold, Colors.magenta, Colors.reset)
	fmt.println()

	// Hacker Lang
	fmt.printfln("%s● Hacker Lang%s", Colors.cyan, Colors.reset)
	fmt.printfln("  %s%s%s", Colors.white, trans["lang_hackerlang_desc"], Colors.reset)
	fmt.println()
	fmt.printfln("  %s%s%s", Colors.gray, trans["lang_hackerlang_use"], Colors.reset)
	fmt.printfln("  %s%s%s", Colors.gray, trans["lang_hackerlang_shell"], Colors.reset)
	fmt.println()
	fmt.printfln("  %sNarzędzia:%s  hl, bytes", Colors.yellow, Colors.reset)
	fmt.printfln("  %sRozszerzenie:%s  .hl", Colors.yellow, Colors.reset)
	fmt.println()

	// H#
	fmt.printfln("%s● H# (H-Sharp)%s", Colors.cyan, Colors.reset)
	fmt.printfln("  %s%s%s", Colors.white, trans["lang_hsharp_desc"], Colors.reset)
	fmt.println()
	fmt.printfln("  %s%s%s", Colors.gray, trans["lang_hsharp_use"], Colors.reset)
	fmt.printfln("  %s%s%s", Colors.gray, trans["lang_hsharp_extern"], Colors.reset)
	fmt.println()
	fmt.printfln("  %sNarzędzia:%s  h#, hsc (H# compiler)", Colors.yellow, Colors.reset)
	fmt.printfln("  %sRozszerzenie:%s  .hsc", Colors.yellow, Colors.reset)
	fmt.println()

	// Dokumentacja
	fmt.printfln("%s%s%s", Colors.bold, trans["lang_docs_header"], Colors.reset)
	fmt.printfln("  %shttps://hackeros-linux-system.github.io/HackerOS-Website/tools-docs/index.html%s", Colors.cyan, Colors.reset)
	fmt.println()
	fmt.printfln("  %s%s%s", Colors.gray, trans["lang_docs_hint"], Colors.reset)
}

// ─── look.json loader ─────────────────────────────────────────────────────────

load_look_from_file :: proc(look_file: string) {
	if !path_exists(look_file) { return }
	data, err := os.read_entire_file(look_file, context.allocator)
	if err != nil { return }
	content := string(data)

	extract_hex :: proc(json: string, key: string) -> string {
		search := fmt.tprintf(`"%s":"`, key)
		idx := strings.index(json, search)
		if idx < 0 { return "" }
		start := idx + len(search)
		end := strings.index(json[start:], `"`)
		if end < 0 { return "" }
		return json[start:start+end]
	}

	make_ansi :: proc(hex: string) -> string {
		if len(hex) != 7 || hex[0] != '#' { return "" }
		r := parse_hex2(hex[1:3])
		g := parse_hex2(hex[3:5])
		b := parse_hex2(hex[5:7])
		return fmt.tprintf("\e[38;2;%d;%d;%dm", r, g, b)
	}

	apply :: proc(field: ^string, hex: string) {
		if ansi := make_ansi(hex); ansi != "" {
			field^ = ansi
		}
	}

	apply(&Colors.magenta, extract_hex(content, "accent"))
	apply(&Colors.green,   extract_hex(content, "success"))
	apply(&Colors.red,     extract_hex(content, "error"))
	apply(&Colors.yellow,  extract_hex(content, "warning"))
	apply(&Colors.cyan,    extract_hex(content, "info"))
	apply(&Colors.gray,    extract_hex(content, "dim"))
}

// ─── show_hackeros_tools ──────────────────────────────────────────────────────

show_hackeros_tools :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["tools_index"], Colors.reset)
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
	fmt.printfln(" %s* Blue Environment (BETA)%s - %s", Colors.green, Colors.reset, trans["tool_blue"])
	fmt.printfln(" %s* H# (H-Sharp)%s - %s", Colors.green, Colors.reset, trans["tool_hsharp"])
}

// ─── plugin ───────────────────────────────────────────────────────────────────
//
// Rozbudowany system pluginów HackerOS
//
// Format pliku ~/.config/hackeros/hacker/plugins/<nazwa>.hacker:
//
// [
// name > Mój Plugin
// version > 1.0.0
// description > Krótki opis
// author > Autor
// license > MIT
// enabled > false
// min_hacker_version > 2.3.0
//
// commands.mojkom.exec > /usr/bin/narzedzie
// commands.mojkom.description > Co robi ta komenda
// commands.mojkom.help > Szczegółowy opis
// commands.mojkom.args > <plik> [opcje]
// commands.mojkom.sudo > false
//
// hooks.pre_update > ~/scripts/przed-aktualizacja.sh
// hooks.post_update > ~/scripts/po-aktualizacji.sh
// hooks.on_enable > ~/scripts/przy-wlaczeniu.sh
// hooks.on_disable > ~/scripts/przy-wylaczeniu.sh
//
// depends > nmap, curl, git
// install > ~/scripts/zainstaluj-plugin.sh
// uninstall > ~/scripts/odinstaluj-plugin.sh
// ]

handle_plugin :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 {
		show_plugin_help(lang)
		os.exit(0)
	}
	switch args[0] {

		// ── list ──────────────────────────────────────────────────────────────
		case "list":
			all_files := glob_dir(get_plugin_dir(), ".hacker")
			if len(all_files) == 0 {
				fmt.printfln("%s%s%s", Colors.gray, trans["no_plugins_found"], Colors.reset)
				fmt.printfln("%s%s%s", Colors.gray, trans["plugins_dir_hint"], Colors.reset)
				os.exit(0)
			}
			fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["plugins"], Colors.reset)
			fmt.println()
			for f in all_files {
				config, ok := parse_hacker_file(f)
				name := strings.trim_suffix(filepath.base(f), ".hacker")
				if !ok {
					fmt.printfln("  %s✗ %-20s%s %s", Colors.red, name, Colors.reset, trans["invalid"])
					continue
				}
				if n, has := config["name"]; has { name = n }
				enabled := config["enabled"] == "true"
				ver, desc, author := "", "", ""
				if v, has := config["version"];     has { ver    = fmt.tprintf(" v%s", v) }
				if d, has := config["description"]; has { desc   = d }
				if a, has := config["author"];      has { author = fmt.tprintf(" [%s]", a) }
				cmd_count := 0
				for k, _ in config {
					if strings.has_prefix(k, "commands.") && strings.has_suffix(k, ".exec") {
						cmd_count += 1
					}
				}
				deps_ok := check_plugin_deps(config)
				sym := "✓"; scol := Colors.green
				if !enabled   { sym = "✗"; scol = Colors.red   }
				if !deps_ok   { sym = "⚠"; scol = Colors.yellow }
				fmt.printfln("  %s%s%s %s%s%s%s",
							 scol, sym, Colors.reset,
				 Colors.cyan, name, Colors.reset, ver)
				fmt.printfln("     %s%s", desc, Colors.reset)
				if author != "" { fmt.printfln("     %s%s%s", Colors.gray, author, Colors.reset) }
				fmt.printfln("     %s%d komend(y)%s", Colors.gray, cmd_count, Colors.reset)
				if !deps_ok {
					fmt.printfln("     %s⚠ %s%s", Colors.yellow, trans["plugin_missing_deps"], Colors.reset)
				}
				fmt.println()
			}

			// ── enable ────────────────────────────────────────────────────────────
		case "enable":
			if len(args) < 2 {
				print_error("%s", trans["usage_plugin_enable"])
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				print_error("%s '%s'", trans["plugin_not_found"], args[1])
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if !ok { print_error("%s", trans["invalid"]); os.exit(1) }
			if !check_plugin_deps(config) {
				fmt.printfln("%s⚠ %s%s", Colors.yellow, trans["plugin_missing_deps"], Colors.reset)
				if deps, has := config["depends"]; has {
					fmt.printfln("  %s%s%s", Colors.gray, deps, Colors.reset)
				}
			}
			config["enabled"] = "true"
			write_hacker_file(plugin_file, config)
			fmt.printfln("%s%s '%s'.%s", Colors.green, trans["enabled_plugin"], args[1], Colors.reset)
			if hook, has := config["hooks.on_enable"]; has && hook != "" {
				fmt.printfln("%s-> %s on_enable...%s", Colors.gray, trans["plugin_running_hook"], Colors.reset)
				safe_run(hook)
			}

			// ── disable ───────────────────────────────────────────────────────────
		case "disable":
			if len(args) < 2 {
				print_error("%s", trans["usage_plugin_disable"])
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				print_error("%s '%s'", trans["plugin_not_found"], args[1])
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if !ok { print_error("%s", trans["invalid"]); os.exit(1) }
			config["enabled"] = "false"
			write_hacker_file(plugin_file, config)
			fmt.printfln("%s%s '%s'.%s", Colors.green, trans["disabled_plugin"], args[1], Colors.reset)
			if hook, has := config["hooks.on_disable"]; has && hook != "" {
				fmt.printfln("%s-> %s on_disable...%s", Colors.gray, trans["plugin_running_hook"], Colors.reset)
				safe_run(hook)
			}

			// ── info ──────────────────────────────────────────────────────────────
		case "info":
			if len(args) < 2 {
				print_error("%s", trans["usage_plugin_info"])
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				print_error("%s '%s'", trans["plugin_not_found"], args[1])
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if !ok { print_error("%s", trans["invalid"]); os.exit(1) }

			fmt.printfln("%s%s╔══ Plugin: %s ══%s", Colors.bold, Colors.magenta, args[1], Colors.reset)
			if n, has := config["name"];        has { fmt.printfln("  %sNazwa:%s       %s", Colors.cyan, Colors.reset, n) }
			if v, has := config["version"];     has { fmt.printfln("  %sWersja:%s      %s", Colors.cyan, Colors.reset, v) }
			if d, has := config["description"]; has { fmt.printfln("  %sOpis:%s        %s", Colors.cyan, Colors.reset, d) }
			if a, has := config["author"];      has { fmt.printfln("  %sAutor:%s       %s", Colors.cyan, Colors.reset, a) }
			if l, has := config["license"];     has { fmt.printfln("  %sLicencja:%s    %s", Colors.cyan, Colors.reset, l) }
			if mv, has := config["min_hacker_version"]; has {
				fmt.printfln("  %sMin. hacker:%s %s", Colors.cyan, Colors.reset, mv)
			}
			enabled := config["enabled"] == "true"
			scol := Colors.red; sstr := "wyłączony"
			if enabled { scol = Colors.green; sstr = "włączony" }
			fmt.printfln("  %sStatus:%s      %s%s%s", Colors.cyan, Colors.reset, scol, sstr, Colors.reset)
			if deps, has := config["depends"]; has {
				dok := check_plugin_deps(config)
				dc := Colors.green; if !dok { dc = Colors.yellow }
				fmt.printfln("  %sZależności:%s  %s%s%s", Colors.cyan, Colors.reset, dc, deps, Colors.reset)
			}
			fmt.println()
			// Komendy
			has_cmds := false
			for k, v in config {
				if strings.has_prefix(k, "commands.") && strings.has_suffix(k, ".exec") {
					if !has_cmds {
						fmt.printfln("  %sKomendy:%s", Colors.yellow, Colors.reset)
						has_cmds = true
					}
					cmd_name := k[len("commands."):]
					cmd_name = cmd_name[:len(cmd_name)-len(".exec")]
					desc := ""; if d, h := config[fmt.tprintf("commands.%s.description", cmd_name)]; h { desc = d }
					help := ""; if h, hh := config[fmt.tprintf("commands.%s.help", cmd_name)]; hh { help = h }
					cargs := ""; if a, ha := config[fmt.tprintf("commands.%s.args", cmd_name)]; ha { cargs = fmt.tprintf(" <%s>", a) }
					sudo := ""; if s, hs := config[fmt.tprintf("commands.%s.sudo", cmd_name)]; hs && s == "true" { sudo = " [sudo]" }
					fmt.printfln("    %shacker %s%s%s%s%s", Colors.cyan, cmd_name, cargs, sudo, Colors.reset, "")
					fmt.printfln("    %s exec:%s  %s", Colors.gray, Colors.reset, v)
					if desc != "" { fmt.printfln("    %s desc:%s  %s", Colors.gray, Colors.reset, desc) }
					if help != "" { fmt.printfln("    %s help:%s  %s", Colors.gray, Colors.reset, help) }
					fmt.println()
				}
			}
			// Hooki
			hook_keys := []string{"hooks.pre_update","hooks.post_update","hooks.on_enable","hooks.on_disable"}
			has_hooks := false
			for hk in hook_keys {
				if val, has := config[hk]; has && val != "" {
					if !has_hooks { fmt.printfln("  %sHooki:%s", Colors.yellow, Colors.reset); has_hooks = true }
					fmt.printfln("    %s%-22s%s %s", Colors.gray, hk, Colors.reset, val)
				}
			}
			fmt.println()
			if inst, has := config["install"];   has && inst != "" { fmt.printfln("  %sInstall:%s     %s", Colors.gray, Colors.reset, inst) }
			if uni,  has := config["uninstall"]; has && uni != ""  { fmt.printfln("  %sUninstall:%s   %s", Colors.gray, Colors.reset, uni) }

			// ── install ───────────────────────────────────────────────────────────
			case "install":
				if len(args) < 2 {
					print_error("%s", trans["plugin_install_usage"])
					os.exit(1)
				}
				plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
				if !path_exists(plugin_file) {
					print_error("%s '%s'", trans["plugin_not_found"], args[1])
					os.exit(1)
				}
				config, ok := parse_hacker_file(plugin_file)
				if !ok { print_error("%s", trans["invalid"]); os.exit(1) }
				if inst, has := config["install"]; has && inst != "" {
					fmt.printfln("%s%s '%s'...%s", Colors.yellow, trans["plugin_installing"], args[1], Colors.reset)
					if safe_run(inst) {
						fmt.printfln("%s%s%s", Colors.green, trans["plugin_install_done"], Colors.reset)
					} else {
						print_error("%s", trans["plugin_install_failed"])
						os.exit(1)
					}
				} else {
					fmt.printfln("%s%s%s", Colors.gray, trans["plugin_no_install_script"], Colors.reset)
				}

				// ── uninstall ─────────────────────────────────────────────────────────
			case "uninstall":
				if len(args) < 2 {
					print_error("%s", trans["plugin_uninstall_usage"])
					os.exit(1)
				}
				plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
				if !path_exists(plugin_file) {
					print_error("%s '%s'", trans["plugin_not_found"], args[1])
					os.exit(1)
				}
				config, ok := parse_hacker_file(plugin_file)
				if !ok { print_error("%s", trans["invalid"]); os.exit(1) }
				if uni, has := config["uninstall"]; has && uni != "" {
					fmt.printfln("%s%s '%s'...%s", Colors.yellow, trans["plugin_uninstalling"], args[1], Colors.reset)
					if config["enabled"] == "true" {
						if hook, hhas := config["hooks.on_disable"]; hhas && hook != "" { safe_run(hook) }
					}
					if safe_run(uni) {
						fmt.printfln("%s%s%s", Colors.green, trans["plugin_uninstall_done"], Colors.reset)
					} else {
						print_error("%s", trans["plugin_uninstall_failed"])
						os.exit(1)
					}
				} else {
					fmt.printfln("%s%s%s", Colors.gray, trans["plugin_no_uninstall_script"], Colors.reset)
				}

				// ── run <plugin> <komenda> [args] ─────────────────────────────────────
			case "run":
				if len(args) < 3 {
					print_error("%s", trans["plugin_run_usage"])
					os.exit(1)
				}
				plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
				if !path_exists(plugin_file) {
					print_error("%s '%s'", trans["plugin_not_found"], args[1])
					os.exit(1)
				}
				config, ok := parse_hacker_file(plugin_file)
				if !ok || config["enabled"] != "true" {
					print_error("%s", trans["plugin_not_enabled"])
					os.exit(1)
				}
				cmd_name := args[2]
				exec_key := fmt.tprintf("commands.%s.exec", cmd_name)
				sudo_key := fmt.tprintf("commands.%s.sudo", cmd_name)
				if exec_cmd, has := config[exec_key]; has {
					arg_str := ""
					if len(args) > 3 { arg_str = strings.join(args[3:], " ") }
					use_sudo := ""
					if sv, shas := config[sudo_key]; shas && sv == "true" { use_sudo = "sudo " }
					safe_run(fmt.tprintf("%s%s %s", use_sudo, exec_cmd, arg_str))
				} else {
					print_error("%s '%s' w pluginie '%s'", trans["plugin_cmd_not_found"], cmd_name, args[1])
					os.exit(1)
				}

				// ── new <nazwa> ───────────────────────────────────────────────────────
			case "new":
				if len(args) < 2 {
					print_error("%s", trans["plugin_new_usage"])
					os.exit(1)
				}
				plugin_name := args[1]
				plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), plugin_name)
				if path_exists(plugin_file) {
					print_error("%s '%s'", trans["plugin_already_exists"], plugin_name)
					os.exit(1)
				}
				plugin_dir := get_plugin_dir()
				if !path_exists(plugin_dir) { _ = os.make_directory_all(plugin_dir) }
				template := fmt.tprintf(`[
					name > %s
					version > 1.0.0
					description > Opis pluginu
					author > Autor
					license > MIT
					enabled > false

					commands.example.exec > /bin/echo
					commands.example.description > Przykładowa komenda
					commands.example.help > Uruchom przykładową komendę
					commands.example.args > <tekst>
					commands.example.sudo > false

					hooks.pre_update >
					hooks.post_update >
					hooks.on_enable >
					hooks.on_disable >

					depends >
					install >
					uninstall >
				]
				`, plugin_name)
				if err := os.write_entire_file_from_string(plugin_file, template); err != nil {
					print_error("%s", trans["plugin_new_failed"])
					os.exit(1)
				}
				fmt.printfln("%s%s '%s'%s", Colors.green, trans["plugin_new_created"], plugin_file, Colors.reset)
				fmt.printfln("%s%s%s", Colors.gray, trans["plugin_new_hint"], Colors.reset)

				// ── run-hooks <typ> ───────────────────────────────────────────────────
			case "run-hooks":
				if len(args) < 2 {
					print_error("Użycie: hacker plugin run-hooks <pre_update|post_update|on_enable|on_disable>")
					os.exit(1)
				}
				run_plugin_update_hooks(args[1])
				fmt.printfln("%s%s %s%s", Colors.green, trans["plugin_hooks_ran"], args[1], Colors.reset)

			case:
				print_error("Unknown plugin subcommand -> %s", args[0])
				show_plugin_help(lang)
				os.exit(1)
	}
}

// ─── Sprawdzenie zależności pluginu ───────────────────────────────────────────

check_plugin_deps :: proc(config: HackerConfig) -> bool {
	deps_val, has := config["depends"]
	if !has || strings.trim_space(deps_val) == "" { return true }
	deps := strings.split(deps_val, ",")
	for &dep in deps {
		dep = strings.trim_space(dep)
		if dep == "" { continue }
		check := fmt.tprintf("command -v %s > /dev/null 2>&1", dep)
		if !safe_run(check) { return false }
	}
	return true
}

// ─── Uruchomienie hooków dla wszystkich aktywnych pluginów ────────────────────

run_plugin_update_hooks :: proc(hook_type: string) {
	hook_key := fmt.tprintf("hooks.%s", hook_type)
	for f in glob_dir(get_plugin_dir(), ".hacker") {
		config, ok := parse_hacker_file(f)
		if !ok { continue }
		if config["enabled"] != "true" { continue }
		if hook, has := config[hook_key]; has && hook != "" {
			pname := strings.trim_suffix(filepath.base(f), ".hacker")
			fmt.printfln("%s-> [%s] hook %s...%s", Colors.gray, pname, hook_type, Colors.reset)
			safe_run(hook)
		}
	}
}

show_plugin_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["plugin_subcommands"], Colors.reset)
	fmt.printfln(" %slist              %s- %s", Colors.gray, Colors.reset, trans["list_desc"])
	fmt.printfln(" %senable  <nazwa>   %s- %s", Colors.gray, Colors.reset, trans["enable_desc"])
	fmt.printfln(" %sdisable <nazwa>   %s- %s", Colors.gray, Colors.reset, trans["disable_desc"])
	fmt.printfln(" %sinfo    <nazwa>   %s- %s", Colors.gray, Colors.reset, trans["plugin_info_desc"])
	fmt.printfln(" %sinstall <nazwa>   %s- %s", Colors.gray, Colors.reset, trans["plugin_install_desc"])
	fmt.printfln(" %suninstall <nazwa> %s- %s", Colors.gray, Colors.reset, trans["plugin_uninstall_desc"])
	fmt.printfln(" %srun <p> <komenda> %s- %s", Colors.gray, Colors.reset, trans["plugin_run_desc"])
	fmt.printfln(" %snew <nazwa>       %s- %s", Colors.gray, Colors.reset, trans["plugin_new_desc"])
	fmt.printfln(" %srun-hooks <typ>   %s- %s", Colors.gray, Colors.reset, trans["plugin_run_hooks_desc"])
}

// ─── enable / disable ─────────────────────────────────────────────────────────

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
	fmt.printfln(" %smotd         %s- %s", Colors.gray, Colors.reset, trans["motd_desc"])
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
	fmt.printfln(" %smotd         %s- %s", Colors.gray, Colors.reset, trans["motd_desc"])
	fmt.printfln(" %sspecial-motd %s- %s", Colors.gray, Colors.reset, trans["special_motd_desc"])
}

// ─── settings ─────────────────────────────────────────────────────────────────

// Format pliku look.json:
// {
//   "accent":  "#c026d3",
//   "success": "#22c55e",
//   "error":   "#ef4444",
//   "warning": "#eab308",
//   "info":    "#06b6d4",
//   "dim":     "#475569"
// }

// ─── Look presets ─────────────────────────────────────────────────────────────

LookPreset :: struct {
	name:   string,
	// [accent, success, error, warning, info, dim]
	colors: [6]string,
}

// Zwraca slice presetów — procedura zamiast mutable global
get_look_presets :: proc() -> []LookPreset {
	@(static) presets := [?]LookPreset{
		{"default", {"#c026d3", "#22c55e", "#ef4444", "#eab308", "#06b6d4", "#475569"}},
		{"ocean",   {"#0ea5e9", "#34d399", "#f87171", "#fbbf24", "#22d3ee", "#64748b"}},
		{"forest",  {"#16a34a", "#4ade80", "#f87171", "#facc15", "#2dd4bf", "#6b7280"}},
		{"sunset",  {"#f97316", "#22c55e", "#dc2626", "#fbbf24", "#38bdf8", "#6b7280"}},
		{"mono",    {"#e2e8f0", "#a3e635", "#f87171", "#fde68a", "#93c5fd", "#64748b"}},
		{"hacker",  {"#00ff41", "#00ff41", "#ff0000", "#ffff00", "#00ffff", "#4a4a4a"}},
	}
	return presets[:]
}

// Znajdź preset po nazwie
find_look_preset :: proc(name: string) -> ([6]string, bool) {
	for p in get_look_presets() {
		if p.name == name {
			return p.colors, true
		}
	}
	return {}, false
}

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
				os.exit(0)
			} else {
				print_error("%s %s. %s %s", trans["unsupported_language"], new_lang, trans["supported"], strings.join(supported_languages, ", "))
				os.exit(1)
			}
		case "look":
			handle_settings_look(args[1:], lang)
		case:
			print_error("Unknown settings subcommand -> %s", args[0])
			show_settings_help(lang)
			os.exit(1)
	}
}

handle_settings_look :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	look_file := get_config_path("look.json")

	if len(args) == 0 {
		show_look_status(look_file, lang)
		os.exit(0)
	}

	sub := args[0]

	switch sub {
		case "preset":
			if len(args) < 2 {
				fmt.printfln("%s%s%s", Colors.yellow, trans["look_available_presets"], Colors.reset)
				for p in get_look_presets() {
					fmt.printfln("  %s%s%s", Colors.cyan, p.name, Colors.reset)
				}
				os.exit(0)
			}
			preset_name := strings.to_lower(args[1])
			colors, ok := find_look_preset(preset_name)
			if ok {
				save_look_preset(look_file, preset_name, colors)
				fmt.printfln("%s%s '%s'.%s", Colors.green, trans["look_preset_applied"], preset_name, Colors.reset)
				fmt.printfln("%s%s%s", Colors.gray, trans["look_restart_hint"], Colors.reset)
			} else {
				print_error("%s '%s'", trans["look_unknown_preset"], preset_name)
				fmt.printfln("%s%s%s%s", Colors.yellow, trans["look_available_presets"], ": default, ocean, forest, sunset, mono, hacker", Colors.reset)
				os.exit(1)
			}

		case "set":
			if len(args) < 3 {
				fmt.printfln("%s%s%s", Colors.yellow, trans["look_set_usage"], Colors.reset)
				os.exit(1)
			}
			key := strings.to_lower(args[1])
			hex := args[2]
			valid_keys := []string{"accent","success","error","warning","info","dim"}
			key_valid := false
			for vk in valid_keys { if vk == key { key_valid = true; break } }
			if !key_valid {
				print_error("%s '%s'. %s: accent, success, error, warning, info, dim", trans["look_invalid_key"], key, trans["look_valid_keys"])
				os.exit(1)
			}
			if len(hex) != 7 || hex[0] != '#' {
				print_error("%s", trans["look_invalid_hex"])
				os.exit(1)
			}
			set_look_color(look_file, key, hex)
			fmt.printfln("%s%s '%s' -> %s%s", Colors.green, trans["look_color_set"], key, hex, Colors.reset)
			fmt.printfln("%s%s%s", Colors.gray, trans["look_restart_hint"], Colors.reset)

		case "reset":
			if path_exists(look_file) {
				_ = os.remove(look_file)
			}
			fmt.printfln("%s%s%s", Colors.green, trans["look_reset_done"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.gray, trans["look_restart_hint"], Colors.reset)

		case "show":
			show_look_status(look_file, lang)

		case:
			print_error("Unknown look subcommand -> %s", sub)
			show_look_help(lang)
			os.exit(1)
	}
}

show_look_status :: proc(look_file: string, lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["look_current_title"], Colors.reset)

	if !path_exists(look_file) {
		fmt.printfln("  %s%s%s", Colors.gray, trans["look_using_defaults"], Colors.reset)
	} else {
		data, err := os.read_entire_file(look_file, context.allocator)
		if err == nil {
			fmt.printfln("  %s%s%s", Colors.gray, string(data), Colors.reset)
		}
	}
	fmt.println()
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.cyan, trans["look_presets_title"], Colors.reset)
	for p in get_look_presets() {
		hex := p.colors[0]
		// Bezpieczna konwersja hex na ANSI (tylko jeśli poprawny format)
		ansi := ""
		if len(hex) == 7 && hex[0] == '#' {
			r := parse_hex2(hex[1:3])
			g := parse_hex2(hex[3:5])
			b := parse_hex2(hex[5:7])
			ansi = fmt.tprintf("\e[38;2;%d;%d;%dm", r, g, b)
		}
		fmt.printfln("  %s%-10s%s accent: %s%s%s", Colors.gray, p.name, Colors.reset, ansi, hex, Colors.reset)
	}
	fmt.println()
	fmt.printfln("%s%s%s", Colors.gray, trans["look_usage_hint"], Colors.reset)
}

save_look_preset :: proc(look_file: string, name: string, colors: [6]string) {
	content := fmt.tprintf(
		`{"preset":"%s","accent":"%s","success":"%s","error":"%s","warning":"%s","info":"%s","dim":"%s"}`,
		name, colors[0], colors[1], colors[2], colors[3], colors[4], colors[5],
	)
	dir := strings.join([]string{get_home(), ".config", "hackeros", "hacker"}, "/")
	if !path_exists(dir) {
		_ = os.make_directory_all(dir)
	}
	_ = os.write_entire_file_from_string(look_file, content)
	load_look_colors(colors)
}

set_look_color :: proc(look_file: string, key: string, hex: string) {
	// Wczytaj istniejący JSON lub zacznij od domyślnych
	existing := `{"preset":"custom","accent":"#c026d3","success":"#22c55e","error":"#ef4444","warning":"#eab308","info":"#06b6d4","dim":"#475569"}`
	if path_exists(look_file) {
		data, err := os.read_entire_file(look_file, context.allocator)
		if err == nil { existing = string(data) }
	}
	// Prosta podmiana wartości dla danego klucza w JSON
	old_search := fmt.tprintf(`"%s":"#`, key)
	idx := strings.index(existing, old_search)
	if idx >= 0 {
		start := idx + len(old_search) - 1
		end := strings.index(existing[start:], `"`)
		if end >= 0 {
			new_content := strings.concatenate({existing[:start], hex, existing[start+end:]})
			_ = os.write_entire_file_from_string(look_file, new_content)
			return
		}
	}
	// Jeśli klucz nie istnieje, użyj save_look_preset z domyślnymi
	_ = os.write_entire_file_from_string(look_file, existing)
}

load_look_colors :: proc(colors: [6]string) {
	make_ansi :: proc(hex: string) -> string {
		if len(hex) != 7 { return "" }
		r := parse_hex2(hex[1:3])
		g := parse_hex2(hex[3:5])
		b := parse_hex2(hex[5:7])
		return fmt.tprintf("\e[38;2;%d;%d;%dm", r, g, b)
	}
	Colors.magenta = make_ansi(colors[0])
	Colors.green   = make_ansi(colors[1])
	Colors.red     = make_ansi(colors[2])
	Colors.yellow  = make_ansi(colors[3])
	Colors.cyan    = make_ansi(colors[4])
	Colors.gray    = make_ansi(colors[5])
}

show_look_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["look_subcommands"], Colors.reset)
	fmt.printfln(" %spreset <nazwa> %s- %s", Colors.gray, Colors.reset, trans["look_preset_desc"])
	fmt.printfln(" %sset <klucz> <#hex> %s- %s", Colors.gray, Colors.reset, trans["look_set_desc"])
	fmt.printfln(" %sreset %s- %s", Colors.gray, Colors.reset, trans["look_reset_desc"])
	fmt.printfln(" %sshow %s- %s", Colors.gray, Colors.reset, trans["look_show_desc"])
}

show_settings_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["settings_subcommands"], Colors.reset)
	fmt.printfln(" %slanguage [kod] %s- %s", Colors.gray, Colors.reset, trans["language_desc"])
	fmt.printfln(" %slook           %s- %s", Colors.gray, Colors.reset, trans["look_desc"])
}

// ─── main help ────────────────────────────────────────────────────────────────

show_main_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["tool_title"], Colors.reset)
	cmds := [][2]string{
		{"unpack",                    trans["desc_unpack"]},
		{"pack",                      trans["desc_pack"]},
		{"env",                       trans["desc_env"]},
		{"help",                      trans["desc_help"]},
		{"help-ui",                   trans["desc_help_ui"]},
		{"docs",                      trans["desc_docs"]},
		{"install <pkg>",             trans["desc_install"]},
		{"remove <pkg>",              trans["desc_remove"]},
		{"flatpak-install <pkg>",     trans["desc_flatpak_install"]},
		{"flatpak-remove <pkg>",      trans["desc_flatpak_remove"]},
		{"system",                    trans["desc_system"]},
		{"run",                       trans["desc_run"]},
		{"update [--with-gui]",       trans["desc_update"]},
		{"game",                      trans["desc_game"]},
		{"languages",                 trans["desc_languages"]},
		{"ascii",                     trans["desc_ascii"]},
		{"shell",                     trans["desc_shell"]},
		{"interactive",               trans["desc_interactive"]},
		{"enter <container>",         trans["desc_enter"]},
		{"remove-container <name>",   trans["desc_remove_container"]},
		{"restart <service>",         trans["desc_restart"]},
		{"doctor",                    trans["desc_doctor"]},
		{"plugin",                    trans["desc_plugin"]},
		{"enable",                    trans["desc_enable"]},
		{"disable",                   trans["desc_disable"]},
		{"how-to-create-commands",    trans["desc_how_to"]},
		{"index",                     trans["desc_index"]},
		{"info",                      trans["desc_info"]},
		{"issue",                     trans["desc_issue"]},
		{"repair",                    trans["desc_repair"]},
		{"settings",                  trans["desc_settings"]},
		{"switch",                    trans["desc_switch"]},
	}
	for c in cmds {
		fmt.printfln(" %s%-28s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
	// Custom commands
	fmt.printfln("\n%s%s%s%s", Colors.bold, Colors.magenta, trans["custom_commands"], Colors.reset)
	for f in glob_dir(get_custom_dir(), ".hacker") {
		name := strings.trim_suffix(filepath.base(f), ".hacker")
		config, ok := parse_hacker_file(f)
		if ok {
			desc := trans["no_description"]
			if d, has := config["description"]; has { desc = d }
			fmt.printfln(" %s%-28s %s- %s", Colors.gray, name, Colors.reset, desc)
		} else {
			fmt.printfln(" %s%-28s %s- %s", Colors.gray, name, Colors.reset, trans["invalid_config"])
		}
	}
	// Plugin commands
	fmt.printfln("\n%s%s%s%s", Colors.bold, Colors.magenta, trans["plugins_title"], Colors.reset)
	found_any_plugin_cmd := false
	for f in glob_dir(get_plugin_dir(), ".hacker") {
		config, ok := parse_hacker_file(f)
		if !ok { continue }
		if config["enabled"] != "true" { continue }
		for k, v in config {
			if strings.has_prefix(k, "commands.") && strings.has_suffix(k, ".exec") {
				cmd_name := k[len("commands."):]
				cmd_name = cmd_name[:len(cmd_name)-len(".exec")]
				desc_key := fmt.tprintf("commands.%s.description", cmd_name)
				desc := trans["no_description"]
				if d, has := config[desc_key]; has { desc = d }
				fmt.printfln(" %s%-28s %s- %s", Colors.gray, cmd_name, Colors.reset, desc)
				found_any_plugin_cmd = true
				_ = v
			}
		}
	}
	if !found_any_plugin_cmd {
		fmt.printfln(" %s%s%s", Colors.gray, trans["no_plugins_active"], Colors.reset)
	}
}
