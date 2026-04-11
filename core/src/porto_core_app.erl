-module(porto_core_app).
-behaviour(application).

-export([start/2, stop/1, track_resource/1]).

%% @doc Dynamically spawns a new managed resource actor under the simple_one_for_one tree
track_resource(ResourceId) ->
    porto_resource_sup:start_resource(ResourceId).

start(_StartType, _StartArgs) ->
    %% Establish core memory structure for disaster recovery persistence.
    %% Guard against already_exists on nodes with existing persistent schema.
    case mnesia:create_schema([node()]) of
        ok -> ok;
        {error, {_, {already_exists, _}}} -> ok
    end,
    application:start(mnesia),
    io:format("Mnesia Database Sub-Layer Initialized~n"),

    %% Create persistence table — idempotent on restart.
    case mnesia:create_table(porto_state,
            [{attributes, [id, history]},
             {disc_copies, [node()]}]) of
        {atomic, ok}                      -> ok;
        {aborted, {already_exists, _}}    -> ok
    end,
         
    %% Construct external API routing tables securely accepting REST POST injections natively
    Dispatch = cowboy_router:compile([
        {'_', [{"/track", porto_http_handler, []}]}
    ]),
    
    %% Securely mapping universally to TCP port 8080 routing inbound user commands
    {ok, _} = cowboy:start_clear(porto_http_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    io:format("Cowboy API Gateway successfully bounded to TCP Port 8080~n"),
         
    porto_core_sup:start_link().

stop(_State) ->
    ok.
