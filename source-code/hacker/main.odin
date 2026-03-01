package hackeros

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"

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
		case "env":                    // ← NOWOŚĆ
			handle_env(rest, lang)
		case "help-ui":
			safe_run("~/.hackeros/hacker/hacker-help")
		case "docs":
			safe_run("~/.hackeros/hacker/hacker-docs")
		case "install":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_install"], Colors.reset)
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("~/.hackeros/hacker/apt-fronted install %s", pkg))
		case "remove":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_remove"], Colors.reset)
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("~/.hackeros/hacker/apt-fronted remove %s", pkg))
		case "flatpak-install":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_flatpak_install"], Colors.reset)
				os.exit(1)
			}
			pkg := strings.join(rest, " ")
			safe_run(fmt.tprintf("flatpak install -y %s", pkg))
		case "flatpak-remove":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_flatpak_remove"], Colors.reset)
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
			safe_run("source ~/.hackeros/venv/bin/activate && ~/.hackeros/hacker/hacker-shell")
		case "enter":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_enter"], Colors.reset)
				os.exit(1)
			}
			safe_run(fmt.tprintf("distrobox enter %s", rest[0]))
		case "remove-container":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_remove_container"], Colors.reset)
				os.exit(1)
			}
			safe_run(fmt.tprintf("distrobox rm %s", rest[0]))
		case "restart":
			if len(rest) == 0 {
				fmt.printfln("%s%s%s", Colors.red, trans["usage_restart"], Colors.reset)
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
			data, ok := os.read_entire_file(file_path)
			if !ok {
				fmt.printfln("%s%s %s%s", Colors.red, trans["file_not_found"], file_path, Colors.reset)
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
				fmt.printfln("%s%s%s", Colors.red, trans["variant_not_found"], Colors.reset)
			}
		case "info":
			fmt.printfln("%s%s%s", Colors.green, trans["version_tool"], Colors.reset)
			fmt.printfln("%s%s%s", Colors.green, trans["version_os"], Colors.reset)
		case "issue":
			browser := "xdg-open"
			if path_exists("/usr/bin/vivaldi") { browser = "vivaldi" }
			safe_run(fmt.tprintf("%s https://github.com/HackerOS-Linux-System/HackerOS-Website/issues/new", browser))
		case "repair":
			safe_run(filepath.join([]string{get_home(), ".hackeros/hacker/hacker-repair"}))
		case "settings":
			handle_settings(rest, lang)
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
						fmt.printfln("%s%s%s", Colors.red, trans["no_exec_custom"], Colors.reset)
						os.exit(1)
					}
				} else {
					fmt.printfln("%s%s%s", Colors.red, trans["error_custom"], Colors.reset)
					os.exit(1)
				}
			} else if !try_plugin_command(command, rest, lang) {
				fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_command"], command, Colors.reset)
				show_main_help(lang)
				os.exit(1)
			}
	}
}

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
			fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_system"], args[0], Colors.reset)
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
				fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_update_flag"], args[0], Colors.reset)
				fmt.println(trans["available_flags"])
				os.exit(1)
		}
	}
}

show_hackeros_tools :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["tools_index"], Colors.reset)
	fmt.printfln(" * bytes - %s", trans["tool_bytes"])
	fmt.printfln(" * hl - %s", trans["tool_hl"])
	fmt.printfln(" * hli - %s", trans["tool_hli"])
	fmt.printfln(" * hacker - %s", trans["tool_hacker"])
	fmt.printfln(" * Hacker Kernel - %s", trans["tool_kernel"])
	fmt.printfln(" * HackerOS Steam - %s", trans["tool_steam"])
	fmt.printfln(" * HackerOS Welcome - %s", trans["tool_welcome"])
	fmt.printfln(" * HackerOS App - %s", trans["tool_app"])
	fmt.printfln(" * HackerOS Store - %s", trans["tool_store"])
	fmt.printfln(" * Security Mode - %s", trans["tool_security_mode"])
	fmt.printfln(" * Hacker Mode - %s", trans["tool_hacker_mode"])
	fmt.printfln(" * isolator - %s", trans["tool_isolator"])
	fmt.printfln(" * hpm - %s", trans["tool_hpm"])
	fmt.printfln(" * HackerOS Game Mode - %s", trans["tool_game_mode"])
	fmt.printfln(" * hup - %s", trans["tool_hup"])
	fmt.printfln(" * hammer - %s", trans["tool_hammer"])
	fmt.printfln(" * HackerOS Games - %s", trans["tool_games"])
	fmt.printfln(" * Hacker Launcher - %s", trans["tool_launcher"])
	fmt.printfln(" * virus - %s", trans["tool_virus"])
	fmt.printfln(" * HackerOS Builder - %s", trans["tool_builder"])
	fmt.printfln(" * Blue Environment (BETA) - %s", trans["tool_blue"])
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
				fmt.printfln("%s%s%s", Colors.red, trans["usage_plugin_enable"], Colors.reset)
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				fmt.printfln("%s%s%s", Colors.red, trans["plugin_not_found"], Colors.reset)
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
				fmt.printfln("%s%s%s", Colors.red, trans["usage_plugin_disable"], Colors.reset)
				os.exit(1)
			}
			plugin_file := fmt.tprintf("%s/%s.hacker", get_plugin_dir(), args[1])
			if !path_exists(plugin_file) {
				fmt.printfln("%s%s%s", Colors.red, trans["plugin_not_found"], Colors.reset)
				os.exit(1)
			}
			config, ok := parse_hacker_file(plugin_file)
			if ok {
				config["enabled"] = "false"
				write_hacker_file(plugin_file, config)
				fmt.printfln("%s%s '%s'.%s", Colors.green, trans["disabled_plugin"], args[1], Colors.reset)
			}
		case:
			fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_plugin"], args[0], Colors.reset)
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
			fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_enable"], args[0], Colors.reset)
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
			fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_disable"], args[0], Colors.reset)
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
			} else {
				fmt.printfln("%s%s %s. %s %s%s",
							 Colors.red, trans["unsupported_language"], new_lang,
				 trans["supported"], strings.join(supported_languages, ", "),
							 Colors.reset)
				os.exit(1)
			}
		case:
			fmt.printfln("%s%s %s%s", Colors.red, trans["unknown_settings"], args[0], Colors.reset)
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
		{"pack",   trans["desc_pack"]},
		{"env",    trans["desc_env"]},           // ← NOWOŚĆ
		{"help",   trans["desc_help"]},
		{"help-ui",trans["desc_help_ui"]},
		{"docs",   trans["desc_docs"]},
		{"install ", trans["desc_install"]},
		{"remove ", trans["desc_remove"]},
		{"flatpak-install ", trans["desc_flatpak_install"]},
		{"flatpak-remove ", trans["desc_flatpak_remove"]},
		{"system", trans["desc_system"]},
		{"run",    trans["desc_run"]},
		{"update [ --with-gui ]", trans["desc_update"]},
		{"game",   trans["desc_game"]},
		{"hacker-lang", trans["desc_hacker_lang"]},
		{"ascii",  trans["desc_ascii"]},
		{"shell",  trans["desc_shell"]},
		{"enter ", trans["desc_enter"]},
		{"remove-container ",trans["desc_remove_container"]},
		{"restart ", trans["desc_restart"]},
		{"plugin", trans["desc_plugin"]},
		{"enable", trans["desc_enable"]},
		{"disable",trans["desc_disable"]},
		{"how-to-create-commands", trans["desc_how_to"]},
		{"index",  trans["desc_index"]},
		{"info",   trans["desc_info"]},
		{"issue",  trans["desc_issue"]},
		{"repair", trans["desc_repair"]},
		{"settings", trans["desc_settings"]},
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
