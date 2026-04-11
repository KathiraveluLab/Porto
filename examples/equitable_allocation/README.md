# Equitable Allocation — PORTO Use Case

This directory contains a self-contained application demonstrating PORTO applied to
verifiable equitable digital resource distribution, motivated by human-centered
system design goals for equitable and sustainable digital societies (EQUISYS).

## Scenario

A coordinating authority distributes units from a shared digital resource pool
(e.g., broadband capacity, compute quotas, public cloud credits) across participants.
Each participant needs to prove their allocation meets the publicly agreed minimum
share guarantee — without revealing their identity or exact allocation on-chain.

## Structure

```
equitable_allocation/
├── circuits/              # Leo/Aleo ZK circuit
│   ├── program.json
│   └── src/main.leo       # verify_allocation transition
└── core/                  # Erlang orchestration layer (extends PORTO)
    └── src/
        ├── porto_allocation_actor.erl   # gen_server actor per participant
        └── porto_allocation_sup.erl     # simple_one_for_one supervisor
```

## How it extends PORTO

The example reuses PORTO's `porto_leo_bridge` for OS Port execution,
`porto_core_sup` for the root supervision tree, and Mnesia for persistence.
The `porto_allocation_sup` and `porto_allocation_actor` modules plug into
the PORTO framework without modifying core.

## Running the circuit

```bash
cd circuits
leo run verify_allocation 50u32 1234567890123456789012345678901234567890u128 100u32 10u32
# ^ proves: allocation=50 >= min_share=10, and <= total_pool=100
```

A constraint violation (e.g. allocation below min_share) causes Leo to abort
with a non-zero exit — consistent with PORTO's hard-error, let-it-crash policy.

## HTTP API (when the example's Cowboy endpoint is active)

```bash
curl -X POST http://localhost:8080/allocate \
  -H "Content-Type: application/json" \
  -d '{"participant_id": "inst-42", "allocation": 50, "total_pool": 100, "min_share": 10}'
```
