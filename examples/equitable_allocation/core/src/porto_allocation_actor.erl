-module(porto_allocation_actor).
-behaviour(gen_server).

-export([start_link/4, verify/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link(ParticipantId, Allocation, TotalPool, MinShare) ->
    gen_server:start_link(?MODULE, [ParticipantId, Allocation, TotalPool, MinShare], []).

verify(Pid) ->
    gen_server:call(Pid, verify, infinity).

init([ParticipantId, Allocation, TotalPool, MinShare]) ->
    pg:join(porto_cluster, porto_allocations, self()),
    io:format("Allocation Actor started for participant ~p~n", [ParticipantId]),
    {ok, #{participant_id => ParticipantId,
           allocation     => Allocation,
           total_pool     => TotalPool,
           min_share      => MinShare}}.

handle_call(verify, _From, State = #{participant_id := PId,
                                     allocation     := Alloc,
                                     total_pool     := Pool,
                                     min_share      := Min}) ->
    %% Hard-error policy: if the circuit constraint fails, {ok, _} will not match
    %% and this actor crashes. The supervisor restarts it cleanly.
    {ok, Result} = porto_leo_bridge:verify_allocation(PId, Alloc, Pool, Min),
    io:format("Allocation verified for ~p: ~p~n", [PId, Result]),

    %% Persist verification result to Mnesia for auditability
    mnesia:activity(transaction, fun() ->
        mnesia:write({porto_state, PId, {verified, Alloc, Pool, Min}})
    end),

    {reply, {ok, Result}, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
