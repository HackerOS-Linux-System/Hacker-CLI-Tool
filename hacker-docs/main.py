from textual.app import App, on
from textual import events
from textual.widgets import ListView, ListItem, Label, Markdown, Input, Footer, Header
from textual.containers import Horizontal, Vertical

faqs = [
    {
        "question": "Jak instalować pakiety na HackerOS?",
        "answer": "Użyj 'hacker install {nazwa pakietu}' lub 'sudo apt install {nazwa pakietu}' lub możesz użyć aplikacji Software (GNOME Software).",
    },
    {
        "question": "Jak usuwać pakiety?",
        "answer": "Użyj 'hacker remove {nazwa pakietu}' lub 'sudo apt remove {nazwa pakietu}' lub możesz użyć aplikacji Software (GNOME Software).",
    },
    {
        "question": "Jak zaktualizować system?",
        "answer": "Polecane dla HackerOS: użyj aplikacji 'Update System' lub komendy 'hacker update'.",
    },
    {
        "question": "Skąd mogę zdobyć oprogramowanie?",
        "answer": "Instaluj za pomocą 'hacker unpack {nazwa zestawu}' lub 'hacker unpack select' aby wybrać konkretne aplikacje. Możesz również instalować za pomocą apt, snap lub flatpak.",
    },
    {
        "question": "Co to jest HackerOS?",
        "answer": "HackerOS to dystrybucja Linux oparta na debianie testowym, skupiona na gamingu, cybersecurity i narzędziach dla hackerów.",
    },
    {
        "question": "Jak zmienić hasło?",
        "answer": "Użyj komendy 'passwd' w terminalu.",
    },
    {
        "question": "Jak zrestartować system?",
        "answer": "Użyj 'sudo reboot' lub wybierz opcję restartu z menu.",
    },
    {
        "question": "Jak zainstalować sterowniki GPU dla NVIDIA?",
        "answer": "Użyj 'sudo apt install nvidia-driver' i zrestartuj system.",
    },
    {
        "question": "Co to jest distrobox?",
        "answer": "Distrobox to narzędzie do tworzenia i zarządzania kontenerami z innymi dystrybucjami Linuxa w twoim systemie.",
    },
    {
        "question": "Jak uruchomić aplikację Windows na HackerOS?",
        "answer": "Zainstaluj Wine za pomocą 'hacker unpack add-ons' i użyj 'wine {plik.exe}'.",
    },
    {
        "question": "Jak skonfigurować cybersecurity tools?",
        "answer": "Użyj 'hacker unpack cybersecurity' aby ustawić kontener z BlackArch tools.",
    },
    {
        "question": "Jak grać w gry na HackerOS?",
        "answer": "Zainstaluj gaming tools za pomocą 'hacker unpack gaming' i użyj Steam, Lutris lub Heroic Games Launcher.",
    },
    {
        "question": "Jak sprawdzić logi systemowe?",
        "answer": "Użyj 'hacker system logs' lub 'journalctl -xe'.",
    },
    {
        "question": "Jak wejść do kontenera distrobox?",
        "answer": "Użyj 'hacker enter {nazwa kontenera}'.",
    },
]

all_items = [
    {"question": "Exit", "answer": "Press to exit", "idx": -1}
] + [{"question": f["question"], "answer": f["answer"], "idx": i} for i, f in enumerate(faqs)]

placeholder = "Select a question from the list to view the answer.\n\nPress 'enter' to select, 'esc' to go back, 'q' to quit."

class FAQApp(App):
    BINDINGS = [
        ("q", "quit_app", "Quit"),
    ]

    def compose(self):
        yield Header()
        yield Horizontal(
            Vertical(
                Label("HackerOS Documentation & FAQ"),
                Input(placeholder="Filter questions...", id="search"),
                ListView(id="faq_list"),
                id="left",
            ),
            Vertical(
                Markdown(id="details"),
                id="right",
            ),
        )
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#details").update(placeholder)
        self.refresh_list("")
        self.query_one(ListView).focus()
        # Add some basic styles
        self.query_one("#left").styles.border_right = ("solid", "white")
        self.query_one("#right").styles.border = ("solid", "white")
        self.query_one("#right").styles.padding = 1

    def refresh_list(self, query: str) -> None:
        lv = self.query_one("#faq_list")
        lv.clear()
        for item in all_items:
            if query.lower() in item["question"].lower():
                if item["idx"] == -1:
                    lv.append(ListItem(Label(item["question"]), name="exit"))
                else:
                    lv.append(ListItem(Label(item["question"]), name=str(item["idx"])))

    @on(Input.Changed, "#search")
    def on_search_changed(self, event: Input.Changed) -> None:
        self.refresh_list(event.value)

    @on(ListView.Selected)
    def show_details(self, event: ListView.Selected) -> None:
        md = self.query_one(Markdown)
        if event.item.name == "exit":
            self.exit()
            return
        idx = int(event.item.name)
        md.update(faqs[idx]["answer"])
        md.scroll_home(animate=False)
        md.focus()

    def on_key(self, event: events.Key) -> None:
        if event.key == "escape":
            if self.query_one(Markdown).has_focus:
                self.query_one(Markdown).update(placeholder)
                self.query_one(ListView).focus()

    def action_quit_app(self) -> None:
        self.exit()

if __name__ == "__main__":
    FAQApp().run()
