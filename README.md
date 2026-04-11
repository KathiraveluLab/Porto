# PORTO
Private Off-chain Resource Tracking and Orchestration

PORTO is a radically new decentralized framework that implements an Actor-Model orchestration engine using Erlang/OTP natively integrated with the Aleo Zero-Knowledge (ZK) execution layer via the Leo CLI.

It fundamentally solves the throughput-privacy trilemma plaguing monolithic Layer-2 sequencers by completely isolating state logic across multi-node parallel environments. Mathematical confidentiality is generated strictly off-chain while verifiable cryptographic proofs are transmitted to the Aleo ecosystem.

## Build Requirements

1. **Erlang/OTP >= 25** (for the `core` orchestration framework)
2. **Rebar3** (Erlang build tool)
3. **Rust & Cargo** (Required to natively compile the Aleo dependencies)
4. **Leo CLI** (Aleo's zero-knowledge circuit compiler)

## Quick Start (Local Dry-run Execution)

### 1. Installing Aleo & Leo
```bash
# Clone the Leo repository to install the Leo CLI locally
git clone https://github.com/AleoHQ/leo
cd leo
cargo install --path .
```
Verify the installation by running `leo --version`.

### 2. Running PORTO Core
Once the zero-knowledge environment is accessible, you can compile and boot the Erlang distributed orchestration engine natively:

```bash
cd core
rebar3 compile
erl -pa _build/default/lib/core/ebin
```

Inside the Erlang shell, you can dynamically spin up your off-chain tracking actors using the provided API. This will seamlessly spawn concurrent OS processes mapping to your Aleo execution circuits:
```erlang
% Spawns a new actor to track "ResourceA" and validate bounds via zero-knowledge
porto_core_app:track_resource("ResourceA").
```
