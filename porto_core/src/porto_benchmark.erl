-module(porto_benchmark).
-export([run_sync/1, run_porto_async/1]).

%% Baseline: Monolithic Synchronous Sequencer
%% Executes N ZK Proof evaluations in sequence.
run_sync(N) ->
    {TimeUs, _} = timer:tc(fun() -> 
        loop_sync(N)
    end),
    TimeMs = TimeUs / 1000.0,
    Throughput = case TimeMs of 0.0 -> 0; _ -> N / (TimeMs / 1000.0) end,
    io:format("=== SYNC BASELINE ===~nTotal Time: ~p ms~nThroughput: ~p TPS~n", [TimeMs, Throughput]),
    {TimeMs, Throughput}.

loop_sync(0) -> ok;
loop_sync(N) ->
    %% Simulate the actual cryptographic workload by hitting the OS API synchronously and waiting
    {ok, _} = porto_leo_bridge:verify_proof(#{id => N}),
    loop_sync(N - 1).

%% PORTO Architecture: Asynchronous OS Port Isolation
%% Executes N ZK Proofs concurrently through individual simple_one_for_one actors.
run_porto_async(N) ->
    {TimeUs, _} = timer:tc(fun() -> 
        Parent = self(),
        %% Blast N parallel tracking processes natively via the Erlang engine
        [spawn(fun() -> 
            %% Each process hits the bridge (representing its own isolated OS container call)
            porto_leo_bridge:verify_proof(#{id => I}),
            Parent ! {done, I}
        end) || I <- lists:seq(1, N)],
        wait_async(N)
    end),
    TimeMs = TimeUs / 1000.0,
    Throughput = case TimeMs of 0.0 -> 0; _ -> N / (TimeMs / 1000.0) end,
    io:format("=== PORTO ASYNC ===~nTotal Time: ~p ms~nThroughput: ~p TPS~n", [TimeMs, Throughput]),
    {TimeMs, Throughput}.

wait_async(0) -> ok;
wait_async(N) ->
    receive
        {done, _I} -> wait_async(N - 1)
    end.
