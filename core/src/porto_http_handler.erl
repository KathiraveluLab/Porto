-module(porto_http_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, Opts) ->
    Action = proplists:get_value(action, Opts, track),
    Method = cowboy_req:method(Req),
    case Method of
        <<"POST">> ->
            {ok, Body, Req2} = cowboy_req:read_body(Req),
            handle_body(Action, Body, Req2, Opts);
        _ ->
            Req2 = cowboy_req:reply(405,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Method Not Allowed\"}">>,
                Req),
            {ok, Req2, Opts}
    end.

%% ---- /track ---------------------------------------------------------------

handle_body(track, <<>>, Req, State) ->
    Req2 = cowboy_req:reply(400,
        #{<<"content-type">> => <<"application/json">>},
        <<"{\"error\": \"Empty request body\"}">>,
        Req),
    {ok, Req2, State};
handle_body(track, Body, Req, State) ->
    try jsx:decode(Body, [return_maps]) of
        #{<<"resource_id">> := ResourceId} when is_binary(ResourceId), ResourceId =/= <<>> ->
            porto_core_app:track_resource(ResourceId),
            Req2 = cowboy_req:reply(200,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"status\": \"tracking initiated\"}">>,
                Req),
            {ok, Req2, State};
        _ ->
            Req2 = cowboy_req:reply(400,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Missing or invalid 'resource_id' field\"}">>,
                Req),
            {ok, Req2, State}
    catch _:_ ->
        Req2 = cowboy_req:reply(400,
            #{<<"content-type">> => <<"application/json">>},
            <<"{\"error\": \"Invalid JSON payload\"}">>,
            Req),
        {ok, Req2, State}
    end.

%% ---- /allocate is handled by the equitable_allocation example, not core ----
%% See examples/equitable_allocation/core/src/ for the allocation handler.

