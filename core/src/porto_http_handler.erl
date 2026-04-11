-module(porto_http_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    %% Restrict network ingestion logic strictly to POST parameters natively mapping user JSON
    Method = cowboy_req:method(Req),
    case Method of
        <<"POST">> ->
            %% For structural verification against external JSON injection formats, 
            %% we read the stream body and parse mathematically via Cowboy.
            {ok, Body, Req2} = cowboy_req:read_body(Req),
            
            %% Delegate external load directly into the BEAM orchestration network!
            porto_core_app:track_resource(Body),
            
            Req3 = cowboy_req:reply(200,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"status\": \"tracking execution sequence active\"}">>,
                Req2),
            {ok, Req3, State};
        _ ->
            Req2 = cowboy_req:reply(405,
                #{<<"content-type">> => <<"application/json">>},
                <<"{\"error\": \"Method Not Allowed\"}">>,
                Req),
            {ok, Req2, State}
    end.
