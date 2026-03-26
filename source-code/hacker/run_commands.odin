package hackeros

import "core:fmt"
import "core:os"

handle_run :: proc(args: []string, lang: string) {
	trans := get_translations_main(lang)
	if len(args) == 0 || args[0] == "help" {
		show_run_help(lang)
		os.exit(0)
	}
	switch args[0] {
		case "update-system":
			safe_run("/usr/share/HackerOS/Scripts/Bin/update-system.sh")
		case "check-updates":
			safe_run("/usr/share/HackerOS/Scripts/Bin/check_updates_notify.sh")
		case "steam":
			safe_run("/usr/share/HackerOS/Scripts/Steam/HackerOS-Steam.sh")
		case "hacker-launcher":
			safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker_Launcher")
		case "hackeros-game-mode":
			safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Game-Mode.AppImage")
		case "update-hackeros":
			safe_run("/usr/share/HackerOS/Scripts/Bin/update-hackeros.sh")
		case "update-wallpapers":
			safe_run("/usr/share/HackerOS/Scripts/Bin/update-wallpapers.sh")
		case "remove-debian-kernel":
			safe_run("/usr/share/HackerOS/Scripts/Bin/remove-debian-kernel.sh")
		case "HackerOS-Store":
			safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerOS-Store")
		case "HackerOS-Steam":
			safe_run("HackerOS-Steam run")
		case "HackerDeck":
			safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/HackerDeck")
		case "Hacker-Term":
			safe_run("/usr/share/HackerOS/Scripts/HackerOS-Apps/Hacker-Term")
		case "build-hackeros":
			safe_run("sudo /usr/share/HackerOS/Archived/build-hackeros")
		case:
			print_error("Unknown run subcommand -> %s", args[0])
			show_run_help(lang)
			os.exit(1)
	}
}

show_run_help :: proc(lang: string) {
	trans := get_translations_main(lang)
	fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["run_title"], Colors.reset)
	cmds := [][2]string{
		{"update-system",        trans["run_update_system"]},
		{"check-updates",        trans["run_check_updates"]},
		{"steam",                trans["run_steam"]},
		{"hacker-launcher",      trans["run_hacker_launcher"]},
		{"hackeros-game-mode",   trans["run_game_mode"]},
		{"update-hackeros",      trans["run_update_hackeros"]},
		{"update-wallpapers",    trans["run_update_wallpapers"]},
		{"remove-debian-kernel", trans["run_remove_debian_kernel"]},
		{"HackerOS-Store",       trans["run_hackeros_store"]},
		{"HackerOS-Steam",       trans["run_hackeros_steam"]},
		{"HackerDeck",           trans["run_hackerdeck"]},
		{"Hacker-Term",          trans["run_hacker_term"]},
		{"build-hackeros",       trans["run_build_hackeros"]},
	}
	for c in cmds {
		fmt.printfln(" %s%-24s %s- %s", Colors.gray, c[0], Colors.reset, c[1])
	}
}
