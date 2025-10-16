use colored::*;
use std::io::{self};
use rand::Rng;

pub fn play_game() {
    loop {
        println!("{}", "========== Welcome to Hacker Adventure! ==========".purple().bold());
        println!("{}", "You are a fun-loving hacker trying to 'hack' into silly systems for laughs.".cyan().bold());
        println!("{}", "Choose your adventure level:".cyan().bold());
        println!("{}", "1. Easy (Coffee Machine Hack - Guess the PIN)".white());
        println!("{}", "2. Medium (Cat Meme Database - Decode the Puzzle)".white());
        println!("{}", "3. Hard (Alien UFO Control - Multi-Step Challenge)".white());

        let mut input = String::new();
        io::stdin().read_line(&mut input).expect("Failed to read line");
        let choice: u32 = match input.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("{}", "Invalid choice! Defaulting to Medium.".red().bold());
                2
            }
        };

        let mut score = 0;
        let mut won = false;

        match choice {
            1 => {
                println!("{}", "Level 1: Hacking the Office Coffee Machine!".green().bold());
                println!("{}", "Guess the 4-digit PIN (0000-9999). You have 10 attempts.".cyan());
                let pin = rand::thread_rng().gen_range(0..10000);
                let mut attempts = 0;
                while attempts < 10 {
                    attempts += 1;
                    println!("{}", format!("Attempt {}/10: Enter PIN:", attempts).yellow().bold());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    let guess: u32 = match guess.trim().parse() {
                        Ok(num) => num,
                        Err(_) => continue,
                    };
                    if guess == pin {
                        println!("{}", "Success! Coffee for everyone! +100 points.".green().bold());
                        score += 100;
                        won = true;
                        break;
                    } else if guess < pin {
                        println!("{}", "Too low! The machine buzzes angrily.".yellow());
                    } else {
                        println!("{}", "Too high! The machine steams up.".yellow());
                    }
                }
                if !won {
                    println!("{}", format!("Failed! The PIN was {}. No coffee today.", pin).red().bold());
                }
            }
            2 => {
                println!("{}", "Level 2: Infiltrating the Cat Meme Database!".green().bold());
                println!("{}", "Solve the riddle to decode the access key.".cyan());
                let riddles = vec![
                    ("What has keys but can't open locks?", "keyboard"),
                    ("I'm light as a feather, but the strongest hacker can't hold me for much more than a minute. What am I?", "breath"),
                    ("What do you call a hacker who skips school?", "truant"),
                ];
                for (riddle, answer) in riddles {
                    println!("{}", riddle.magenta().bold());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    if guess.trim().to_lowercase() == answer {
                        println!("{}", "Correct! +50 points.".green());
                        score += 50;
                    } else {
                        println!("{}", format!("Wrong! It was '{}'.", answer).red());
                    }
                }
                if score >= 100 {
                    won = true;
                    println!("{}", "Database hacked! Endless cat memes unlocked!".green().bold());
                } else {
                    println!("{}", "Access denied! Try harder next time.".red().bold());
                }
            }
            3 => {
                println!("{}", "Level 3: Taking over an Alien UFO!".green().bold());
                println!("{}", "Complete all challenges to win.".cyan());
                // Challenge 1: Guess number
                let num = rand::thread_rng().gen_range(1..101);
                let mut attempts = 0;
                let mut success = false;
                while attempts < 5 {
                    attempts += 1;
                    println!("{}", "Challenge 1: Guess the alien code (1-100):".yellow().bold());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    let guess: i32 = match guess.trim().parse() {
                        Ok(num) => num,
                        Err(_) => continue,
                    };
                    if guess == num {
                        println!("{}", "Code cracked! +100 points.".green());
                        score += 100;
                        success = true;
                        break;
                    } else if guess < num {
                        println!("{}", "Too low! Aliens chuckle.".yellow());
                    } else {
                        println!("{}", "Too high! UFO wobbles.".yellow());
                    }
                }
                if !success {
                    println!("{}", "Challenge failed! UFO escapes.".red().bold());
                    break;
                }
                // Challenge 2: Choose path
                println!("{}", "Challenge 2: Choose your hack path:".yellow().bold());
                println!("{}", "1. Brute force (risky)".white());
                println!("{}", "2. Stealth mode (safe)".white());
                let mut choice = String::new();
                io::stdin().read_line(&mut choice).expect("Failed to read line");
                if choice.trim() == "2" {
                    println!("{}", "Stealth success! +100 points.".green());
                    score += 100;
                } else {
                    if rand::thread_rng().gen_bool(0.5) {
                        println!("{}", "Brute force worked! +150 points.".green());
                        score += 150;
                    } else {
                        println!("{}", "Brute force failed! -50 points.".red());
                        score -= 50;
                    }
                }
                // Challenge 3: Final puzzle
                println!("{}", "Final Challenge: What do hackers do at the beach?".magenta().bold());
                println!("{}", "Hint: It involves waves.".cyan());
                let mut guess = String::new();
                io::stdin().read_line(&mut guess).expect("Failed to read line");
                if guess.trim().to_lowercase().contains("surf") {
                    println!("{}", "Correct! They surf the web. +200 points.".green());
                    score += 200;
                    won = true;
                } else {
                    println!("{}", "Wrong! UFO self-destructs.".red());
                }
            }
            _ => continue,
        }

        println!("{}", format!("Your score: {}", score).blue().bold());
        if won {
            println!("{}", "You win the level!".green().bold());
        }

        println!("{}", "Play again? (y/n)".cyan().bold());
        let mut again = String::new();
        io::stdin().read_line(&mut again).expect("Failed to read line");
        if again.trim().to_lowercase() != "y" {
            break;
        }
    }
    println!("{}", "========== Thanks for playing Hacker Adventure! ==========".purple().bold());
}
