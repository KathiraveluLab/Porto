// PORTO base circuits — general-purpose ZK transition.
// Domain-specific circuits (e.g., equitable_allocation) are in examples/.
program porto_circuits.aleo {

    transition main(public a: u32) -> u32 {
        let c: u32 = a + 10u32;
        return c;
    }
}

