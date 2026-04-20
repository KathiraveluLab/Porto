# Service Eligibility - PORTO Use Case

## Overview
This example demonstrates a privacy-preserving application for assessing eligibility
for public digital services (e.g., broadband subsidies, digital inclusion programs).

Citizens can prove that they meet a specific eligibility threshold (derived from
income, geography, or other vulnerability indexes) without revealing their raw
score on-chain.

## Key Logic
A participant's eligibility score - derived from factors like income decile or 
geographic remoteness - must meet a publicly announced threshold to qualify.
The score is kept private; only the eligibility status is published.

## Running the Example
1. Start the PORTO core.
2. Spawn an eligibility actor:

```erlang
% Spawns a supervised actor for a specific applicant
porto_eligibility_actor:start_link(ApplicantID, Score, Threshold).
```

Verification is performed via the `porto_leo_bridge`. Results are stored with the
threshold applied - never the applicant's score.

## Structure

```
service_eligibility/
├── circuits/              # Leo/Aleo ZK circuit
│   ├── program.json
│   └── src/main.leo       # verify_eligibility transition
└── core/                  # Erlang orchestration layer (extends PORTO)
    └── src/
        ├── porto_eligibility_actor.erl
        └── porto_eligibility_sup.erl
```

## How it extends PORTO

Reuses `porto_leo_bridge:verify_eligibility/3` (shared bridge API) and the
`porto_cluster` process group. The eligibility actors plug into PORTO without
modifying core. The Mnesia audit record stores only the eligibility fact and
threshold applied - never the applicant's score.

## Running the circuit

```bash
cd circuits
leo run verify_eligibility 30u32 1234567890123456789012345678901234567890u128 50u32
# ^ proves: score=30 <= threshold=50 (applicant qualifies)
```

A score above the threshold causes Leo to abort with a non-zero exit.
