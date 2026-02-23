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

CUSTOM_DIR = Path.home / ".config" / "hackeros" / "hacker" / "custom-commands"
PLUGIN_DIR = Path.home / ".config" / "hackeros" / "hacker" / "plugins"

class Config
  @data : Hash(String, String | Config)
  def initialize
    @data = Hash(String, String | Config).new
  end
  def [](key : String) : String | Config
    @data[key]
  end
  def []?(key : String) : String | Config | Nil
    @data[key]?
  end
  def []=(key : String, value : String | Config)
    @data[key] = value
  end
  def each(&block)
    @data.each { |k, v| yield k, v }
  end
end

def parse_hacker_file(path : String) : Config
  content = File.read(path).strip
  raise "Invalid .hacker file format: must start with '[' and end with ']'." unless content.starts_with?('[') && content.ends_with?(']')
  content = content[1...-1].strip
  lines = content.lines.map(&.strip).reject(&.empty?)
  root = Config.new
  stack = [root] of Config
  lines.each do |line|
    level = 0
    temp = line
    while temp.starts_with?(">")
      level += 1
      temp = temp[1..].lstrip
    end
    parts = temp.split(">", limit: 2)
    key = parts[0].strip
    value = parts.size > 1 ? parts[1].strip : ""
    while stack.size > level + 1
      stack.pop
    end
    raise "Nesting error in .hacker file at: #{line}" if stack.size != level + 1
    if value.empty?
      new_config = Config.new
      stack.last[key] = new_config
      stack.push new_config
    else
      stack.last[key] = value
    end
  end
  root
end

def write_hacker_file(path : String, config : Config)
  File.write(path, "[\n#{write_config(config, 0)}\n]")
end

def write_config(config : Config, level : Int32) : String
  lines = [] of String
  config.each do |key, value|
    indent = ("> " * level)
    if value.is_a?(String)
      lines << "#{indent}#{key}> #{value}"
    elsif value.is_a?(Config)
      lines << "#{indent}#{key}>"
      lines << write_config(value, level + 1)
    end
  end
  lines.join("\n")
end
