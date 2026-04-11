-module(porto_http_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    Method = cowboy_req:method(Req),
    case Method of
        <<"POST">> ->
            {ok, Body, Req2} = cowboy_req:read_body(Req),
            handle_body(Body, Req2, State);
        _ ->
            Req2 = cowboy_req:reply(405,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Method Not Allowed\"}">>,
                Req),
            {ok, Req2, State}
    end.

handle_body(<<>>, Req, State) ->
    %% Reject empty payloads immediately
    Req2 = cowboy_req:reply(400,
        #{<<"content-type">> => <<"application/json">>},
        <<"{\"error\": \"Empty request body\"}">>,
        Req),
    {ok, Req2, State};
handle_body(Body, Req, State) ->
    %% Parse JSON via jsx; catch decode errors to prevent crashes
    try jsx:decode(Body, [return_maps]) of
        #{<<"resource_id">> := ResourceId} when is_binary(ResourceId), ResourceId =/= <<>> ->
            %% Valid payload — spawn the tracking actor
            porto_core_app:track_resource(ResourceId),
            Req2 = cowboy_req:reply(200,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"status\": \"tracking initiated\"}">>,
                Req),
            {ok, Req2, State};
        _ ->
            %% JSON parsed but missing or invalid resource_id field
            Req2 = cowboy_req:reply(400,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Missing or invalid 'resource_id' field\"}">>,
                Req),
            {ok, Req2, State}
    catch
        _:_ ->
            %% Malformed JSON
            Req2 = cowboy_req:reply(400,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Invalid JSON payload\"}">>,
                Req),
            {ok, Req2, State}
    end.
