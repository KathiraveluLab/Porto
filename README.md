# PORTO

**Private Off-chain Resource Tracking and Orchestration.**

## Getting Started

PORTO bridges a highly concurrent Erlang BEAM runtime with the Aleo Zero-Knowledge toolchain. To run this project locally, you must first install Rust and the Leo language compiler.

### 1. Install prerequisites (Rust & Cargo)
Leo is built from Rust source. Install the Rust toolchain:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### 2. Install Leo Compiler
Once Cargo is configured in your path, install the `leo` binary:
```bash
cargo install leo-lang
```
Verify the installation by running `leo --version`.

### 3. Running PORTO Core
Once the zero-knowledge environment is accessible, you can compile and boot the Erlang distributed orchestration engine natively:

```bash
cd porto_core
rebar3 compile
rebar3 shell
```

Inside the Erlang shell, you can dynamically spin up your off-chain tracking actors using the provided API. This will seamlessly spawn concurrent OS processes mapping to your Aleo execution circuits:
```erlang
% Spawns a new actor to track "ResourceA" and validate bounds via zero-knowledge
porto_core_app:track_resource("ResourceA").
```
