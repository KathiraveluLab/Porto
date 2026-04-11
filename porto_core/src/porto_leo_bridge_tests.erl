-module(porto_leo_bridge_tests).
-include_lib("eunit/include/eunit.hrl").

valid_proof_routing_test() ->
    Ref = make_ref(),
    From = {self(), Ref},
    State = #{pending_verifications => #{mock_port => From}},
    
    %% Simulate a 0 exit status (success) from Aleo OS Port via the supervisor trapping
    {noreply, NewState} = porto_leo_bridge:handle_info({mock_port, {exit_status, 0}}, State),
    
    %% Verify the task was popped from the tracking registry
    ?assertEqual(#{}, maps:get(pending_verifications, NewState)),
    %% Verify the correct mathematically validated message was routed back to the isolated actor
    receive
        {Ref, Reply} -> ?assertEqual({ok, valid_proof}, Reply)
    after 1000 ->
        ?assert(false)
    end.

invalid_proof_panic_test() ->
    Ref = make_ref(),
    From = {self(), Ref},
    State = #{pending_verifications => #{mock_port => From}},
    
    %% Simulate a Rust panic/memory crash (Non-0 exit) from the underlying Aleo OS Port
    {noreply, NewState} = porto_leo_bridge:handle_info({mock_port, {exit_status, 137}}, State),
    
    ?assertEqual(#{}, maps:get(pending_verifications, NewState)),
    receive
        {Ref, Reply} -> ?assertEqual({error, invalid_proof}, Reply)
    after 1000 ->
        ?assert(false)
    end.

untracked_rogue_port_test() ->
    State = #{pending_verifications => #{}},
    %% Simulate an unknown OS port crashing that isn't mapped to an actor
    {noreply, NewState} = porto_leo_bridge:handle_info({unknown_port, {exit_status, 1}}, State),
    ?assertEqual(#{}, maps:get(pending_verifications, NewState)).
