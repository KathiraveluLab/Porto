// Service Eligibility Circuit - PORTO Use Case
// This circuit is part of the examples/service_eligibility/ application,
// which demonstrates PORTO applied to privacy-preserving access to public
// digital services (e.g., subsidised broadband, digital inclusion programs,
// public compute access for underserved communities).
//
// Scenario: A citizen or household proves they are eligible for a public
// digital service by demonstrating their eligibility score (e.g., derived
// from income decile, geographic remoteness index, or vulnerability index)
// meets a publicly known threshold - without revealing the score itself.
//
// Privacy model:
//   - score and applicant_hash are PRIVATE: never revealed on-chain
//   - threshold is PUBLIC: the eligibility policy set by the service provider
//
// The circuit proves: score <= threshold (i.e., the applicant qualifies).
// It reveals nothing about the applicant's actual score or identity.
program service_eligibility.aleo {

    transition verify_eligibility(
        private score: u32,
        private applicant_hash: u128,
        public threshold: u32
    ) -> bool {
        assert(score <= threshold);
        return true;
    }
}
