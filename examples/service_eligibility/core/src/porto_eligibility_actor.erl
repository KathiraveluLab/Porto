-module(porto_eligibility_actor).
-behaviour(gen_server).

-export([start_link/3, verify/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link(ApplicantId, Score, Threshold) ->
    gen_server:start_link(?MODULE, [ApplicantId, Score, Threshold], []).

verify(Pid) ->
    gen_server:call(Pid, verify, infinity).

init([ApplicantId, Score, Threshold]) ->
    pg:join(porto_cluster, porto_eligibility_checks, self()),
    io:format("Eligibility Actor started for applicant ~p~n", [ApplicantId]),
    {ok, #{applicant_id => ApplicantId,
           score        => Score,
           threshold    => Threshold}}.

handle_call(verify, _From, State = #{applicant_id := AId,
                                     score        := Score,
                                     threshold    := Threshold}) ->
    %% Hard-error policy: if score > threshold the circuit aborts,
    %% {ok, _} will not match, and this actor crashes cleanly.
    {ok, Result} = porto_leo_bridge:verify_eligibility(AId, Score, Threshold),
    io:format("Eligibility verified for ~p: ~p~n", [AId, Result]),

    %% Persist eligibility result to Mnesia - applicant's score is NOT stored,
    %% only the fact of eligibility and the threshold applied.
    mnesia:activity(transaction, fun() ->
        mnesia:write({porto_state, AId, {eligible, Threshold}})
    end),

    {reply, {ok, Result}, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
