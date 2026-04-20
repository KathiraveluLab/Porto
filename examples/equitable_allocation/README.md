# Equitable Allocation - PORTO Use Case

## Overview
This example demonstrates how PORTO's off-chain actors can be used to prove
the "equitability" of a resource distribution without revealing the identities
of the participants or the raw totals on-chain.

Participants generate a zero-knowledge proof that their local allocation is
greater than or equal to a defined **Minimum Fair Share** (computed from the 
Total Pool / Number of Participants).

The PORTO `porto_leo_bridge` handles the transition from Erlang actor state to
the Leo ZK circuit, providing a cryptographic guarantee of the "right to a 
share guarantee" - without revealing their identity or exact allocation on-chain.

## Running the Example
1. Ensure `rebar3` is in your path.
2. Ensure `leo` CLI is installed and accessible.
3. Start the PORTO cluster and the allocation actor.

```erlang
% Spawns a supervised equitable allocation actor
porto_allocation_actor:start_link(ParticipantID, Allocation, TotalPool, MinShare).
```

If the Zero-Knowledge verification fails, the Erlang process will terminate
with a non-zero exit - consistent with PORTO's hard-error, let-it-crash policy.

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
with a non-zero exit - consistent with PORTO's hard-error, let-it-crash policy.

## HTTP API (when the example's Cowboy endpoint is active)

```bash
curl -X POST http://localhost:8080/allocate \
  -H "Content-Type: application/json" \
  -d '{"participant_id": "inst-42", "allocation": 50, "total_pool": 100, "min_share": 10}'
```
