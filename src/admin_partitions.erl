%% -------------------------------------------------------------------
%%
%% Copyright (c) 2011 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(admin_partitions).

-author('Christopher Meiklejohn <cmeiklejohn@basho.com>').

-export([routes/0,
         init/1,
         content_types_provided/2,
         to_json/2,
         is_authorized/2,
         service_available/2,
         forbidden/2]).

-include_lib("riak_control/include/riak_control.hrl").
-include_lib("webmachine/include/webmachine.hrl").

-define(CONTENT_TYPES, [{"application/json",to_json}]).

-define(VNODE_TYPES, [riak_kv,riak_pipe,riak_search]).

-record(context, {partitions}).

%% @doc Route handling.
routes() ->
    [{admin_routes:partitions_route(), ?MODULE, []}].

%% @doc Get partition list at the start of the request.
init([]) ->
    {ok, _, Partitions} = riak_control_session:get_partitions(),
    {ok, #context{partitions=Partitions}}.

%% @doc Validate origin.
forbidden(ReqData, Context) ->
    {riak_control_security:is_null_origin(ReqData), ReqData, Context}.

%% @doc Determine if it's available.
service_available(ReqData, Context) ->
    riak_control_security:scheme_is_available(ReqData, Context).

%% @doc Handle authorization.
is_authorized(ReqData, Context) ->
    riak_control_security:enforce_auth(ReqData, Context).

%% @doc Return available content types.
content_types_provided(ReqData, Context) ->
    {?CONTENT_TYPES, ReqData, Context}.

%% @doc Return a list of partitions.
to_json(ReqData, Context) ->
    {ok, _, Nodes} = riak_control_session:get_nodes(),
    Details = [{struct,
                riak_control_formatting:node_ring_details(P, Nodes)} ||
                P <- Context#context.partitions],
    {mochijson2:encode({struct,[{partitions,Details}]}), ReqData, Context}.
