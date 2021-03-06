%%% Copyright (c) 2013, Samuel Rivas <samuelrivas@gmail.com>
%%% All rights reserved.
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%     * Redistributions of source code must retain the above copyright
%%%       notice, this list of conditions and the following disclaimer.
%%%     * Redistributions in binary form must reproduce the above copyright
%%%       notice, this list of conditions and the following disclaimer in the
%%%       documentation and/or other materials provided with the distribution.
%%%     * Neither the name the author nor the names of its contributors may
%%%       be used to endorse or promote products derived from this software
%%%       without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
%%% INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
%%% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
%%% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%%% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
%%% THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%%% @doc A server to hold the call history for a moka
-module(moka_history).

-behaviour(gen_server).

%%%_* Exports ==========================================================

%% API
-export([start_link/1, stop/1, add_return/4, add_exception/5, get_calls/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


%%%_* Includes =========================================================

%%%_* Types ============================================================
-record(state, {
          calls = [] :: moka:history()
         }).

-type server()        :: atom().

-export_type([server/0]).

%%%_* API ==============================================================

%% @doc Start a history server
-spec start_link(server()) -> {ok, pid()}.
start_link(Name) -> gen_server:start_link({local, Name}, ?MODULE, none, []).

%% @doc Add a successful function call to the history
-spec add_return(
        server(), moka_call_handler:call_description(),
        [any()], moka:return()) -> ok.
add_return(ServerName, CallDescription, Args, Value) ->
    add_call(ServerName, CallDescription, Args, {return, Value}).

%% @doc Add a failed function call to the history
-spec add_exception(
        server(), moka_call_handler:call_description(),
        [any()], moka:class(), any()) -> ok.
add_exception(ServerName, CallDescription, Args, Class, Reason) ->
    add_call(ServerName, CallDescription, Args, {exception, Class, Reason}).

-spec add_call(
        server(),
        moka_call_handler:call_description(),
        [any()],
        moka:result()) -> ok.
add_call(ServerName, CallDescription, Args, Result) ->
    sel_gen_server:call(ServerName, {add_call, {CallDescription, Args, Result}}).

%% @doc Get the call history
-spec get_calls(server()) -> moka:history().
get_calls(ServerName) -> sel_gen_server:call(ServerName, get_calls).

%% @doc Stop a history server
%%
%% This is typically used for testing
-spec stop(server()) -> ok.
stop(ServerName) -> sel_gen_server:call(ServerName, stop).

%%%_* gen_server callbacks =============================================

%% @private
init(none) -> {ok, #state{}}.

%% @private
handle_call(get_calls, _From, State) ->
    {reply, lists:reverse(State#state.calls), State};
handle_call(stop, _From, State) ->
    {stop, normal, ok, State};
handle_call({add_call, Call}, _From, State) ->
    {reply, ok, State#state{calls = [Call | State#state.calls]}};
handle_call(Request, _From, State) ->
    {reply, {error, {bad_call, Request}}, State}.

%% @private
handle_cast(_Msg, State) -> {noreply, State}.

%% @private
handle_info(_Info, State) -> {noreply, State}.

%% @private
terminate(_Reason, _State) -> ok.

%% @private
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%%_* Private Functions ================================================

%%%_* Emacs ============================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 4
%%% End:
