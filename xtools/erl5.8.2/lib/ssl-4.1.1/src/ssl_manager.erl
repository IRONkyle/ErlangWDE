%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2007-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

%%----------------------------------------------------------------------
%% Purpose: Manages ssl sessions and trusted certifacates
%%----------------------------------------------------------------------

-module(ssl_manager).
-behaviour(gen_server).

-include("ssl_internal.hrl").

%% Internal application API
-export([start_link/1, 
	 connection_init/2, cache_pem_file/1,
	 lookup_trusted_cert/3, issuer_candidate/1, client_session_id/3, 
	 server_session_id/3,
	 register_session/2, register_session/3, invalidate_session/2,
	 invalidate_session/3]).

% Spawn export
-export([init_session_validator/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-include("ssl_handshake.hrl").
-include("ssl_internal.hrl").

-record(state, {
	  session_cache,
	  session_cache_cb,
	  session_lifetime,
	  certificate_db,
	  session_validation_timer
	 }).

-define('24H_in_msec', 8640000).
-define('24H_in_sec', 8640).
-define(SESSION_VALIDATION_INTERVAL, 60000).
-define(CERTIFICATE_CACHE_CLEANUP, 30000).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
-spec start_link(list()) -> {ok, pid()} | ignore | {error, term()}.
%%
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link(Opts) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Opts], []).

%%--------------------------------------------------------------------
-spec connection_init(string()| {der, list()}, client | server) -> {ok, reference(), cache_ref()}.
%%			     
%% Description: Do necessary initializations for a new connection.
%%--------------------------------------------------------------------
connection_init(Trustedcerts, Role) ->
    call({connection_init, Trustedcerts, Role}).
%%--------------------------------------------------------------------
-spec cache_pem_file(string()) -> {ok, term()}.	
%%		    
%% Description: Cach a pem file and 
%%--------------------------------------------------------------------
cache_pem_file(File) ->   
    case ssl_certificate_db:lookup_cached_certs(File) of
	[{_,Content}] ->
	    {ok, Content};
	[] ->
	    call({cache_pem, File})
    end.
%%--------------------------------------------------------------------
-spec lookup_trusted_cert(reference(), serialnumber(), issuer()) -> 
				 undefined | 
				 {ok, {der_cert(), #'OTPCertificate'{}}}.
%%				 
%% Description: Lookup the trusted cert with Key = {reference(),
%% serialnumber(), issuer()}.
%% --------------------------------------------------------------------
lookup_trusted_cert(Ref, SerialNumber, Issuer) ->
    ssl_certificate_db:lookup_trusted_cert(Ref, SerialNumber, Issuer).
%%--------------------------------------------------------------------
-spec issuer_candidate(cert_key() | no_candidate) -> 
			      {cert_key(), {der_cert(), #'OTPCertificate'{}}} | no_more_candidates.      
%%
%% Description: Return next issuer candidate.
%%--------------------------------------------------------------------
issuer_candidate(PrevCandidateKey) ->
    ssl_certificate_db:issuer_candidate(PrevCandidateKey).
%%--------------------------------------------------------------------
-spec client_session_id(host(), port_num(), #ssl_options{}) -> session_id().
%%
%% Description: Select a session id for the client.
%%--------------------------------------------------------------------
client_session_id(Host, Port, SslOpts) ->
    call({client_session_id, Host, Port, SslOpts}).

%%--------------------------------------------------------------------
-spec server_session_id(host(), port_num(), #ssl_options{}) -> session_id().
%%
%% Description: Select a session id for the server.
%%--------------------------------------------------------------------
server_session_id(Port, SuggestedSessionId, SslOpts) ->
    call({server_session_id, Port, SuggestedSessionId, SslOpts}).

%%--------------------------------------------------------------------
-spec register_session(port_num(), #session{}) -> ok.
-spec register_session(host(), port_num(), #session{}) -> ok.
%%
%% Description: Make the session available for reuse.
%%--------------------------------------------------------------------
register_session(Host, Port, Session) ->
    cast({register_session, Host, Port, Session}).

register_session(Port, Session) ->
    cast({register_session, Port, Session}).
%%--------------------------------------------------------------------
-spec invalidate_session(port_num(), #session{}) -> ok.
-spec invalidate_session(host(), port_num(), #session{}) -> ok.
%%
%% Description: Make the session unavilable for reuse.
%%--------------------------------------------------------------------
invalidate_session(Host, Port, Session) ->
    cast({invalidate_session, Host, Port, Session}).

invalidate_session(Port, Session) ->
    cast({invalidate_session, Port, Session}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
-spec init(list()) -> {ok, #state{}}.
%% Possible return values not used now. 
%% |  {ok, #state{}, timeout()} | ignore | {stop, term()}.		  
%%
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([Opts]) ->
    process_flag(trap_exit, true),
    CacheCb = proplists:get_value(session_cb, Opts, ssl_session_cache),
    SessionLifeTime =  
	proplists:get_value(session_lifetime, Opts, ?'24H_in_sec'),
    CertDb = ssl_certificate_db:create(),
    SessionCache = CacheCb:init(proplists:get_value(session_cb_init_args, Opts, [])),
    Timer = erlang:send_after(SessionLifeTime * 1000, 
			      self(), validate_sessions),
    {ok, #state{certificate_db = CertDb,
		session_cache = SessionCache,
		session_cache_cb = CacheCb,
		session_lifetime = SessionLifeTime,
		session_validation_timer = Timer}}.

%%--------------------------------------------------------------------
-spec handle_call(msg(), from(), #state{}) -> {reply, reply(), #state{}}. 
%% Possible return values not used now.  
%%					      {reply, reply(), #state{}, timeout()} |
%%					      {noreply, #state{}} |
%%					      {noreply, #state{}, timeout()} |
%%					      {stop, reason(), reply(), #state{}} |
%%					      {stop, reason(), #state{}}.
%%
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({{connection_init, "", _Role}, Pid}, _From, 
	    #state{session_cache = Cache} = State) ->
    erlang:monitor(process, Pid),
    Result = {ok, make_ref(), Cache},
    {reply, Result, State};

handle_call({{connection_init, Trustedcerts, _Role}, Pid}, _From,
	    #state{certificate_db = Db,
		   session_cache = Cache} = State) ->
    erlang:monitor(process, Pid),
    Result = 
	try
	    {ok, Ref} = ssl_certificate_db:add_trusted_certs(Pid, Trustedcerts, Db),
	    {ok, Ref, Cache}
	catch
	    _:Reason ->
		{error, Reason}
	end,
    {reply, Result, State};

handle_call({{client_session_id, Host, Port, SslOpts}, _}, _, 
	    #state{session_cache = Cache,
		  session_cache_cb = CacheCb} = State) ->
    Id = ssl_session:id({Host, Port, SslOpts}, Cache, CacheCb),
    {reply, Id, State};

handle_call({{server_session_id, Port, SuggestedSessionId, SslOpts}, _},
	    _, #state{session_cache_cb = CacheCb,
		      session_cache = Cache,
		      session_lifetime = LifeTime} = State) ->
    Id = ssl_session:id(Port, SuggestedSessionId, SslOpts,
			Cache, CacheCb, LifeTime),
    {reply, Id, State};

handle_call({{cache_pem, File},Pid}, _, State = #state{certificate_db = Db}) ->
    try ssl_certificate_db:cache_pem_file(Pid,File,Db) of
	Result ->
	    {reply, Result, State}
    catch 
	_:Reason ->
	    {reply, {error, Reason}, State}
    end.
%%--------------------------------------------------------------------
-spec  handle_cast(msg(), #state{}) -> {noreply, #state{}}.
%% Possible return values not used now.  
%%				      | {noreply, #state{}, timeout()} |
%%				       {stop, reason(), #state{}}.
%%
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast({register_session, Host, Port, Session}, 
	    #state{session_cache = Cache,
		   session_cache_cb = CacheCb} = State) ->
    TimeStamp = calendar:datetime_to_gregorian_seconds({date(), time()}),
    NewSession = Session#session{time_stamp = TimeStamp},
    CacheCb:update(Cache, {{Host, Port}, 
		   NewSession#session.session_id}, NewSession),
    {noreply, State};

handle_cast({register_session, Port, Session},  
	    #state{session_cache = Cache,
		   session_cache_cb = CacheCb} = State) ->    
    TimeStamp = calendar:datetime_to_gregorian_seconds({date(), time()}),
    NewSession = Session#session{time_stamp = TimeStamp},
    CacheCb:update(Cache, {Port, NewSession#session.session_id}, NewSession),
    {noreply, State};

handle_cast({invalidate_session, Host, Port, 
	     #session{session_id = ID}}, 
	    #state{session_cache = Cache,
		   session_cache_cb = CacheCb} = State) ->
    CacheCb:delete(Cache, {{Host, Port}, ID}),
    {noreply, State};

handle_cast({invalidate_session, Port, #session{session_id = ID}}, 
	    #state{session_cache = Cache,
		   session_cache_cb = CacheCb} = State) ->
    CacheCb:delete(Cache, {Port, ID}),
    {noreply, State}.

%%--------------------------------------------------------------------
-spec handle_info(msg(), #state{}) -> {noreply, #state{}}.
%% Possible return values not used now.
%%				      |{noreply, #state{}, timeout()} |
%%				      {stop, reason(), #state{}}.
%%
%% Description: Handling all non call/cast messages
%%-------------------------------------------------------------------- 
handle_info(validate_sessions, #state{session_cache_cb = CacheCb,
				      session_cache = Cache,
				      session_lifetime = LifeTime
				     } = State) ->
    Timer = erlang:send_after(?SESSION_VALIDATION_INTERVAL, 
			      self(), validate_sessions),
    start_session_validator(Cache, CacheCb, LifeTime),
    {noreply, State#state{session_validation_timer = Timer}};

handle_info({'EXIT', _, _}, State) ->
    %% Session validator died!! Do we need to take any action?
    %% maybe error log
    {noreply, State};

handle_info({'DOWN', _Ref, _Type, _Pid, ecacertfile}, State) ->
    {noreply, State};

handle_info({'DOWN', _Ref, _Type, Pid, _Reason}, State) ->
    erlang:send_after(?CERTIFICATE_CACHE_CLEANUP, self(), 
		      {remove_trusted_certs, Pid}),
    {noreply, State};
handle_info({remove_trusted_certs, Pid}, 
	    State = #state{certificate_db = Db}) ->
    ssl_certificate_db:remove_trusted_certs(Pid, Db),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
-spec terminate(reason(), #state{}) -> term().
%%		       
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, #state{certificate_db = Db,
			  session_cache = SessionCache,
			  session_cache_cb = CacheCb,
			  session_validation_timer = Timer}) ->
    erlang:cancel_timer(Timer),
    ssl_certificate_db:remove(Db),
    CacheCb:terminate(SessionCache),
    ok.

%%--------------------------------------------------------------------
-spec code_change(term(), #state{}, list()) -> {ok, #state{}}.			 
%%
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
call(Msg) ->
    gen_server:call(?MODULE, {Msg, self()}, infinity).

cast(Msg) ->
    gen_server:cast(?MODULE, Msg).
 
validate_session(Host, Port, Session, LifeTime) ->
    case ssl_session:valid_session(Session, LifeTime) of
	true ->
	    ok;
	false ->
	    invalidate_session(Host, Port, Session)
    end.

validate_session(Port, Session, LifeTime) ->
    case ssl_session:valid_session(Session, LifeTime) of
	true ->
	    ok;
	false ->
	    invalidate_session(Port, Session)
    end.
		    
start_session_validator(Cache, CacheCb, LifeTime) ->
    spawn_link(?MODULE, init_session_validator, 
	       [[Cache, CacheCb, LifeTime]]).

init_session_validator([Cache, CacheCb, LifeTime]) ->
    CacheCb:foldl(fun session_validation/2,
		  LifeTime, Cache).

session_validation({{{Host, Port}, _}, Session}, LifeTime) ->
    validate_session(Host, Port, Session, LifeTime),
    LifeTime;
session_validation({{Port, _}, Session}, LifeTime) ->
    validate_session(Port, Session, LifeTime),
    LifeTime.
