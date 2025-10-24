from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.tree import Tree
from prompt_toolkit import PromptSession
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.styles import Style
import subprocess
import sys
import os

console = Console()

commands = [
    "unpack addons", "unpack gs", "unpack devtools", "unpack emulators", "unpack cybersecurity",
    "unpack select", "unpack gaming", "unpack noroblox", "unpack hackermode",
    "help", "install", "remove", "apt-install", "apt-remove",
    "flatpak-install", "flatpak-remove", "flatpak-update",
    "system logs",
    "run hackeros-cockpit", "run switch-to-other-session", "run update-system", "run check-updates",
    "run steam", "run hacker-launcher", "run hackeros-game-mode",
    "update", "game", "hacker-lang", "ascii", "shell", "exit"
]

completer = WordCompleter(commands, ignore_case=True)

style = Style.from_dict({
    'prompt': 'cyan bold',
})

def display_command_list():
    console.clear()
    title = Text("Hacker Shell - Commands", style="bold magenta")
    tree = Tree("Available Commands", style="bold green")

    unpack = tree.add("unpack: Unpack various toolsets", style="cyan")
    unpack.add("addons, gs, devtools, emulators, cybersecurity, select, gaming, noroblox, hackermode")

    tree.add("help: Display help")
    tree.add("install <package>")
    tree.add("remove <package>")
    tree.add("apt-install <package>")
    tree.add("apt-remove <package>")
    tree.add("flatpak-install <package>")
    tree.add("flatpak-remove <package>")
    tree.add("flatpak-update")

    system = tree.add("system: System commands", style="cyan")
    system.add("logs")

    run = tree.add("run: Run scripts", style="cyan")
    run.add("hackeros-cockpit, switch-to-other-session, update-system, check-updates, steam, hacker-launcher, hackeros-game-mode")

    tree.add("update")
    tree.add("game")
    tree.add("hacker-lang")
    tree.add("ascii")
    tree.add("shell")
    tree.add("exit: Exit the shell")

    panel = Panel(tree, title=title, expand=False, border_style="green")
    console.print(panel)

def run_hacker_command(cmd):
    if cmd.strip() == "":
        return
    if cmd == "exit":
        sys.exit(0)
    try:
        result = subprocess.run(["hacker"] + cmd.split(), capture_output=True, text=True)
        if result.returncode == 0:
            console.print(result.stdout, style="green")
        else:
            console.print(result.stderr, style="red")
    except Exception as e:
        console.print(f"Error executing command: {e}", style="red")

def main():
    session = PromptSession(completer=completer, style=style)
    while True:
        display_command_list()
        try:
            cmd = session.prompt('> ')
            run_hacker_command(cmd)
        except KeyboardInterrupt:
            continue
        except EOFError:
            break

if __name__ == "__main__":
    main()

