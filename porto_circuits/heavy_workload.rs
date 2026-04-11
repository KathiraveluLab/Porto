use std::hash::{Hash, Hasher};
use std::collections::hash_map::DefaultHasher;

fn generate_computational_proof() {
    let mut hash_val: u64 = 0;
    // Pure mathematical load without external crates mimicking ZK proof EC computation
    for i in 0..15_000_000u64 {
        let mut s = DefaultHasher::new();
        i.hash(&mut s);
        hash_val ^= s.finish();
    }
    // Prevent the compiler from optimizing the loop entirely
    if hash_val == 42 {
        std::process::exit(1);
    }
}

fn main() {
    generate_computational_proof();
    std::process::exit(0);
}
