require "./helpers"

def play_text_game
  puts "#{Colors::BOLD}#{Colors::GREEN}Welcome to HackerOS Text Adventure!#{Colors::RESET}"
  puts "#{Colors::WHITE}You are an elite hacker in a high-security digital fortress. Your mission: breach the central mainframe and extract classified data.#{Colors::RESET}"
  puts "#{Colors::WHITE}Choose your game mode:#{Colors::RESET}"
  puts "  #{Colors::CYAN}1. Easy Mode #{Colors::RESET}- More hints, fewer obstacles."
  puts "  #{Colors::CYAN}2. Normal Mode #{Colors::RESET}- Balanced challenge."
  puts "  #{Colors::CYAN}3. Hard Mode #{Colors::RESET}- Limited hints, more traps and puzzles."
  puts "#{Colors::YELLOW}Enter mode number (1-3):#{Colors::RESET}"

  mode_input = gets.not_nil!.strip
  mode = case mode_input
         when "1" then :easy
         when "2" then :normal
         when "3" then :hard
         else
           puts "#{Colors::RED}Invalid mode. Defaulting to Normal.#{Colors::RESET}"
           :normal
         end

  # Game state
  locations = {
    "entrance" => {
      "description" => "You are at the main entrance of the digital fortress. Pathways lead north to the server room, east to the firewall chamber, west to the security office, and south to the data vault.",
      "north" => "server_room",
      "east" => "firewall_chamber",
      "west" => "security_office",
      "south" => "data_vault",
      "items" => [] of String,
      "puzzle" => nil
    },
    "server_room" => {
      "description" => "You are in the server room. Terminals hum with activity. There's a locked console here. North leads to the core chamber.",
      "south" => "entrance",
      "north" => "core_chamber",
      "items" => ["usb_drive"],
      "puzzle" => "The console requires a password. Hint: It's related to the company name."
    },
    "firewall_chamber" => {
      "description" => "You are in the firewall chamber. A massive digital wall blocks further access. East leads to a maintenance tunnel.",
      "west" => "entrance",
      "east" => "maintenance_tunnel",
      "items" => [] of String,
      "puzzle" => "The firewall needs to be bypassed with a keycard."
    },
    "security_office" => {
      "description" => "You are in the security office. Monitors show surveillance feeds. There's a keycard on the desk.",
      "east" => "entrance",
      "items" => ["keycard"],
      "puzzle" => nil
    },
    "data_vault" => {
      "description" => "You are in the data vault. Archives of information surround you. South leads to the backup generator.",
      "north" => "entrance",
      "south" => "backup_generator",
      "items" => ["password_note"],
      "puzzle" => nil
    },
    "core_chamber" => {
      "description" => "You are in the core chamber. The mainframe is here, heavily guarded. This is your target.",
      "south" => "server_room",
      "items" => [] of String,
      "puzzle" => "To hack the mainframe, you need the USB drive and the password."
    },
    "maintenance_tunnel" => {
      "description" => "You are in a narrow maintenance tunnel. It's dark and cramped. West back to firewall, east to a hidden lab.",
      "west" => "firewall_chamber",
      "east" => "hidden_lab",
      "items" => [] of String,
      "puzzle" => "A trap door requires a code. In hard mode, it's tricky."
    },
    "hidden_lab" => {
      "description" => "You are in a hidden lab. Experimental tech lies around. There's a decryption tool here.",
      "west" => "maintenance_tunnel",
      "items" => ["decryption_tool"],
      "puzzle" => nil
    },
    "backup_generator" => {
      "description" => "You are in the backup generator room. Power surges occasionally. North back to data vault.",
      "north" => "data_vault",
      "items" => [] of String,
      "puzzle" => "The generator can be sabotaged to cause a distraction."
    }
  }

  current_location = "entrance"
  inventory = [] of String
  hints_used = 0
  max_hints = case mode
              when :easy then 5
              when :normal then 3
              when :hard then 1
              else 3
              end
  trapped = false

  puts "#{Colors::YELLOW}Commands: north, south, east, west, take <item>, use <item>, inventory, hack, sabotage, help, hint, quit#{Colors::RESET}"

  loop do
    location_data = locations[current_location]
    puts "#{Colors::MAGENTA}#{location_data["description"]}#{Colors::RESET}"
    if location_data["puzzle"]
      puts "#{Colors::YELLOW}Puzzle: #{location_data["puzzle"]}#{Colors::RESET}" if mode == :easy || (mode == :normal && Random.rand < 0.5)
    end
    if !(location_data["items"].as(Array(String))).empty?
      puts "#{Colors::GREEN}Items here: #{(location_data["items"].as(Array(String))).join(", ")}#{Colors::RESET}"
    end

    input = gets.not_nil!.strip.downcase
    inputs = input.split(" ")
    command = inputs[0]?
    arg = inputs[1]? if inputs.size > 1

    case command
    when "north", "south", "east", "west"
      direction = command.not_nil!
      next_location = location_data[direction]?
      if next_location
        if current_location == "firewall_chamber" && direction == "east" && !inventory.includes?("keycard")
          puts "#{Colors::RED}The firewall blocks you. You need a keycard to bypass.#{Colors::RESET}"
        elsif current_location == "server_room" && direction == "north" && !inventory.includes?("password_note")
          puts "#{Colors::RED}The door to the core is locked. You need the password.#{Colors::RESET}"
        elsif current_location == "maintenance_tunnel" && mode == :hard && Random.rand < 0.3
          puts "#{Colors::RED}You triggered a trap! Game over.#{Colors::RESET}"
          exit(0)
        else
          current_location = next_location
        end
      else
        puts "#{Colors::RED}Can't go that way.#{Colors::RESET}"
      end
    when "take"
      if arg && (location_data["items"].as(Array(String))).includes?(arg)
        inventory << arg
        (location_data["items"].as(Array(String))).delete(arg)
        puts "#{Colors::GREEN}You took the #{arg}.#{Colors::RESET}"
      else
        puts "#{Colors::RED}No such item here.#{Colors::RESET}"
      end
    when "use"
      if arg && inventory.includes?(arg)
        case arg
        when "keycard"
          if current_location == "firewall_chamber"
            puts "#{Colors::GREEN}You used the keycard to bypass the firewall. Path east is open.#{Colors::RESET}"
          else
            puts "#{Colors::RED}No use for that here.#{Colors::RESET}"
          end
        when "decryption_tool"
          if current_location == "core_chamber"
            puts "#{Colors::GREEN}The decryption tool helps in hacking.#{Colors::RESET}"
          else
            puts "#{Colors::RED}No use for that here.#{Colors::RESET}"
          end
        else
          puts "#{Colors::RED}Can't use that.#{Colors::RESET}"
        end
      else
        puts "#{Colors::RED}You don't have that item.#{Colors::RESET}"
      end
    when "inventory"
      puts "#{Colors::GREEN}Inventory: #{inventory.join(", ") || "empty"}#{Colors::RESET}"
    when "hack"
      if current_location == "core_chamber" && inventory.includes?("usb_drive") && inventory.includes?("password_note") && inventory.includes?("decryption_tool")
        puts "#{Colors::GREEN}You successfully hacked the mainframe and extracted the data! You win!#{Colors::RESET}"
        exit(0)
      elsif current_location == "core_chamber"
        puts "#{Colors::RED}You need the USB drive, password, and decryption tool to hack here.#{Colors::RESET}"
      else
        puts "#{Colors::RED}Nothing to hack here.#{Colors::RESET}"
      end
    when "sabotage"
      if current_location == "backup_generator"
        puts "#{Colors::GREEN}You sabotaged the generator, causing a power fluctuation that disables some security.#{Colors::RESET}"
        # Could add effects, like opening paths or something
      else
        puts "#{Colors::RED}Nothing to sabotage here.#{Colors::RESET}"
      end
    when "help"
      puts "#{Colors::YELLOW}Available commands:#{Colors::RESET}"
      puts "  north, south, east, west - Move in that direction"
      puts "  take <item> - Pick up an item"
      puts "  use <item> - Use an item from inventory"
      puts "  inventory - Show your items"
      puts "  hack - Attempt to hack a terminal or mainframe"
      puts "  sabotage - Sabotage machinery (in specific locations)"
      puts "  hint - Get a hint (limited by mode)"
      puts "  quit - Exit the game"
    when "hint"
      if hints_used < max_hints
        hints_used += 1
        hint = case current_location
               when "entrance" then "Explore all directions to find useful items."
               when "server_room" then "The password might be in the data vault."
               when "firewall_chamber" then "Find a keycard in the security office."
               when "security_office" then "Take the keycard."
               when "data_vault" then "Grab the password note."
               when "core_chamber" then "You need three items to hack successfully."
               when "maintenance_tunnel" then "Watch out for traps in hard mode."
               when "hidden_lab" then "The decryption tool is crucial for the final hack."
               when "backup_generator" then "Sabotaging here can help distract security."
               else "No hint available here."
               end
        puts "#{Colors::BLUE}Hint: #{hint} (Hints used: #{hints_used}/#{max_hints})#{Colors::RESET}"
      else
        puts "#{Colors::RED}No more hints available in this mode.#{Colors::RESET}"
      end
    when "quit"
      puts "#{Colors::YELLOW}Goodbye, hacker!#{Colors::RESET}"
      exit(0)
    else
      puts "#{Colors::RED}Unknown command. Type 'help' for commands.#{Colors::RESET}"
    end
  end
end
