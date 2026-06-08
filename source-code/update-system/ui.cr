# ── UI helpers ───────────────────────────────────────────────────────────────
def banner(title : String)
  total_width = 52
  label       = " [ #{title} ] "
  side        = [2, (total_width - label.size) // 2].max
  left_line   = "─" * side
  right_line  = "─" * [0, total_width - side - label.size].max
  puts ""
  puts (left_line + label.colorize(:white).bold.to_s + right_line).colorize(:dark_gray)
end

def step(msg : String)
  puts "  #{"›".colorize(:dark_gray)}  #{msg.colorize(:white)}"
end

def ok(msg : String)
  puts "  #{"✓".colorize(:green).bold}  #{msg.colorize(:light_gray)}"
end

def fail_msg(msg : String)
  puts "  #{"✗".colorize(:red).bold}  #{msg.colorize(:light_gray)}"
end

def warn_msg(msg : String)
  puts "  #{"⚠".colorize(:yellow).bold}  #{msg.colorize(:light_gray)}"
end

def format_duration(seconds : Int64) : String
  if seconds >= 60
    m = seconds // 60
    s = seconds % 60
    "#{m}m #{s}s"
  else
    "#{seconds}s"
  end
end
