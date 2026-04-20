-module(porto_benchmark).
-export([run_sync/1, run_porto_async/1]).

%% Benchmark Methodology Note:
%% ===========================
%% These benchmarks measure PORTO's orchestration layer overhead -
%% specifically the latency and throughput difference between:
%%   (a) a monolithic synchronous sequencer (Sync baseline), and
%%   (b) PORTO's parallel actor-per-proof dispatch (Async).
%%
%% The workload kernel is a native Rust CPU-bound computation
%% (circuits/heavy_workload.rs) that approximates the computational
%% cost of ZK constraint solving without Leo compiler startup overhead.
%% This isolation is intentional: it measures the orchestration
%% architecture, not Leo toolchain latency, which varies by hardware.
%%
%% To benchmark with the live Leo compiler instead, replace the
%% command below with the leo_run_command/1 variant.

-define(BENCHMARK_KERNEL, "./heavy_workload").
-define(BENCHMARK_DIR,    "../circuits").

%% Baseline: Monolithic Synchronous Sequencer
%% Executes N proof evaluations sequentially, one at a time.
run_sync(N) ->
    {TimeUs, _} = timer:tc(fun() ->
        loop_sync(N)
    end),
    TimeMs = TimeUs / 1000.0,
    Throughput = case TimeMs of 0.0 -> 0; _ -> N / (TimeMs / 1000.0) end,
    io:format("=== SYNC BASELINE (N=~p) ===~nTotal Time: ~p ms~nThroughput: ~p TPS~n",
              [N, TimeMs, Throughput]),
    {TimeMs, Throughput}.

loop_sync(0) -> ok;
loop_sync(N) ->
    run_kernel(),
    loop_sync(N - 1).

%% PORTO Architecture: Parallel Actor Dispatch
%% Executes N proof evaluations concurrently via isolated OS processes.
run_porto_async(N) ->
    {TimeUs, _} = timer:tc(fun() ->
        Parent = self(),
        [spawn(fun() ->
            run_kernel(),
            Parent ! {done, I}
        end) || I <- lists:seq(1, N)],
        wait_async(N)
    end),
    TimeMs = TimeUs / 1000.0,
    Throughput = case TimeMs of 0.0 -> 0; _ -> N / (TimeMs / 1000.0) end,
    io:format("=== PORTO ASYNC (N=~p) ===~nTotal Time: ~p ms~nThroughput: ~p TPS~n",
              [N, TimeMs, Throughput]),
    {TimeMs, Throughput}.

%% Spawns the benchmark kernel as an isolated OS process and waits for exit.
run_kernel() ->
    Port = erlang:open_port({spawn, ?BENCHMARK_KERNEL},
                            [{cd, ?BENCHMARK_DIR}, stream, exit_status, binary]),
    collect_port(Port).

collect_port(Port) ->
    receive
        {Port, {data, _}}         -> collect_port(Port);
        {Port, {exit_status, 0}}  -> ok;
        {Port, {exit_status, _}}  -> {error, kernel_failed}
    end.

wait_async(0) -> ok;
wait_async(N) ->
    receive
        {done, _} -> wait_async(N - 1)
    end.
