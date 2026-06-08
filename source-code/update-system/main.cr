require "option_parser"
require "process"
require "file_utils"
require "colorize"

require "./constants"
require "./ui"
require "./sudo"
require "./updates"
require "./results"
require "./menu"

# ── Entry point ──────────────────────────────────────────────────────────────
def main
  gui_mode = false
  OptionParser.parse do |parser|
    parser.banner = "Usage: hackeros-update-system [options]"
    parser.on("--gui-mode", "Run in interactive GUI mode inside terminal") { gui_mode = true }
  end

  unless gui_mode
    Process.new(
      "alacritty",
      args:   ["-e", BIN_PATH, "--gui-mode"],
      input:  Process::Redirect::Close,
      output: Process::Redirect::Close,
      error:  Process::Redirect::Close
    )
    return
  end

  variant = detect_variant
  pwd     = prompt_sudo_password
  results = perform_updates(pwd, variant)
  show_summary(results)
  show_gui_menu
end

main
