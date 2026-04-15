import subprocess
import sys
import os
import json
import shutil
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.table import Table
    from rich.columns import Columns
    from rich.rule import Rule
    from rich import box
    from prompt_toolkit import PromptSession
    from prompt_toolkit.completion import WordCompleter, Completer, Completion
    from prompt_toolkit.styles import Style
    from prompt_toolkit.history import FileHistory
    from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
    from prompt_toolkit.key_binding import KeyBindings
except ImportError:
    print("[ERROR] Brak wymaganych modułów. Uruchom: pip install rich prompt_toolkit")
    sys.exit(1)

# ─── Ścieżki ───────────────────────────────────────────────────────────────────
HOME = Path.home()
HACKEROS_DIR = HOME / ".hackeros" / "hacker"
CONFIG_DIR = HOME / ".config" / "hackeros" / "hacker"
HISTORY_FILE = CONFIG_DIR / "shell_history"
LOOK_FILE = CONFIG_DIR / "look.json"

CONFIG_DIR.mkdir(parents=True, exist_ok=True)

# ─── Schemat kolorów z look.json ──────────────────────────────────────────────

DEFAULT_LOOK = {
    "accent":  "#c026d3",
    "success": "#22c55e",
    "error":   "#ef4444",
    "warning": "#eab308",
    "info":    "#06b6d4",
    "dim":     "#475569",
}

def load_look() -> dict:
    if LOOK_FILE.exists():
        try:
            with open(LOOK_FILE) as f:
                data = json.load(f)
            return {**DEFAULT_LOOK, **data}
        except Exception:
            pass
    return DEFAULT_LOOK.copy()

LOOK = load_look()

# ─── Definicje komend ──────────────────────────────────────────────────────────

COMMANDS = {
    # ── Pakiety ──
    "install":          "Zainstaluj pakiet APT",
    "remove":           "Usuń pakiet APT",
    "flatpak-install":  "Zainstaluj pakiet Flatpak",
    "flatpak-remove":   "Usuń pakiet Flatpak",
    # ── Unpack ──
    "unpack add-ons":                  "Wine, BoxBuddy, WineZGUI, GearLever",
    "unpack gaming":                   "Steam, Heroic, ProtonPlus…",
    "unpack gaming with-roblox":       "Gaming + Roblox (Sober, Vinegar)",
    "unpack devtools":                 "VS Code, Rust, Go, Node, Zig…",
    "unpack emulators":                "shadPS4, Ryujinx, DOSBox-X, RPCS3",
    "unpack cybersecurity":            "Kontener BlackArch",
    "unpack select":                   "Interaktywny wybór (TUI)",
    "unpack hacker-mode":              "Tryb Hacker-Mode (Wayland)",
    "unpack gamescope-session-steam":  "Steam GameMode (gamescope)",
    "unpack automatic-updates":        "Włącz auto-aktualizacje (hup)",
    "unpack alacritty-config":         "Konfiguracja Alacritty",
    "unpack nvidia-drivers":           "Sterowniki NVIDIA",
    "unpack hackeros-containers":      "Kontenery HackerOS",
    "unpack h#":                       "H# (H-Sharp) — język HackerOS",
    "unpack h#-utils":                 "Narzędzia pomocnicze H#",
    "unpack flox":                     "Flox — menedżer środowisk",
    "unpack hammer":                   "Hammer — atomowy menedżer pakietów",
    "unpack lpm":                      "LPM — następca apt",
    "unpack isolator":                 "Isolator — pakiety w kontenerach",
    "unpack hexai":                    "HexAi — AI dla HackerOS",
    "unpack hackerdeck":               "HackerDeck — nakładka Waydroid",
    "unpack hackeros-games-addons":    "Dodatki do gier HackerOS",
    "unpack hackeros-tv":              "HackerOS TV",
    "unpack winboat":                  "Winboat",
    "unpack hydra":                    "Motyw Hydra Look-and-Feel",
    "unpack hackeros-builder":         "HackerOS Builder",
    # ── Pack ──
    "pack add-ons":                    "Usuń Wine i dodatki",
    "pack gaming":                     "Usuń narzędzia do gier",
    "pack devtools":                   "Usuń narzędzia deweloperskie",
    "pack emulators":                  "Usuń emulatory",
    "pack cybersecurity":              "Usuń kontener BlackArch",
    "pack hacker-mode":                "Usuń Hacker-Mode",
    "pack automatic-updates":          "Wyłącz auto-aktualizacje",
    "pack nvidia-drivers":             "Usuń sterowniki NVIDIA",
    "pack h#":                         "Usuń H# (H-Sharp)",
    "pack h#-utils":                   "Usuń narzędzia H#",
    "pack hammer":                     "Usuń Hammer",
    "pack lpm":                        "Usuń LPM",
    "pack hexai":                      "Usuń HexAi",
    "pack hackerdeck":                 "Usuń HackerDeck",
    "pack hackeros-containers":        "Usuń kontenery HackerOS",
    "pack hackeros-games-addons":      "Usuń dodatki do gier",
    # ── Env ──
    "env create":    "Utwórz środowisko z pliku .hk",
    "env remove":    "Usuń środowisko",
    "env enter":     "Wejdź do środowiska",
    "env settings":  "Lista środowisk",
    "env docs":      "Tutorial środowisk",
    # ── System ──
    "update":                  "Aktualizacja systemu (TUI)",
    "update --with-gui":       "Aktualizacja w nowym oknie",
    "system logs":             "Logi systemowe (journalctl)",
    "switch hacker-mode":      "Przełącz na Hacker-Mode",
    "switch steam-gamemode":   "Przełącz na Steam GameMode",
    "restart":                 "Restart usługi systemd",
    "doctor":                  "Diagnostyka systemu",
    # ── Run ──
    "run update-system":        "Skrypt aktualizacji",
    "run check-updates":        "Sprawdź aktualizacje",
    "run steam":                "Uruchom Steam",
    "run hacker-launcher":      "Hacker Launcher",
    "run hackeros-game-mode":   "HackerOS Game Mode",
    "run HackerOS-Store":       "Sklep HackerOS",
    "run HackerDeck":           "HackerDeck",
    "run Hacker-Term":          "Terminal HackerOS",
    "run update-hackeros":      "Aktualizuj HackerOS",
    "run update-wallpapers":    "Aktualizuj tapety",
    # ── Pluginy ──
    "plugin list":    "Lista pluginów",
    "plugin enable":  "Włącz plugin",
    "plugin disable": "Wyłącz plugin",
    "plugin info":    "Info o pluginie",
    # ── Enable/Disable ──
    "enable motd":         "Włącz MOTD",
    "enable special-motd": "Włącz specjalny MOTD",
    "disable motd":        "Wyłącz MOTD",
    # ── Settings ──
    "settings language":           "Zmień język interfejsu",
    "settings look":               "Pokaż schemat kolorów",
    "settings look preset":        "Zastosuj preset kolorów",
    "settings look set":           "Ustaw konkretny kolor",
    "settings look reset":         "Przywróć domyślne kolory",
    "settings look show":          "Pokaż bieżące kolory",
    # ── Inne ──
    "languages":               "Info o językach programowania HackerOS",
    "game":                    "Tekstowa gra przygodowa",
    "ascii":                   "Logo HackerOS ASCII",
    "enter":                   "Wejdź do kontenera distrobox",
    "remove-container":        "Usuń kontener distrobox",
    "index":                   "Indeks narzędzi HackerOS",
    "info":                    "Wersje narzędzia i systemu",
    "issue":                   "Zgłoś błąd na GitHub",
    "how-to-create-commands":  "Jak tworzyć własne komendy",
    # ── Shell ──
    "help":       "Pokaż tę pomoc",
    "clear":      "Wyczyść ekran",
    "exit":       "Wyjdź z hacker-shell",
    "quit":       "Wyjdź z hacker-shell",
}

# Grupowanie komend do wyświetlania
GROUPS = {
    "📦 Pakiety":    ["install", "remove", "flatpak-install", "flatpak-remove"],
    "📥 Unpack":     [k for k in COMMANDS if k.startswith("unpack ")],
    "📤 Pack":       [k for k in COMMANDS if k.startswith("pack ")],
    "🐳 Env":        [k for k in COMMANDS if k.startswith("env ")],
    "⚙️  System":    ["update", "update --with-gui", "system logs", "switch hacker-mode",
                      "switch steam-gamemode", "restart", "doctor"],
    "▶️  Run":        [k for k in COMMANDS if k.startswith("run ")],
    "🔌 Pluginy":    [k for k in COMMANDS if k.startswith("plugin ")],
    "🎨 Settings":   [k for k in COMMANDS if k.startswith("settings ")],
    "🔧 Narzędzia":  ["languages", "game", "ascii", "enter", "remove-container",
                      "index", "info", "issue", "how-to-create-commands"],
    "🖥️  Shell":      ["help", "clear", "exit", "quit"],
}

# ─── Rich Console ──────────────────────────────────────────────────────────────

console = Console()

# ─── Smart Completer ──────────────────────────────────────────────────────────

class HackerCompleter(Completer):
    """Autouzupełnianie z opisami komend."""
    def __init__(self):
        self.commands = list(COMMANDS.keys())

    def get_completions(self, document, complete_event):
        word = document.text_before_cursor.lstrip()
        # Usuń prefix 'hacker ' jeśli wpisany
        if word.startswith("hacker "):
            word = word[7:]
        for cmd in self.commands:
            if cmd.startswith(word):
                suffix = cmd[len(word):]
                desc = COMMANDS.get(cmd, "")
                yield Completion(
                    suffix,
                    start_position=0,
                    display=cmd,
                    display_meta=desc,
                )

# ─── Prompt style ─────────────────────────────────────────────────────────────

def make_prompt_style():
    accent = LOOK["accent"]
    dim = LOOK["dim"]
    return Style.from_dict({
        "prompt.user":   f"bold {accent}",
        "prompt.arrow":  f"bold {accent}",
        "prompt.dim":    dim,
        "completion-menu.completion":         f"bg:#1a1a24 {dim}",
        "completion-menu.completion.current": f"bg:#2a2a3a bold {accent}",
        "completion-menu.meta.completion":         f"bg:#0d0d0f {dim}",
        "completion-menu.meta.completion.current": f"bg:#1a1a24 {dim}",
    })

# ─── Wyświetlanie pomocy ───────────────────────────────────────────────────────

def show_help():
    console.print()
    console.print(Rule(f"[bold {LOOK['accent']}]hacker-shell — dostępne komendy[/]"))
    console.print()

    for group_name, cmds in GROUPS.items():
        table = Table(
            show_header=False,
            box=None,
            padding=(0, 1),
            expand=False,
        )
        table.add_column("cmd", style=f"{LOOK['info']}", no_wrap=True, min_width=32)
        table.add_column("desc", style=f"{LOOK['dim']}")

        for cmd in cmds:
            if cmd in COMMANDS:
                table.add_row(cmd, COMMANDS[cmd])

        panel = Panel(
            table,
            title=f"[bold {LOOK['accent']}]{group_name}[/]",
            border_style=LOOK["dim"],
            padding=(0, 1),
        )
        console.print(panel)

    console.print()
    console.print(f"[{LOOK['dim']}]  Tip: komendy wykonywane są jako 'hacker <cmd>'[/]")
    console.print(f"[{LOOK['dim']}]  Tab — autouzupełnianie  ·  ↑↓ — historia  ·  Ctrl+C — przerwij  ·  Ctrl+D — wyjdź[/]")
    console.print()

# ─── Wykonywanie komend ────────────────────────────────────────────────────────

def run_hacker_command(cmd: str) -> int:
    """Wykonaj 'hacker <cmd>' i zwróć kod wyjścia."""
    # Specjalne komendy powłoki
    if cmd in ("exit", "quit"):
        show_goodbye()
        sys.exit(0)
    if cmd == "help":
        show_help()
        return 0
    if cmd == "clear":
        os.system("clear")
        return 0
    if cmd == "":
        return 0

    # Usuń prefix 'hacker ' jeśli użytkownik wpisał pełną komendę
    if cmd.startswith("hacker "):
        cmd = cmd[7:]

    # Wygeneruj pełną komendę
    full_cmd = f"hacker {cmd}"
    console.print(f"[{LOOK['dim']}]  ❯ {full_cmd}[/]")
    console.print()

    try:
        result = subprocess.run(full_cmd, shell=True)
        return result.returncode
    except KeyboardInterrupt:
        console.print(f"\n[{LOOK['warning']}]  Przerwano.[/]")
        return 130
    except Exception as e:
        console.print(f"[{LOOK['error']}]  Błąd: {e}[/]")
        return 1

def show_goodbye():
    console.print(f"\n[bold {LOOK['accent']}]  Do zobaczenia, hakerze! 👋[/]\n")

# ─── Banner powitalny ──────────────────────────────────────────────────────────

def show_banner():
    os.system("clear")
    accent = LOOK["accent"]
    dim = LOOK["dim"]
    info = LOOK["info"]

    banner = Text()
    banner.append("  ⬡  hacker", style=f"bold {accent}")
    banner.append("-shell", style=f"{dim}")
    banner.append("  —  interaktywna powłoka HackerOS\n", style=f"{dim}")
    banner.append(f"  wpisz ", style=f"{dim}")
    banner.append("help", style=f"bold {info}")
    banner.append(" aby zobaczyć listę komend  ·  ", style=f"{dim}")
    banner.append("Tab", style=f"bold {info}")
    banner.append(" autouzupełnianie  ·  ", style=f"{dim}")
    banner.append("Ctrl+D", style=f"bold {info}")
    banner.append(" wyjście", style=f"{dim}")

    console.print(Panel(
        banner,
        border_style=accent,
        padding=(0, 1),
    ))
    console.print()

# ─── Main ──────────────────────────────────────────────────────────────────────

def main():
    show_banner()

    # Key bindings
    bindings = KeyBindings()

    @bindings.add("c-d")
    def _(event):
        show_goodbye()
        event.app.exit()

    session = PromptSession(
        history=FileHistory(str(HISTORY_FILE)),
        completer=HackerCompleter(),
        auto_suggest=AutoSuggestFromHistory(),
        style=make_prompt_style(),
        key_bindings=bindings,
        complete_while_typing=True,
        mouse_support=False,
    )

    accent = LOOK["accent"]
    success = LOOK["success"]
    error = LOOK["error"]
    dim = LOOK["dim"]

    while True:
        try:
            # Prompt: "hacker ❯ "
            raw = session.prompt([
                ("class:prompt.user",  " hacker "),
                ("class:prompt.arrow", "❯ "),
            ])
            cmd = raw.strip()
            if not cmd:
                continue

            exit_code = run_hacker_command(cmd)

            if exit_code == 0:
                console.print(f"[{dim}]  ✓ OK  (exit 0)[/]\n")
            elif exit_code == 130:
                pass  # Ctrl+C — już obsłużone
            else:
                console.print(f"[{error}]  ✗ Błąd (exit {exit_code})[/]\n")

        except KeyboardInterrupt:
            console.print(f"\n[{dim}]  (Ctrl+C — wpisz 'exit' aby wyjść)[/]\n")
            continue
        except EOFError:
            show_goodbye()
            break

if __name__ == "__main__":
    main()
