module Colors
  RED = "\e[31m"
  GREEN = "\e[32m"
  YELLOW = "\e[33m"
  BLUE = "\e[34m"
  MAGENTA = "\e[35m"
  CYAN = "\e[36m"
  WHITE = "\e[37m"
  GRAY = "\e[90m"
  BOLD = "\e[1m"
  RESET = "\e[0m"
end
def safe_run(cmd : String)
  status = Process.run(cmd, shell: true, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  if !status.success?
    puts "#{Colors::RED}Command '#{cmd}' failed with exit code #{status.exit_code}#{Colors::RESET}"
  end
  status.success?
end
def install_gamescope
  # Assuming gamescope is installed via flatpak; adjust if needed
  safe_run("flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope") # Example; replace with actual if different
end
