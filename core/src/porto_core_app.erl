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
         
    %% Read HTTP port from sys.config (resolved from $PORT env var at release time),
    %% falling back to 8080 if not configured.
    HttpPort = case application:get_env(core, http_port) of
        {ok, P} when is_integer(P) -> P;
        {ok, P} when is_list(P)    -> list_to_integer(P);
        _                          -> 8080
    end,

    Dispatch = cowboy_router:compile([
        {'_', [{"/track", porto_http_handler, []}]}
    ]),
    {ok, _} = cowboy:start_clear(porto_http_listener,
        [{port, HttpPort}],
        #{env => #{dispatch => Dispatch}}
    ),
    io:format("Cowboy API Gateway listening on TCP port ~p~n", [HttpPort]),
         
    porto_core_sup:start_link().

stop(_State) ->
    ok.
