# ── Sudo state ────────────────────────────────────────────────────────────────
module SudoState
  @@password : String = ""

  def self.password=(pwd : String)
    @@password = pwd
  end

  def self.password : String
    @@password
  end
end

# ── Command runners ───────────────────────────────────────────────────────────
def run_command(cmd : String) : Bool
  Process.run(
    cmd,
    shell:  true,
    input:  Process::Redirect::Inherit,
    output: Process::Redirect::Inherit,
    error:  Process::Redirect::Inherit
  ).success?
end

def capture_command(cmd : String) : {Bool, String}
  buf    = IO::Memory.new
  status = Process.run(cmd, shell: true, input: Process::Redirect::Close, output: buf, error: buf)
  {status.success?, buf.to_s}
end

# Run sudo command with password piped via stdin — bypasses TTY cache issues.
def sudo_run(cmd : String) : Bool
  full = "echo #{Process.quote(SudoState.password)} | sudo -S sh -c #{Process.quote(cmd)} 2>/dev/null"
  Process.run(
    full,
    shell:  true,
    input:  Process::Redirect::Close,
    output: Process::Redirect::Inherit,
    error:  Process::Redirect::Inherit
  ).success?
end

# ── Sudo password prompt ──────────────────────────────────────────────────────
def prompt_sudo_password : String
  puts ""
  puts "  #{"┌".colorize(:dark_gray)} #{"Sudo authentication".colorize(:white).bold}"
  puts "  #{"│".colorize(:dark_gray)}  #{"Password is piped directly to each sudo call — no repeated prompts.".colorize(:dark_gray)}"
  print "  #{"└".colorize(:dark_gray)}  #{"password".colorize(:white)} › "

  password = ""
  STDIN.raw do |io|
    loop do
      byte = io.read_byte
      break if byte.nil?
      char = byte.chr
      break if char == '\r' || char == '\n'
      if char == '\u007F' || char == '\b'
        unless password.empty?
          password = password[0..-2]
          print "\b \b"
        end
        next
      end
      password += char.to_s
      print "*"
    end
  end
  puts ""

  validated = Process.run(
    "echo #{Process.quote(password)} | sudo -S true 2>/dev/null",
    shell:  true,
    input:  Process::Redirect::Close,
    output: Process::Redirect::Close,
    error:  Process::Redirect::Close
  ).success?

  unless validated
    puts ""
    puts "  #{"✗".colorize(:red).bold}  #{"Incorrect password — aborting.".colorize(:red)}"
    exit(1)
  end

  puts "  #{"✓".colorize(:green).bold}  #{"Authentication successful.".colorize(:light_gray)}"
  puts ""
  password
end
