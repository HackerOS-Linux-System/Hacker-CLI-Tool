use colored::*;
use std::io::{self};
use rand::Rng;

pub fn play_game() {
    loop {
        println!("{}", "========== Welcome to Hacker Adventure! ==========".purple().bold().on_black());
        println!("{}", "You are a fun-loving hacker trying to 'hack' into silly systems for laughs.".cyan().bold().on_black());
        println!("{}", "Choose your adventure level:".cyan().bold().on_black());
        println!("{}", "1. Easy (Coffee Machine Hack - Guess the PIN)".white().bold());
        println!("{}", "2. Medium (Cat Meme Database - Decode the Puzzle)".white().bold());
        println!("{}", "3. Hard (Alien UFO Control - Multi-Step Challenge)".white().bold());
        println!("{}", "4. Expert (Quantum Computer Hack - Advanced Riddles and Guesses)".white().bold());

        let mut input = String::new();
        io::stdin().read_line(&mut input).expect("Failed to read line");
        let choice: u32 = match input.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("{}", "Invalid choice! Defaulting to Medium.".red().bold().on_black());
                2
            }
        };

        let mut score = 0;
        let mut won = false;

        match choice {
            1 => {
                println!("{}", "Level 1: Hacking the Office Coffee Machine!".green().bold().on_black());
                println!("{}", "Guess the 4-digit PIN (0000-9999). You have 10 attempts.".cyan().on_black());
                let pin = rand::thread_rng().gen_range(0..10000);
                let mut attempts = 0;
                while attempts < 10 {
                    attempts += 1;
                    println!("{}", format!("Attempt {}/10: Enter PIN:", attempts).yellow().bold().on_black());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    let guess: u32 = match guess.trim().parse() {
                        Ok(num) => num,
                        Err(_) => continue,
                    };
                    if guess == pin {
                        println!("{}", "Success! Coffee for everyone! +100 points.".green().bold().on_black());
                        score += 100;
                        won = true;
                        break;
                    } else if guess < pin {
                        println!("{}", "Too low! The machine buzzes angrily.".yellow().on_black());
                    } else {
                        println!("{}", "Too high! The machine steams up.".yellow().on_black());
                    }
                }
                if !won {
                    println!("{}", format!("Failed! The PIN was {}. No coffee today.", pin).red().bold().on_black());
                }
            }
            2 => {
                println!("{}", "Level 2: Infiltrating the Cat Meme Database!".green().bold().on_black());
                println!("{}", "Solve the riddle to decode the access key.".cyan().on_black());
                let riddles = vec![
                    ("What has keys but can't open locks?", "keyboard"),
                    ("I'm light as a feather, but the strongest hacker can't hold me for much more than a minute. What am I?", "breath"),
                    ("What do you call a hacker who skips school?", "truant"),
                    ("What gets wetter as it dries?", "towel"),
                    ("I speak without a mouth and hear without ears. I have no body, but I come alive with the wind. What am I?", "echo"),
                ];
                for (riddle, answer) in riddles {
                    println!("{}", riddle.magenta().bold().on_black());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    if guess.trim().to_lowercase() == answer {
                        println!("{}", "Correct! +50 points.".green().on_black());
                        score += 50;
                    } else {
                        println!("{}", format!("Wrong! It was '{}'.", answer).red().on_black());
                    }
                }
                if score >= 150 {
                    won = true;
                    println!("{}", "Database hacked! Endless cat memes unlocked!".green().bold().on_black());
                } else {
                    println!("{}", "Access denied! Try harder next time.".red().bold().on_black());
                }
            }
            3 => {
                println!("{}", "Level 3: Taking over an Alien UFO!".green().bold().on_black());
                println!("{}", "Complete all challenges to win.".cyan().on_black());
                // Challenge 1: Guess number
                let num = rand::thread_rng().gen_range(1..101);
                let mut attempts = 0;
                let mut success = false;
                while attempts < 5 {
                    attempts += 1;
                    println!("{}", "Challenge 1: Guess the alien code (1-100):".yellow().bold().on_black());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    let guess: i32 = match guess.trim().parse() {
                        Ok(num) => num,
                        Err(_) => continue,
                    };
                    if guess == num {
                        println!("{}", "Code cracked! +100 points.".green().on_black());
                        score += 100;
                        success = true;
                        break;
                    } else if guess < num {
                        println!("{}", "Too low! Aliens chuckle.".yellow().on_black());
                    } else {
                        println!("{}", "Too high! UFO wobbles.".yellow().on_black());
                    }
                }
                if !success {
                    println!("{}", "Challenge failed! UFO escapes.".red().bold().on_black());
                    break;
                }
                // Challenge 2: Choose path
                println!("{}", "Challenge 2: Choose your hack path:".yellow().bold().on_black());
                println!("{}", "1. Brute force (risky)".white().bold());
                println!("{}", "2. Stealth mode (safe)".white().bold());
                let mut choice = String::new();
                io::stdin().read_line(&mut choice).expect("Failed to read line");
                if choice.trim() == "2" {
                    println!("{}", "Stealth success! +100 points.".green().on_black());
                    score += 100;
                } else {
                    if rand::thread_rng().gen_bool(0.5) {
                        println!("{}", "Brute force worked! +150 points.".green().on_black());
                        score += 150;
                    } else {
                        println!("{}", "Brute force failed! -50 points.".red().on_black());
                        score -= 50;
                    }
                }
                // Challenge 3: Final puzzle
                println!("{}", "Final Challenge: What do hackers do at the beach?".magenta().bold().on_black());
                println!("{}", "Hint: It involves waves.".cyan().on_black());
                let mut guess = String::new();
                io::stdin().read_line(&mut guess).expect("Failed to read line");
                if guess.trim().to_lowercase().contains("surf") {
                    println!("{}", "Correct! They surf the web. +200 points.".green().on_black());
                    score += 200;
                    won = true;
                } else {
                    println!("{}", "Wrong! UFO self-destructs.".red().on_black());
                }
            }
            4 => {
                println!("{}", "Level 4: Hacking a Quantum Computer!".green().bold().on_black());
                println!("{}", "Solve advanced riddles and guess the quantum state.".cyan().on_black());
                let riddles = vec![
                    ("I am not alive, but I grow; I don't have lungs, but I need air; I don't have a mouth, but water kills me. What am I?", "fire"),
                    ("What can travel around the world while staying in a corner?", "stamp"),
                    ("What has a head, a tail, is brown, and has no legs?", "penny"),
                ];
                for (riddle, answer) in riddles {
                    println!("{}", riddle.magenta().bold().on_black());
                    let mut guess = String::new();
                    io::stdin().read_line(&mut guess).expect("Failed to read line");
                    if guess.trim().to_lowercase() == answer {
                        println!("{}", "Correct! +100 points.".green().on_black());
                        score += 100;
                    } else {
                        println!("{}", format!("Wrong! It was '{}'.", answer).red().on_black());
                    }
                }
                // Quantum guess: Even or odd
                let quantum = rand::thread_rng().gen_range(1..1001);
                println!("{}", "Final Quantum Challenge: Guess if the state is even or odd (number 1-1000).".yellow().bold().on_black());
                let mut guess = String::new();
                io::stdin().read_line(&mut guess).expect("Failed to read line");
                let is_even = quantum % 2 == 0;
                let guessed_even = guess.trim().to_lowercase() == "even";
                if (is_even && guessed_even) || (!is_even && !guessed_even) {
                    println!("{}", "Quantum state hacked! +300 points.".green().on_black());
                    score += 300;
                    won = true;
                } else {
                    println!("{}", format!("Wrong! It was {}. Quantum collapse!", if is_even { "even" } else { "odd" }).red().on_black());
                }
            }
            _ => continue,
        }

        println!("{}", format!("Your score: {}", score).blue().bold().on_black());
        if won {
            println!("{}", "You win the level!".green().bold().on_black());
        }

        println!("{}", "Play again? (y/n)".cyan().bold().on_black());
        let mut again = String::new();
        io::stdin().read_line(&mut again).expect("Failed to read line");
        if again.trim().to_lowercase() != "y" {
            break;
        }
    }
    println!("{}", "========== Thanks for playing Hacker Adventure! ==========".purple().bold().on_black());
}
