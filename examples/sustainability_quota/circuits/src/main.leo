// Sustainability Quota Compliance Circuit - PORTO Use Case
// This circuit is part of the examples/sustainability_quota/ application,
// which demonstrates PORTO applied to verifiable sustainable resource usage.
//
// Scenario: an organisation proves its actual resource consumption
// (energy, bandwidth, carbon credits, compute hours) did not exceed
// its allocated quota - without revealing the actual usage figure.
//
// Privacy model:
//   - usage and participant_hash are PRIVATE: never revealed on-chain
//   - quota is PUBLIC: the agreed ceiling known to all parties
//
// The circuit proves: usage <= quota.
// It reveals nothing about the actual consumption level.
program sustainability_quota.aleo {

    transition verify_quota(
        private usage: u32,
        private participant_hash: u128,
        public quota: u32
    ) -> bool {
        assert(usage <= quota);
        return true;
    }
}
