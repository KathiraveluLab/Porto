# Sustainability Quota Compliance - PORTO Use Case

## Overview
This use case demonstrates PORTO's applicability to sustainable digital resource 
usage. It allows organisations to prove that their consumption of resources 
(e.g., carbon credits, energy, compute hours) did not exceed an assigned quota
without disclosing the exact consumption data.

## Key Logic
An organisation's resource usage is compared against a public quota ceiling.
The proof confirms that usage <= quota - without revealing the actual usage figure.

## Running the Example
1. Start the PORTO core.
2. Launch a quota actor for an organisation:

```erlang
% Spawns a supervised actor for a specific organisation
porto_quota_actor:start_link(OrgID, CurrentUsage, QuotaLimit).
```

Proof generation and verification are handled by the `porto_leo_bridge`.
Only the compliance status is persisted.

## Why this matters

Revealing precise consumption figures is commercially sensitive and may expose
competitive or operational intelligence. \projectname enables compliance proofs
that satisfy regulators without sacrificing data sovereignty.

## Structure

```
sustainability_quota/
├── circuits/              # Leo/Aleo ZK circuit
│   ├── program.json
│   └── src/main.leo       # verify_quota transition
└── core/                  # Erlang orchestration layer (extends PORTO)
    └── src/
        ├── porto_quota_actor.erl   # gen_server actor per participant
        └── porto_quota_sup.erl     # simple_one_for_one supervisor
```

## How it extends PORTO

Reuses `porto_leo_bridge:verify_quota/3` (shared bridge API) and `porto_cluster`
process group. The quota actors plug into PORTO without modifying core.

## Running the circuit

```bash
cd circuits
leo run verify_quota 45u32 1234567890123456789012345678901234567890u128 100u32
# ^ proves: usage=45 <= quota=100
```

A constraint violation (usage > quota) causes Leo to abort with a non-zero exit.
