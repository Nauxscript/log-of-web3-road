use rand::Rng;
use std::{io, cmp::Ordering};

fn main() {
    println!("Hello, world!");
    let secret_number = rand::thread_rng().gen_range(1..10);
    let mut attempts = 0;
    loop {
        let mut guess = String::new();
        io::stdin().read_line(&mut guess).expect("Failed to read line");
        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => {
                println!("Please input valid number");
                continue;
            }
        };
        attempts += 1;
        if guess < 1 || guess > 10 {
            println!("Please input a number between 1 and 10"); 
            continue;
        }

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("too small!"),
            Ordering::Greater => println!("too big!"),
            Ordering::Equal => {
                println!("Congratulation you're right!");
                println!("tips: you have tried {} times", attempts);
                break;
            }
        }
    }
}
