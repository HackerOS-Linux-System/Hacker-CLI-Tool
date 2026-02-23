package hackeros

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:encoding/json"
import "core:sys/posix"

ColorCodes :: struct {
	red, yellow, green, magenta, gray, bold, reset, blue, cyan, white: string,
}

@(private)
_colors := ColorCodes{
	red = "\e[31m",
	yellow = "\e[33m",
	green = "\e[32m",
	magenta = "\e[35m",
	gray = "\e[90m",
	bold = "\e[1m",
	reset = "\e[0m",
	blue = "\e[34m",
	cyan = "\e[36m",
	white = "\e[37m",
}

Colors := _colors

safe_run :: proc(cmd: string) -> bool {
	pid := posix.fork()
	if pid < 0 {
		err := posix.get_errno()
		fmt.printfln("%sFailed to fork: %v%s", Colors.red, err, Colors.reset)
		return false
	}
	if pid == 0 {
		// child
		sh_str := "/bin/sh\x00"
		sh_cstr := cstring(raw_data(sh_str))
		c_str := "-c\x00"
		c_cstr := cstring(raw_data(c_str))
		cmd_cstr := strings.clone_to_cstring(cmd)
		args_array: [4]cstring = {sh_cstr, c_cstr, cmd_cstr, nil}
		args := raw_data(args_array[:])
		exec_err := posix.execvp(sh_cstr, args)
		if exec_err == -1 {
			fmt.printfln("%sExec failed: %v%s", Colors.red, posix.get_errno(), Colors.reset)
		}
		delete(cmd_cstr)
		posix._exit(1)
	}
	// parent: wait
	status: i32
	wpid := posix.waitpid(pid, &status, {})
	if wpid == -1 {
		err := posix.get_errno()
		fmt.printfln("%sWait failed: %v%s", Colors.red, err, Colors.reset)
		return false
	}
	if wpid != pid {
		fmt.printfln("%sWaitpid returned unexpected pid: %d%s", Colors.red, wpid, Colors.reset)
		return false
	}
	exit_code := posix.WEXITSTATUS(status)
	if exit_code != 0 {
		fmt.printfln("%sCommand '%s' failed with exit code %d%s",
					 Colors.red, cmd, exit_code, Colors.reset)
		return false
	}
	return true
}

get_home :: proc() -> string {
	home, ok := os.lookup_env("HOME")
	if !ok { return "/root" }
	return home
}

get_config_path :: proc(file: string) -> string {
	return filepath.join([]string{get_home(), ".config", "hackeros", "hacker", file})
}

get_custom_dir :: proc() -> string {
	return get_config_path("custom-commands")
}

get_plugin_dir :: proc() -> string {
	return get_config_path("plugins")
}

get_custom_command_path :: proc(name: string) -> string {
	return fmt.tprintf("%s/%s.hacker", get_custom_dir(), name)
}

path_exists :: proc(p: string) -> bool {
	_, err := os.stat(p)
	return err == os.ERROR_NONE
}

glob_dir :: proc(dir: string, suffix: string) -> []string {
	result: [dynamic]string
	handle, err := os.open(dir)
	if err != os.ERROR_NONE { return result[:] }
	defer os.close(handle)
	infos, read_err := os.read_dir(handle, -1)
	if read_err != os.ERROR_NONE { return result[:] }
	for info in infos {
		if strings.has_suffix(info.name, suffix) {
			append(&result, filepath.join([]string{dir, info.name}))
		}
	}
	return result[:]
}

load_lang :: proc() -> string {
	file := get_config_path("language.json")
	data, ok := os.read_entire_file(file)
	if !ok { return "pl" }
	val, err := json.parse(data)
	if err != nil { return "pl" }
	defer json.destroy_value(val)
	obj, is_obj := val.(json.Object)
	if !is_obj { return "pl" }
	lang_val, has := obj["language"]
	if !has { return "pl" }
	lang_str, is_str := lang_val.(json.String)
	if !is_str { return "pl" }
	l := string(lang_str)
	valid_langs := []string{"pl","en","de","fr","es","it","ru","zh","ja","ko","pt","ar","hi"}
	for sl in valid_langs {
		if l == sl { return l }
	}
	return "en"
}

save_language :: proc(lang: string) {
	file := get_config_path("language.json")
	dir := filepath.dir(file)
	os.make_directory(dir)
	content := fmt.tprintf("{\"language\":\"%s\"}", lang)
	os.write_entire_file(file, transmute([]u8)content)
}

load_styles :: proc(file: string) {
	data, ok := os.read_entire_file(file)
	if !ok { return }
	content := string(data)
	start := strings.index(content, ":root")
	if start < 0 { return }
	brace := strings.index(content[start:], "{")
	if brace < 0 { return }
	end := strings.index(content[start+brace:], "}")
	if end < 0 { return }
	css := content[start+brace+1 : start+brace+end]
	for decl in strings.split_iterator(&css, ";") {
		decl := strings.trim_space(decl)
		if decl == "" { continue }
		colon := strings.index(decl, ":")
		if colon < 0 { continue }
		var_name := strings.trim_space(strings.to_lower(strings.trim_prefix(decl[:colon], "--")))
		hex_val := strings.trim_space(decl[colon+1:])
		if len(hex_val) != 7 || hex_val[0] != '#' { continue }
		r := parse_hex2(hex_val[1:3])
		g := parse_hex2(hex_val[3:5])
		b := parse_hex2(hex_val[5:7])
		ansi := fmt.tprintf("\e[38;2;%d;%d;%dm", r, g, b)
		switch var_name {
			case "red": Colors.red = ansi
			case "yellow": Colors.yellow = ansi
			case "green": Colors.green = ansi
			case "magenta": Colors.magenta = ansi
			case "gray": Colors.gray = ansi
		}
	}
}

@(private)
parse_hex2 :: proc(s: string) -> int {
	val := 0
	for c in s {
		val *= 16
		switch c {
			case '0'..='9': val += int(c - '0')
			case 'a'..='f': val += int(c - 'a') + 10
			case 'A'..='F': val += int(c - 'A') + 10
		}
	}
	return val
}

HackerConfig :: map[string]string

parse_hacker_file :: proc(path: string) -> (HackerConfig, bool) {
	data, ok := os.read_entire_file(path)
	if !ok { return nil, false }
	content := strings.trim_space(string(data))
	if !strings.has_prefix(content, "[") || !strings.has_suffix(content, "]") {
		return nil, false
	}
	content = strings.trim_space(content[1:len(content)-1])
	config := make(HackerConfig)
	path_stack: [dynamic]string
	for raw_line in strings.split_lines_iterator(&content) {
		line := strings.trim_space(raw_line)
		if line == "" { continue }
		level := 0
		for strings.has_prefix(line[level:], ">") {
			level += 1
		}
		line = strings.trim_space(line[level:])
		arrow := strings.index(line, ">")
		key := line[:arrow] if arrow >= 0 else line
		value := ""
		if arrow >= 0 {
			value = strings.trim_space(line[arrow+1:])
		}
		for len(path_stack) > level {
			pop(&path_stack)
		}
		if value == "" {
			append(&path_stack, key)
		} else {
			full_key := strings.join(append_clone(path_stack[:], key), ".")
			config[full_key] = value
		}
	}
	return config, true
}

@(private)
append_clone :: proc(s: []string, extra: string) -> []string {
	result := make([]string, len(s)+1)
	copy(result, s)
	result[len(s)] = extra
	return result
}

write_hacker_file :: proc(path: string, config: HackerConfig) {
	sb := strings.builder_make()
	strings.write_string(&sb, "[\n")
	for k, v in config {
		strings.write_string(&sb, fmt.tprintf("%s> %s\n", k, v))
	}
	strings.write_string(&sb, "]\n")
	os.write_entire_file(path, transmute([]u8)strings.to_string(sb))
}

try_plugin_command :: proc(command: string, args: []string, lang: string) -> bool {
	for f in glob_dir(get_plugin_dir(), ".hacker") {
		config, ok := parse_hacker_file(f)
		if !ok { continue }
		if config["enabled"] != "true" { continue }
		exec_key := fmt.tprintf("commands.%s.exec", command)
		if exec_cmd, has := config[exec_key]; has {
			arg_str := strings.join(args, " ")
			safe_run(fmt.tprintf("%s %s", exec_cmd, arg_str))
			return true
		}
	}
	return false
}
