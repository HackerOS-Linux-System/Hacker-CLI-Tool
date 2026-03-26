package hackeros
import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:slice"
import "base:runtime"

EnvConfig :: struct {
    name: string,
    image: string,
    shell: string,
    packages: [dynamic]string,
    sync_configs: [dynamic]string,
    sync_tools: map[string][dynamic]string,
}

handle_env :: proc(args: []string, lang: string) {
    trans := get_translations_main(lang)
    if len(args) == 0 || args[0] == "help" {
        show_env_help(lang)
        os.exit(0)
    }
    sub := args[0]
    rest := args[1:]
    switch sub {
        case "create":
            if len(rest) == 0 {
                print_error("%s", trans["env_create_usage"])
                os.exit(1)
            }
            env_create(rest[0], lang)
        case "remove":
            if len(rest) == 0 {
                print_error("%s", trans["env_remove_usage"])
                os.exit(1)
            }
            env_remove(rest[0], lang)
        case "enter":
            name := ""
            if len(rest) > 0 {
                name = rest[0]
            }
            env_enter(name)
        case "docs":
            env_docs(lang)
        case "settings":
            env_settings(lang)
        case:
            print_error("%s %s", trans["env_unknown_sub"], sub)
            show_env_help(lang)
            os.exit(1)
    }
}

env_create :: proc(file_path: string, lang: string) {
    trans := get_translations_main(lang)
    if !path_exists(file_path) {
        print_error("%s %s", trans["file_not_exists"], file_path)
        os.exit(1)
    }
    cfg := parse_env_file(file_path)
    defer free_env_config(&cfg)
    if cfg.name == "" || cfg.image == "" {
        print_error("%s", trans["env_missing_fields"])
        os.exit(1)
    }
    fmt.printfln("%s%s %s (%s)...%s", Colors.yellow, trans["env_creating"], cfg.name, cfg.image, Colors.reset)
    create_cmd := fmt.tprintf(`podman create \
    --name %s \
    --label hacker-env=true \
    --hostname %s \
    -it \
    %s`, cfg.name, cfg.name, cfg.image)
    safe_run(create_cmd)
    if cfg.shell == "zsh" {
        safe_run(fmt.tprintf("podman exec %s bash -c 'apt update && apt install -y zsh || dnf install -y zsh || true'", cfg.name))
        safe_run(fmt.tprintf("podman exec %s chsh -s /bin/zsh root", cfg.name))
    }
    for pkg in cfg.packages {
        safe_run(fmt.tprintf(`podman exec %s bash -c '
        if command -v apt > /dev/null; then apt install -y %s;
        elif command -v dnf > /dev/null; then dnf install -y %s;
        fi'`, cfg.name, pkg, pkg))
    }
    for cfg_path in cfg.sync_configs {
        home := os.get_env_alloc("HOME", context.allocator)
        host, _ := strings.replace(cfg_path, "~", home, 1)
        target, _ := strings.replace(cfg_path, "~", "/root", 1)
        if path_exists(host) {
            safe_run(fmt.tprintf("podman cp %s %s:%s", host, cfg.name, target))
        }
    }
    fmt.printfln("%s%s %s!%s", Colors.green, trans["env_created"], cfg.name, Colors.reset)
}

env_remove :: proc(name: string, lang: string) {
    trans := get_translations_main(lang)
    safe_run(fmt.tprintf("podman rm -f %s 2>/dev/null || true", name))
    fmt.printfln("%s%s %s.%s", Colors.green, trans["env_removed"], name, Colors.reset)
}

env_enter :: proc(name: string) {
    container := name
    if container == "" {
        safe_run(`podman ps -a --filter "label=hacker-env=true" --format "{{.Names}}"`)
        return
    }
    enter_cmd := fmt.tprintf("podman start %s 2>/dev/null || true && podman exec -it %s zsh || bash", container, container)
    safe_run(enter_cmd)
}

env_docs :: proc(lang: string) {
    // Można dodać tłumaczenia, na razie pozostaje polski
    fmt.printfln(`
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
    `, Colors.bold, Colors.reset)
}

env_settings :: proc(lang: string) {
    trans := get_translations_main(lang)
    fmt.printfln("%s%s%s", Colors.magenta, trans["env_list"], Colors.reset)
    safe_run(`podman ps -a --filter "label=hacker-env=true" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"`)
}

show_env_help :: proc(lang: string) {
    trans := get_translations_main(lang)
    fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, trans["env_subcommands"], Colors.reset)
    fmt.printfln(" %screate <plik.hk|plik.yaml> %s- %s", Colors.gray, Colors.reset, trans["env_create_desc"])
    fmt.printfln(" %sremove <nazwa> %s- %s", Colors.gray, Colors.reset, trans["env_remove_desc"])
    fmt.printfln(" %senter [nazwa] %s- %s", Colors.gray, Colors.reset, trans["env_enter_desc"])
    fmt.printfln(" %sdocs %s- %s", Colors.gray, Colors.reset, trans["env_docs_desc"])
    fmt.printfln(" %ssettings %s- %s", Colors.gray, Colors.reset, trans["env_settings_desc"])
}

parse_env_file :: proc(path: string) -> EnvConfig {
    cfg: EnvConfig
    cfg.sync_tools = make(map[string][dynamic]string)
    data, err := os.read_entire_file(path, context.allocator)
    if err != nil { return cfg }
    content := string(data)
    lines := strings.split_lines(content)
    section := ""
    for &line in lines {
        line = strings.trim(line, " \t\r")
        if len(line) == 0 || strings.has_prefix(line, "!") { continue }
        if strings.has_prefix(line, "[") && strings.has_suffix(line, "]") {
            section = line[1:len(line)-1]
            continue
        }
        if strings.has_prefix(line, "->") {
            parts := strings.split(line[2:], "=>")
            if len(parts) < 2 { continue }
            key := strings.trim(parts[0], " \t")
            val := strings.trim(parts[1], " \t")
            switch section {
                case "env":
                    switch key {
                        case "name": cfg.name = val
                        case "image": cfg.image = val
                        case "shell": cfg.shell = val
                    }
                        case "packages":
                            append(&cfg.packages, val)
                        case "sync_configs":
                            append(&cfg.sync_configs, val)
                        case "sync_tools":
                            tool_type := key
                            tools := strings.split(val, ",")
                            for &t in tools {
                                t = strings.trim(t, " \"'")
                                if t != "" {
                                    if !(tool_type in cfg.sync_tools) {
                                        cfg.sync_tools[tool_type] = [dynamic]string{}
                                    }
                                    append(&cfg.sync_tools[tool_type], t)
                                }
                            }
            }
        }
    }
    return cfg
}

free_env_config :: proc(cfg: ^EnvConfig) {
    delete(cfg.packages)
    delete(cfg.sync_configs)
    for _, &list in cfg.sync_tools {
        delete(list)
    }
    delete(cfg.sync_tools)
}
