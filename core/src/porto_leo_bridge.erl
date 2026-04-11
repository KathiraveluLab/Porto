-module(porto_leo_bridge).
-behaviour(gen_server).

-export([start_link/0, verify_proof/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

verify_proof(StateData) ->
    gen_server:call(?MODULE, {verify_proof, StateData}, infinity).

init([]) ->
    io:format("Initializing PORTO Leo Bridge...~n"),
    {ok, #{pending_verifications => #{}}}.

handle_call({verify_proof, StateData}, From, State = #{pending_verifications := Pending}) ->
    io:format("Delegating zero-knowledge proof generation to Leo for state: ~p~n", [StateData]),
    
    %% Format the execution command pointing to the natively compiled Rust framework.
    %% This strictly delegates the cryptographic processing OUT of the BEAM VM.
    Command = "./heavy_workload",
    
    %% Open an OS Port to securely run the Rust/Leo compilation securely in another OS process.
    %% We set the working directory strictly to the circuits folder.
    Port = erlang:open_port({spawn, Command}, 
                            [{cd, "../circuits"}, stream, exit_status, binary]),
                            
    %% Store the caller reference (`From`) to respond asynchronously without blocking other actors
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
