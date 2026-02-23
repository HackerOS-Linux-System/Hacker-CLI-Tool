use indicatif::{ProgressBar, ProgressStyle};
use std::io::{self, BufRead, Write};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use colored::*;

// ─────────────────────────────────────────────────────────────────────────────
// FAZY
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
enum Phase {
    Init        = 0,
    Reading     = 10,
    Resolving   = 25,
    Downloading = 40,
    Fetched     = 62,
    Unpacking   = 70,
    Setting     = 87,
    Processing  = 95,
    Done        = 100,
}

impl Phase {
    fn label(self) -> &'static str {
        match self {
            Phase::Init        => "Inicjalizacja...",
            Phase::Reading     => "Czytanie list pakietow...",
            Phase::Resolving   => "Rozwiazywanie zaleznosci...",
            Phase::Downloading => "Pobieranie pakietow...",
            Phase::Fetched     => "Pobieranie zakonczone",
            Phase::Unpacking   => "Rozpakowywanie...",
            Phase::Setting     => "Konfigurowanie...",
            Phase::Processing  => "Przetwarzanie wyzwalaczy...",
            Phase::Done        => "Gotowe",
        }
    }

    fn from_line(line: &str) -> Option<Phase> {
        let t = line.trim();
        if t.starts_with("Czytanie") || t.starts_with("Budowanie") || t.starts_with("Odczyt")
            || t.starts_with("Reading") || t.starts_with("Building") || t.starts_with("Scanning")
            {
                Some(Phase::Reading)
            } else if t.starts_with("Rozwiaz") || t.starts_with("Calculating")
                || t.starts_with("The following") || t.starts_with("Nastepujace")
                || t.starts_with("Podsumowanie")  || t.starts_with("After this")
                {
                    Some(Phase::Resolving)
                } else if t.starts_with("Get:") || t.starts_with("Pobieranie:") {
                    Some(Phase::Downloading)
                } else if t.starts_with("Fetched") || t.starts_with("Pobrano")
                    || t.starts_with("0 upgraded") || t.starts_with("0 aktualizowanych")
                    {
                        Some(Phase::Fetched)
                    } else if t.starts_with("Unpacking") || t.starts_with("Rozpakowywanie")
                        || t.starts_with("Removing")    || t.starts_with("Usuwanie")
                        {
                            Some(Phase::Unpacking)
                        } else if t.starts_with("Setting up") || t.starts_with("Ustawianie") {
                            Some(Phase::Setting)
                        } else if t.starts_with("Processing") || t.starts_with("Przetwarzanie") {
                            Some(Phase::Processing)
                        } else {
                            None
                        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI
// ─────────────────────────────────────────────────────────────────────────────

fn print_banner() {
    println!();
    println!("{}", "  +====================================================+".bright_blue().bold());
    println!("{}", "  |                                                    |".bright_blue().bold());
    println!(
        "  {}{}{}",
        "|".bright_blue().bold(),
             "          APT Package Manager v2.3               ".white().bold(),
             "|".bright_blue().bold()
    );
    println!("{}", "  |                                                    |".bright_blue().bold());
    println!("{}", "  +====================================================+".bright_blue().bold());
    println!();
}

fn print_sep() {
    println!("{}", "  ----------------------------------------------------".bright_black());
}

fn print_usage() {
    println!();
    println!("{}", "  Uzycie:".bright_white().bold());
    println!("    apt-frontend install <pakiet>   - zainstaluj pakiet");
    println!("    apt-frontend remove  <pakiet>   - usun pakiet");
    println!("    apt-frontend update             - aktualizuj liste pakietow");
    println!("    apt-frontend upgrade            - aktualizuj system");
    println!("    apt-frontend search  <fraza>    - wyszukaj pakiet");
    println!("    apt-frontend show    <pakiet>   - info o pakiecie");
    println!("    apt-frontend help               - ta pomoc");
    println!();
}

fn colorize(line: &str) -> ColoredString {
    let t = line.trim();
    if t.starts_with("Get:") || t.starts_with("Hit:") {
        line.bright_cyan()
    } else if t.starts_with("Fetched") || t.starts_with("Pobrano") {
        line.bright_green()
    } else if t.starts_with("Unpacking") || t.starts_with("Rozpakowywanie") {
        line.bright_yellow()
    } else if t.starts_with("Setting up")  || t.starts_with("Ustawianie")
        || t.starts_with("Processing")  || t.starts_with("Przetwarzanie")
        {
            line.bright_magenta()
        } else if t.starts_with("Removing") || t.starts_with("Usuwanie") {
            line.red()
        } else if t.starts_with("Czytanie") || t.starts_with("Budowanie")
            || t.starts_with("Odczyt")   || t.starts_with("Reading")
            || t.starts_with("Building") || t.starts_with("Scanning")
            {
                line.bright_black()
            } else if t.to_lowercase().contains("error")   || t.to_lowercase().contains("failed")
                || t.to_lowercase().contains("blad")    || t.to_lowercase().contains("nie udalo")
                {
                    line.bright_red().bold()
                } else if t.to_lowercase().contains("warning") || t.to_lowercase().contains("ostrzez") {
                    line.yellow()
                } else {
                    line.white()
                }
}

// ─────────────────────────────────────────────────────────────────────────────
// POTWIERDZENIE y/n
// ─────────────────────────────────────────────────────────────────────────────

/// Pyta uzytkownika o potwierdzenie. Zwraca true jesli wpisano 't', 'y', lub Enter.
fn confirm(prompt: &str) -> bool {
    loop {
        print!("  {} {} ", "?".bright_yellow().bold(), prompt);
        print!("{}", "[t/n]: ".bright_white());
        io::stdout().flush().ok();

        let mut input = String::new();
        if io::stdin().read_line(&mut input).is_err() {
            return false;
        }
        match input.trim().to_lowercase().as_str() {
            "t" | "y" | "tak" | "yes" | "" => return true,
            "n" | "nie" | "no"             => return false,
            _ => {
                println!("  {} Wpisz {} lub {}.", "!".yellow(), "t".green().bold(), "n".red().bold());
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUDO
// ─────────────────────────────────────────────────────────────────────────────

fn ensure_sudo() -> bool {
    let already_auth = Command::new("sudo")
    .args(["-n", "true"])
    .stdout(Stdio::null())
    .stderr(Stdio::null())
    .status()
    .map(|s| s.success())
    .unwrap_or(false);

    if already_auth {
        return true;
    }

    println!();
    println!("  {}", "[sudo] Wymagane uprawnienia administratora.".yellow().bold());
    println!();

    let status = Command::new("sudo")
    .args(["-v"])
    .stdin(Stdio::inherit())
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .status();

    match status {
        Ok(s) if s.success() => {
            println!();
            true
        }
        _ => {
            println!();
            println!("  {}", "[BLAD] Uwierzytelnienie nie powiodlo sie.".bright_red().bold());
            false
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASEK POSTEPU
// ─────────────────────────────────────────────────────────────────────────────

fn make_bar(prefix: &str, color: &str) -> ProgressBar {
    let bar = ProgressBar::new(100);
    let tpl = match color {
        "red"    => "  {prefix:<14}  [{bar:46.red/black}]  {pos:>3}%  {msg:.bright_black}",
        "yellow" => "  {prefix:<14}  [{bar:46.yellow/black}]  {pos:>3}%  {msg:.bright_black}",
        "green"  => "  {prefix:<14}  [{bar:46.green/black}]  {pos:>3}%  {msg:.bright_black}",
        _        => "  {prefix:<14}  [{bar:46.cyan/black}]  {pos:>3}%  {msg:.bright_black}",
    };
    bar.set_style(
        ProgressStyle::with_template(tpl)
        .unwrap()
        .progress_chars("=>-"),
    );
    bar.set_prefix(prefix.to_string());
    bar.set_message("czekam...");
    bar
}

// ─────────────────────────────────────────────────────────────────────────────
// URUCHOMIENIE APT
// ─────────────────────────────────────────────────────────────────────────────

/// Zwraca true jesli operacja sie powiodla.
fn run_apt(apt_args: &[&str], bar_prefix: &str, bar_color: &str) -> bool {
    let bar = make_bar(bar_prefix, bar_color);
    bar.set_position(0);

    let phase:    Arc<Mutex<Phase>>       = Arc::new(Mutex::new(Phase::Init));
    let get_seen: Arc<Mutex<u64>>         = Arc::new(Mutex::new(0));
    let log:      Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));
    let errors:   Arc<Mutex<Vec<String>>> = Arc::new(Mutex::new(Vec::new()));

    // stdbuf -oL wymusza line-buffering zeby apt nie trzymal buforow
    let mut cmd_args = vec!["stdbuf", "-oL", "-eL", "sudo", "apt"];
    cmd_args.extend_from_slice(apt_args);
    cmd_args.push("-y");

    let mut child = match Command::new(cmd_args[0])
    .args(&cmd_args[1..])
    .stdout(Stdio::piped())
    .stderr(Stdio::piped())
    .stdin(Stdio::null())
    .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            bar.finish_and_clear();
            println!();
            print_sep();
            println!("  {} Nie mozna uruchomic apt: {}", "[BLAD]".bright_red().bold(), e);
            print_sep();
            println!();
            return false;
        }
    };

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let bar_c   = bar.clone();
    let phase_c = Arc::clone(&phase);
    let get_c   = Arc::clone(&get_seen);
    let log_c   = Arc::clone(&log);

    let stdout_t = thread::spawn(move || {
        let reader = io::BufReader::new(stdout);
        for raw in reader.lines() {
            let Ok(line) = raw else { continue };
            let t = line.trim();
            if t.is_empty() { continue; }

            if let Some(new_phase) = Phase::from_line(t) {
                let mut ph = phase_c.lock().unwrap();
                if new_phase > *ph {
                    *ph = new_phase;
                    bar_c.set_position(new_phase as u64);
                    bar_c.set_message(new_phase.label().to_string());
                }
            }

            // Plynna interpolacja w fazie Downloading (40..62)
            if t.starts_with("Get:") {
                let words: Vec<&str> = t.split_whitespace().collect();
                if let Some(n_str) = words.first().and_then(|w| w.strip_prefix("Get:")) {
                    if let Ok(n) = n_str.parse::<u64>() {
                        let mut gs = get_c.lock().unwrap();
                        if n > *gs { *gs = n; }
                        let frac = (n as f64) / (*gs as f64).max(1.0);
                        let pos  = (40 + (frac * 22.0) as u64).min(61);
                        bar_c.set_position(pos);
                        let pkg = words.get(3).copied().unwrap_or("...");
                        bar_c.set_message(format!("pobieranie: {}", pkg));
                    }
                }
            }

            log_c.lock().unwrap().push(format!("    {}", colorize(&line)));
        }
    });

    let errors_c = Arc::clone(&errors);
    let stderr_t = thread::spawn(move || {
        let reader = io::BufReader::new(stderr);
        for raw in reader.lines() {
            if let Ok(line) = raw {
                let t = line.trim();
                if t.is_empty() { continue; }
                if t.contains("apt does not have a stable CLI") { continue; }
                errors_c.lock().unwrap().push(t.to_string());
            }
        }
    });

    let status = child.wait().expect("Failed to wait for apt");
    stdout_t.join().unwrap();
    stderr_t.join().unwrap();

    if status.success() {
        bar.set_position(100);
        bar.set_message(Phase::Done.label().to_string());
    }
    thread::sleep(Duration::from_millis(500));
    bar.finish_and_clear();

    // ── Wynik / log ──────────────────────────────────────────────────────────
    println!();
    print_sep();
    println!("  {}", "Wynik:".bright_black());
    println!();
    for line in log.lock().unwrap().iter() {
        println!("{}", line);
    }

    let errs = errors.lock().unwrap();
    if !errs.is_empty() {
        println!();
        println!("  {}", "Szczegoly bledow:".yellow().bold());
        for e in errs.iter() {
            println!("    {} {}", "!".yellow(), e.yellow());
        }
    }
    drop(errs);

    println!();
    print_sep();
    println!();

    if status.success() {
        let nothing_done = log.lock().unwrap().iter().any(|l| {
            l.contains("0 aktualizowanych, 0 instalowanych, 0 usuwanych")
            || l.contains("0 upgraded, 0 newly installed, 0 to remove")
        });
        if nothing_done {
            println!(
                "  {}  {}",
                "[ INFO ]".on_bright_black().white().bold(),
                     "Nic do zrobienia — pakiet juz jest w wymaganym stanie.".bright_black().bold()
            );
        } else {
            println!(
                "  {}  {}",
                "[  OK  ]".on_green().white().bold(),
                     "Operacja zakonczona pomyslnie.".green().bold()
            );
        }
        println!();
        return true;
    } else {
        let code = status.code().map(|c| c.to_string()).unwrap_or_else(|| "?".into());
        println!(
            "  {}  {}",
            "[ BLAD ]".on_red().white().bold(),
                 format!("Operacja nie powiodla sie (kod wyjscia: {}).", code).red().bold()
        );
        println!();
        println!("  {}", "Wskazowki:".bright_black());
        println!("    - Sprawdz czy pakiet istnieje:  apt-frontend search <nazwa>");
        println!("    - Napraw zaleznosci:             sudo apt --fix-broken install");
        println!("    - Sprawdz logi powyzej");
        println!();
        return false;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTOREMOVE — uruchamiany automatycznie po remove
// ─────────────────────────────────────────────────────────────────────────────

fn run_autoremove() {
    // Sprawdz czy jest cos do usuniecia
    let check = Command::new("apt-get")
    .args(["--dry-run", "autoremove"])
    .stdout(Stdio::piped())
    .stderr(Stdio::null())
    .output();

    let has_orphans = match check {
        Ok(out) => {
            let text = String::from_utf8_lossy(&out.stdout);
            // Jesli apt wypisuje pakiety do usuniecia, bedzie "0 nie aktualizowanych" ALE
            // kluczowa linia to "X packages will be removed" lub polskie odpowiedniki
            text.lines().any(|l| {
                (l.contains("packages will be removed") || l.contains("pakietow zostanie usunietych"))
                && !l.trim_start().starts_with('0')
            })
        }
        Err(_) => false,
    };

    if !has_orphans {
        println!("  {}", "Brak sierot do wyczyszczenia.".bright_black());
        println!();
        return;
    }

    println!("  {}", "Znaleziono niepotrzebne pakiety (sieroty).".yellow());
    println!();

    if !confirm("Wyczysc niepotrzebne pakiety? (autoremove)") {
        println!();
        println!("  {}", "Pominieto autoremove.".bright_black());
        println!();
        return;
    }

    println!();
    println!("  {}", "Czyszczenie sierot...".bright_black());
    println!();

    run_apt(&["autoremove"], "Czyszczenie", "yellow");
}

// ─────────────────────────────────────────────────────────────────────────────
// KOMENDY BEZ PASKA (search, show)
// ─────────────────────────────────────────────────────────────────────────────

fn run_simple(args: &[&str]) {
    let status = Command::new("apt")
    .args(args)
    .stdin(Stdio::inherit())
    .stdout(Stdio::inherit())
    .stderr(Stdio::inherit())
    .status();

    match status {
        Ok(s) if s.success() => {}
        Ok(s) => {
            println!();
            println!("  {} Komenda zakonczona z kodem: {:?}", "[!]".yellow(), s.code());
        }
        Err(e) => {
            println!("  {} Blad: {}", "[BLAD]".bright_red(), e);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

fn main() {
    let raw_args: Vec<String> = std::env::args().skip(1).collect();
    let args: Vec<&str> = raw_args.iter().map(|s| s.as_str()).collect();

    print_banner();

    match args.as_slice() {

        // ── install ──────────────────────────────────────────────────────────
        ["install", package] => {
            println!(
                "  {}  {}",
                "Akcja:".bright_black(),
                     format!("Instalacja  {}", package).green().bold()
            );
            println!();
            print_sep();
            println!();

            // Potwierdzenie
            if !confirm(&format!(
                "Czy na pewno chcesz zainstalowac pakiet {}?",
                package.green().bold()
            )) {
                println!();
                println!("  {}", "Anulowano.".bright_black());
                println!();
                return;
            }
            println!();

            // Sudo
            if !ensure_sudo() { return; }
            println!();

            run_apt(&["install", package], "Instalacja", "cyan");
        }

        // ── remove ───────────────────────────────────────────────────────────
        ["remove", package] => {
            println!(
                "  {}  {}",
                "Akcja:".bright_black(),
                     format!("Usuwanie    {}", package).red().bold()
            );
            println!();
            print_sep();
            println!();

            // Potwierdzenie — podwojne dla remove (bardziej destrukcyjne)
            println!(
                "  {} {}",
                "UWAGA:".bright_red().bold(),
                     format!("Pakiet {} zostanie usuniety z systemu.", package.red().bold())
            );
            println!();
            if !confirm(&format!(
                "Czy na pewno chcesz usunac pakiet {}?",
                package.red().bold()
            )) {
                println!();
                println!("  {}", "Anulowano.".bright_black());
                println!();
                return;
            }
            println!();

            // Sudo
            if !ensure_sudo() { return; }
            println!();

            let success = run_apt(&["remove", package], "Usuwanie", "red");

            // Po udanym remove — autoremove
            if success {
                print_sep();
                println!();
                println!("  {}", "Sprawdzanie sierot po usunieciu...".bright_black());
                println!();
                run_autoremove();
            }
        }

        // ── update ───────────────────────────────────────────────────────────
        ["update"] => {
            println!("  {}  {}", "Akcja:".bright_black(), "Aktualizacja list pakietow".yellow().bold());
            println!();
            print_sep();
            println!();

            if !ensure_sudo() { return; }
            println!();

            run_apt(&["update"], "Aktualizacja", "yellow");
        }

        // ── upgrade ──────────────────────────────────────────────────────────
        ["upgrade"] => {
            println!("  {}  {}", "Akcja:".bright_black(), "Aktualizacja systemu".yellow().bold());
            println!();
            print_sep();
            println!();

            if !confirm("Czy na pewno chcesz zaktualizowac system?") {
                println!();
                println!("  {}", "Anulowano.".bright_black());
                println!();
                return;
            }
            println!();

            if !ensure_sudo() { return; }
            println!();

            run_apt(&["upgrade"], "Uaktualnienie", "yellow");
        }

        // ── search ───────────────────────────────────────────────────────────
        ["search", query] => {
            println!("  {}  {}", "Akcja:".bright_black(), format!("Wyszukiwanie: {}", query).cyan().bold());
            println!();
            print_sep();
            println!();
            run_simple(&["search", query]);
        }

        // ── show ─────────────────────────────────────────────────────────────
        ["show", package] => {
            println!("  {}  {}", "Akcja:".bright_black(), format!("Info: {}", package).cyan().bold());
            println!();
            print_sep();
            println!();
            run_simple(&["show", package]);
        }

        // ── autoremove ───────────────────────────────────────────────────────
        ["autoremove"] => {
            println!("  {}  {}", "Akcja:".bright_black(), "Czyszczenie sierot".yellow().bold());
            println!();
            print_sep();
            println!();

            if !ensure_sudo() { return; }
            println!();

            run_autoremove();
        }

        // ── help / brak argumentow ───────────────────────────────────────────
        ["help"] | [] => {
            print_usage();
        }

        // ── nieznana komenda ─────────────────────────────────────────────────
        _ => {
            println!(
                "  {} Nieznana komenda: {}",
                "[!]".yellow().bold(),
                     args.join(" ").white()
            );
            print_usage();
            std::process::exit(1);
        }
    }
}
