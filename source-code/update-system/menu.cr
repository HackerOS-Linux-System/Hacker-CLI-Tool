# ── Clean section ─────────────────────────────────────────────────────────────
def do_clean
  banner("System Clean")

  step "APT autoremove"
  sudo_run("apt autoremove -y")

  step "APT clean"
  sudo_run("apt clean")

  step "Flatpak remove unused runtimes"
  run_command("flatpak uninstall --unused -y")

  if Process.run("command -v snap", shell: true).success?
    step "Snap remove disabled snaps"
    run_command(%(snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read name rev; do echo #{Process.quote(SudoState.password)} | sudo -S snap remove "$name" --revision="$rev" 2>/dev/null; done))
  end

  if Process.run("command -v brew", shell: true).success?
    step "Brew cleanup"
    run_command("brew cleanup --prune=all")
  end

  puts ""
  ok "Clean complete"
end

# ── Interactive menu ─────────────────────────────────────────────────────────
MENU_ITEMS = [
  {"Q", "Quit",     "Close this terminal"},
  {"R", "Reboot",   "Reboot the system"},
  {"S", "Shutdown", "Shutdown the system"},
  {"L", "Log out",  "Log out from current session"},
  {"T", "Terminal", "Open a new Alacritty terminal"},
  {"C", "Clean",    "Remove unused packages & cache"},
]

def show_gui_menu
  loop do
    key_col_w = 17
    desc_w    = 32
    box_w     = 2 + key_col_w + 2 + desc_w

    puts "┌#{"─" * box_w}┐".colorize(:dark_gray)
    title     = "HackerOS Update System  ·  What's next?"
    title_pad = box_w - title.size - 2
    puts "│  #{title.colorize(:yellow).bold}#{" " * [title_pad, 0].max}│".colorize(:dark_gray)
    puts "├#{"─" * box_w}┤".colorize(:dark_gray)

    MENU_ITEMS.each do |(key, label, desc)|
      key_col  = ("[#{key}]  #{label}").ljust(key_col_w)
      desc_col = desc.ljust(desc_w)
      puts "│  #{key_col.colorize(:white)}  #{desc_col.colorize(:dark_gray)}│".colorize(:dark_gray)
    end

    puts "└#{"─" * box_w}┘".colorize(:dark_gray)
    print "\n  #{"›".colorize(:dark_gray)}  #{"Choice".colorize(:white)}: "

    choice = ""
    STDIN.raw do |io|
      byte = io.read_byte
      if byte
        choice = byte.chr.to_s.upcase
        puts choice.colorize(:cyan).bold
      end
    end

    puts ""

    case choice
    when "Q" then exit(0)
    when "R" then sudo_run("reboot")
    when "S" then sudo_run("shutdown -h now")
    when "L" then run_command("qdbus org.kde.ksmserver /KSMServer logout 0 0 0")
    when "T"
      Process.new("alacritty",
        input:  Process::Redirect::Close,
        output: Process::Redirect::Close,
        error:  Process::Redirect::Close)
    when "C" then do_clean
    else
      warn_msg "Unknown option '#{choice}' — try again"
    end

    puts ""
  end
end
