-module(porto_allocation_sup).
-behaviour(supervisor).

-export([start_link/0, start_allocation/4]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% Spawns a new allocation actor for a participant under the simple_one_for_one tree.
start_allocation(ParticipantId, Allocation, TotalPool, MinShare) ->
    supervisor:start_child(?SERVER, [ParticipantId, Allocation, TotalPool, MinShare]).

init([]) ->
    SupFlags = #{strategy  => simple_one_for_one,
                 intensity => 10,
                 period    => 5},
    ChildSpecs = [
        #{id       => porto_allocation_actor,
          start    => {porto_allocation_actor, start_link, []},
          restart  => temporary,   %% hard-error philosophy: crash and restart on bad proof
          shutdown => 2000,
          type     => worker,
          modules  => [porto_allocation_actor]}
    ],
    {ok, {SupFlags, ChildSpecs}}.
