-module(porto_leo_bridge).
-behaviour(gen_server).

-export([start_link/0, verify_proof/1, verify_allocation/4, verify_quota/3, verify_eligibility/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

verify_proof(StateData) ->
    gen_server:call(?MODULE, {verify_proof, StateData}, infinity).

%% Hashes the ParticipantId using SHA-256, truncates to 128 bits,
%% and submits an allocation fairness proof to the Leo circuit.
verify_allocation(ParticipantId, Allocation, TotalPool, MinShare) ->
    <<Hash:128, _/binary>> = crypto:hash(sha256, term_to_binary(ParticipantId)),
    gen_server:call(?MODULE,
        {verify_allocation, Allocation, Hash, TotalPool, MinShare},
        infinity).

%% Proves that an organisation's resource usage did not exceed its quota.
%% Usage is kept private; only the quota ceiling is public.
verify_quota(ParticipantId, Usage, Quota) ->
    <<Hash:128, _/binary>> = crypto:hash(sha256, term_to_binary(ParticipantId)),
    gen_server:call(?MODULE,
        {verify_quota, Usage, Hash, Quota},
        infinity).

%% Proves an applicant's eligibility score meets a public threshold
%% for access to a public digital service. Score stays private.
verify_eligibility(ApplicantId, Score, Threshold) ->
    <<Hash:128, _/binary>> = crypto:hash(sha256, term_to_binary(ApplicantId)),
    gen_server:call(?MODULE,
        {verify_eligibility, Score, Hash, Threshold},
        infinity).

init([]) ->
    io:format("Initializing PORTO Leo Bridge...~n"),
    {ok, #{pending_verifications => #{}}}.

handle_call({verify_proof, StateData}, From, State = #{pending_verifications := Pending}) ->
    io:format("Delegating zero-knowledge proof generation to Leo for state: ~p~n", [StateData]),
    
    %% Formalized JSON serialization boundary leveraging JSX.
    %% This ensures the Erlang Maps adhere perfectly to exact schema limits 
    %% before we project them out to the Rust Zero-Knowledge circuits.
    JsonPayload = jsx:encode(StateData),
    StructuredData = jsx:decode(JsonPayload, [return_maps]),
    ParsedId = maps:get(<<"id">>, StructuredData, 1),
    
    Payload = integer_to_list(ParsedId) ++ "u32",
    Command = "leo run main " ++ Payload,
    
    %% Open an OS Port to securely run the Rust/Leo compilation securely in another OS process.
    %% We set the working directory strictly to the circuits folder.
    Port = erlang:open_port({spawn, Command}, 
                            [{cd, "../circuits"}, stream, exit_status, binary]),
                            
    %% Store the caller reference (`From`) to respond asynchronously without blocking other actors
    NewPending = maps:put(Port, From, Pending),
    {noreply, State#{pending_verifications => NewPending}};

handle_call({verify_allocation, Allocation, Hash, TotalPool, MinShare}, From,
            State = #{pending_verifications := Pending}) ->
    Command = "leo run verify_allocation "
        ++ integer_to_list(Allocation)  ++ "u32 "
        ++ integer_to_list(Hash)        ++ "u128 "
        ++ integer_to_list(TotalPool)   ++ "u32 "
        ++ integer_to_list(MinShare)    ++ "u32",
    io:format("Submitting allocation proof: ~s~n", [Command]),
    Port = erlang:open_port({spawn, Command},
                            [{cd, "../examples/equitable_allocation/circuits"},
                             stream, exit_status, binary]),
    NewPending = maps:put(Port, From, Pending),
    {noreply, State#{pending_verifications => NewPending}};

handle_call({verify_quota, Usage, Hash, Quota}, From,
            State = #{pending_verifications := Pending}) ->
    Command = "leo run verify_quota "
        ++ integer_to_list(Usage)  ++ "u32 "
        ++ integer_to_list(Hash)   ++ "u128 "
        ++ integer_to_list(Quota)  ++ "u32",
    io:format("Submitting quota compliance proof: ~s~n", [Command]),
    Port = erlang:open_port({spawn, Command},
                            [{cd, "../examples/sustainability_quota/circuits"},
                             stream, exit_status, binary]),
    NewPending = maps:put(Port, From, Pending),
    {noreply, State#{pending_verifications => NewPending}};

handle_call({verify_eligibility, Score, Hash, Threshold}, From,
            State = #{pending_verifications := Pending}) ->
    Command = "leo run verify_eligibility "
        ++ integer_to_list(Score)     ++ "u32 "
        ++ integer_to_list(Hash)      ++ "u128 "
        ++ integer_to_list(Threshold) ++ "u32",
    io:format("Submitting eligibility proof: ~s~n", [Command]),
    Port = erlang:open_port({spawn, Command},
                            [{cd, "../examples/service_eligibility/circuits"},
                             stream, exit_status, binary]),
    NewPending = maps:put(Port, From, Pending),
    {noreply, State#{pending_verifications => NewPending}};

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% Capture the streamed stdout from the Leo process
handle_info({Port, {data, Data}}, State) ->
    io:format("Leo Execution Output: ~s~n", [Data]),
    {noreply, State};

%% Capture the termination status of the OS process and report the cryptographic truth
handle_info({Port, {exit_status, Status}}, State = #{pending_verifications := Pending}) ->
    case maps:take(Port, Pending) of
        {From, RemainingPending} ->
            Reply = case Status of
                0 -> {ok, valid_proof};
                _ -> {error, invalid_proof}
            end,
            gen_server:reply(From, Reply),
            {noreply, State#{pending_verifications => RemainingPending}};
        error ->
            {noreply, State}
    end;

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
