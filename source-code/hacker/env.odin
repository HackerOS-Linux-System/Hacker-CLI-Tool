package hackeros
import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:slice"
// =============================================
// Struktura konfiguracji env
// =============================================
EnvConfig :: struct {
    name: string,
    image: string,
    shell: string,
    packages: [dynamic]string,
    sync_configs: [dynamic]string,
    sync_tools: map[string][dynamic]string, // "snap" -> ["tool1", "tool2"]
}
// =============================================
// Główna procedura
// =============================================
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
                fmt.printfln("%sUżycie: hacker env create <plik.hk|plik.yaml>%s", Colors.red, Colors.reset)
                os.exit(1)
            }
            env_create(rest[0], lang)
        case "remove":
            if len(rest) == 0 {
                fmt.printfln("%sUżycie: hacker env remove <nazwa>%s", Colors.red, Colors.reset)
                os.exit(1)
            }
            env_remove(rest[0])
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
            fmt.printfln("%sNieznana podkomenda env: %s%s", Colors.red, sub, Colors.reset)
            show_env_help(lang)
            os.exit(1)
    }
}
// =============================================
// CREATE
// =============================================
env_create :: proc(file_path: string, lang: string) {
    trans := get_translations_main(lang)
    if !path_exists(file_path) {
        fmt.printfln("%sPlik nie istnieje: %s%s", Colors.red, file_path, Colors.reset)
        os.exit(1)
    }
    cfg := parse_env_file(file_path)
    defer free_env_config(&cfg)
    if cfg.name == "" || cfg.image == "" {
        fmt.printfln("%sBrak wymaganych pól name lub image w pliku konfiguracyjnym%s", Colors.red, Colors.reset)
        os.exit(1)
    }
    fmt.printfln("%sTworzenie środowiska %s (%s)...%s", Colors.yellow, cfg.name, cfg.image, Colors.reset)
    // Tworzenie kontenera przez podman (nakładka)
    create_cmd := fmt.tprintf(`podman create \
    --name %s \
    --label hacker-env=true \
    --hostname %s \
    -it \
    %s`, cfg.name, cfg.name, cfg.image)
    safe_run(create_cmd)
    // Instalacja powłoki
    if cfg.shell == "zsh" {
        safe_run(fmt.tprintf("podman exec %s bash -c 'apt update && apt install -y zsh || dnf install -y zsh || true'", cfg.name))
        safe_run(fmt.tprintf("podman exec %s chsh -s /bin/zsh root", cfg.name))
    }
    // Instalacja pakietów
    for pkg in cfg.packages {
        safe_run(fmt.tprintf(`podman exec %s bash -c '
        if command -v apt > /dev/null; then apt install -y %s;
        elif command -v dnf > /dev/null; then dnf install -y %s;
        fi'`, cfg.name, pkg, pkg))
    }
    // Sync dotfiles
    for cfg_path in cfg.sync_configs {
        host, _ := strings.replace(cfg_path, "~", os.get_env("HOME"), 1)
        if path_exists(host) {
            safe_run(fmt.tprintf("podman cp %s %s:%s", host, cfg.name, cfg_path))
        }
    }
    // Sync tools (tymczasowe bind-mounty przy enter – zrobione w env_enter)
    fmt.printfln("%sŚrodowisko %s zostało utworzone pomyślnie!%s", Colors.green, cfg.name, Colors.reset)
}
// =============================================
// REMOVE
// =============================================
env_remove :: proc(name: string) {
    safe_run(fmt.tprintf("podman rm -f %s 2>/dev/null || true", name))
    fmt.printfln("%sŚrodowisko %s zostało usunięte.%s", Colors.green, name, Colors.reset)
}
// =============================================
// ENTER (z tymczasowym podpinaniem narzędzi)
// =============================================
env_enter :: proc(name: string) {
    container := name
    if container == "" {
        // lista wszystkich hacker-env
        safe_run(`podman ps -a --filter "label=hacker-env=true" --format "{{.Names}}"`)
        return
    }
    // Przygotowanie tymczasowych mountów narzędzi
    mount_flags := ""
    // TODO: wczytaj sync_tools z configu (na razie hardcoded przykład)
    mount_flags = `-v /usr/bin/nvim:/usr/bin/nvim:ro -v ~/.local/share/nvim:/root/.local/share/nvim`
    enter_cmd := fmt.tprintf("podman start %s 2>/dev/null || true && podman exec -it %s %s", container, mount_flags, "zsh || bash")
    safe_run(enter_cmd)
}
// =============================================
// DOCS + SETTINGS + HELP
// =============================================
env_docs :: proc(lang: string) {
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
    fmt.printfln("%sLista wszystkich środowisk Hacker env:%s", Colors.magenta, Colors.reset)
    safe_run(`podman ps -a --filter "label=hacker-env=true" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"`)
}
show_env_help :: proc(lang: string) {
    trans := get_translations_main(lang)
    fmt.printfln("%s%s%s%s", Colors.bold, Colors.magenta, "Podkomendy env:", Colors.reset)
    fmt.printfln(" %screate <plik.hk|plik.yaml> %s- Utwórz nowe środowisko z pliku", Colors.gray, Colors.reset)
    fmt.printfln(" %sremove <nazwa> %s- Usuń środowisko", Colors.gray, Colors.reset)
    fmt.printfln(" %senter [nazwa] %s- Wejdź do środowiska (z podpiętymi narzędziami)", Colors.gray, Colors.reset)
    fmt.printfln(" %sdocs %s- Pełny tutorial + przykłady", Colors.gray, Colors.reset)
    fmt.printfln(" %ssettings %s- Lista wszystkich środowisk", Colors.gray, Colors.reset)
}
// =============================================
// Prosty parser .hk (używa hk-parser przez foreign jeśli dostępny)
// =============================================
parse_env_file :: proc(path: string) -> EnvConfig {
    cfg: EnvConfig
    cfg.sync_tools = make(map[string][dynamic]string)
    // fallback – prosty parser stringowy (działa na większości plików)
    data, ok := os.read_entire_file(path)
    if !ok { return cfg }
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
                            // obsługa prostego przypadku: -> snap => nvim,code
                            tool_type := key
                            tools := strings.split(val, ",")
                            for &t in tools {
                                t = strings.trim(t, " \"'")
                                if t != "" {
                                    if tool_type not_in cfg.sync_tools {
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

