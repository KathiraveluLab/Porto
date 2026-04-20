// Equitable Allocation Circuit - PORTO Use Case
// This circuit is part of the examples/equitable_allocation/ application,
// which demonstrates PORTO applied to EQUISYS goals.
//
// Privacy model:
//   - allocation and participant_hash are PRIVATE: never revealed on-chain
//   - total_pool and min_share are PUBLIC: agreed-upon policy parameters
//
// Proves: this participant received an allocation that satisfies both
// (a) the minimum guaranteed share, and (b) the pool capacity bound.
program equitable_allocation.aleo {

    transition verify_allocation(
        private allocation: u32,
        private participant_hash: u128,
        public total_pool: u32,
        public min_share: u32
    ) -> bool {
        assert(allocation >= min_share);
        assert(allocation <= total_pool);
        return true;
    }
}
