%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosNaming_NamingContext
%% Source: /net/isildur/ldisk/daily_build/r14b01_prebuild_opu_o.2010-12-07_16/otp_src_R14B01/lib/orber/COSS/CosNaming/cos_naming.idl
%% IC vsn: 4.2.25
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosNaming_NamingContext').
-ic_compiled("4_2_25").


%% Interface functions
-export([bind/3, bind/4, rebind/3]).
-export([rebind/4, bind_context/3, bind_context/4]).
-export([rebind_context/3, rebind_context/4, resolve/2]).
-export([resolve/3, unbind/2, unbind/3]).
-export([new_context/1, new_context/2, bind_new_context/2]).
-export([bind_new_context/3, destroy/1, destroy/2]).
-export([list/2, list/3]).

%% Type identification function
-export([typeID/0]).

%% Used to start server
-export([oe_create/0, oe_create_link/0, oe_create/1]).
-export([oe_create_link/1, oe_create/2, oe_create_link/2]).

%% TypeCode Functions and inheritance
-export([oe_tc/1, oe_is_a/1, oe_get_interface/0]).

%% gen server export stuff
-behaviour(gen_server).
-export([init/1, terminate/2, handle_call/3]).
-export([handle_cast/2, handle_info/2, code_change/3]).

-include_lib("orber/include/corba.hrl").


%%------------------------------------------------------------
%%
%% Object interface functions.
%%
%%------------------------------------------------------------



%%%% Operation: bind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName, CosNaming::NamingContext::AlreadyBound
%%
bind(OE_THIS, N, Obj) ->
    corba:call(OE_THIS, bind, [N, Obj], ?MODULE).

bind(OE_THIS, OE_Options, N, Obj) ->
    corba:call(OE_THIS, bind, [N, Obj], ?MODULE, OE_Options).

%%%% Operation: rebind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
rebind(OE_THIS, N, Obj) ->
    corba:call(OE_THIS, rebind, [N, Obj], ?MODULE).

rebind(OE_THIS, OE_Options, N, Obj) ->
    corba:call(OE_THIS, rebind, [N, Obj], ?MODULE, OE_Options).

%%%% Operation: bind_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName, CosNaming::NamingContext::AlreadyBound
%%
bind_context(OE_THIS, N, Nc) ->
    corba:call(OE_THIS, bind_context, [N, Nc], ?MODULE).

bind_context(OE_THIS, OE_Options, N, Nc) ->
    corba:call(OE_THIS, bind_context, [N, Nc], ?MODULE, OE_Options).

%%%% Operation: rebind_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
rebind_context(OE_THIS, N, Nc) ->
    corba:call(OE_THIS, rebind_context, [N, Nc], ?MODULE).

rebind_context(OE_THIS, OE_Options, N, Nc) ->
    corba:call(OE_THIS, rebind_context, [N, Nc], ?MODULE, OE_Options).

%%%% Operation: resolve
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
resolve(OE_THIS, N) ->
    corba:call(OE_THIS, resolve, [N], ?MODULE).

resolve(OE_THIS, OE_Options, N) ->
    corba:call(OE_THIS, resolve, [N], ?MODULE, OE_Options).

%%%% Operation: unbind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
unbind(OE_THIS, N) ->
    corba:call(OE_THIS, unbind, [N], ?MODULE).

unbind(OE_THIS, OE_Options, N) ->
    corba:call(OE_THIS, unbind, [N], ?MODULE, OE_Options).

%%%% Operation: new_context
%% 
%%   Returns: RetVal
%%
new_context(OE_THIS) ->
    corba:call(OE_THIS, new_context, [], ?MODULE).

new_context(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, new_context, [], ?MODULE, OE_Options).

%%%% Operation: bind_new_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::AlreadyBound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
bind_new_context(OE_THIS, N) ->
    corba:call(OE_THIS, bind_new_context, [N], ?MODULE).

bind_new_context(OE_THIS, OE_Options, N) ->
    corba:call(OE_THIS, bind_new_context, [N], ?MODULE, OE_Options).

%%%% Operation: destroy
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotEmpty
%%
destroy(OE_THIS) ->
    corba:call(OE_THIS, destroy, [], ?MODULE).

destroy(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, destroy, [], ?MODULE, OE_Options).

%%%% Operation: list
%% 
%%   Returns: RetVal, Bl, Bi
%%
list(OE_THIS, How_many) ->
    corba:call(OE_THIS, list, [How_many], ?MODULE).

list(OE_THIS, OE_Options, How_many) ->
    corba:call(OE_THIS, list, [How_many], ?MODULE, OE_Options).

%%------------------------------------------------------------
%%
%% Inherited Interfaces
%%
%%------------------------------------------------------------
oe_is_a("IDL:omg.org/CosNaming/NamingContext:1.0") -> true;
oe_is_a(_) -> false.

%%------------------------------------------------------------
%%
%% Interface TypeCode
%%
%%------------------------------------------------------------
oe_tc(bind) -> 
	{tk_void,
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                     "NameComponent",
                     [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                 0},
             {tk_objref,[],"Object"}],
            []};
oe_tc(rebind) -> 
	{tk_void,
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                     "NameComponent",
                     [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                 0},
             {tk_objref,[],"Object"}],
            []};
oe_tc(bind_context) -> 
	{tk_void,
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                     "NameComponent",
                     [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                 0},
             {tk_objref,"IDL:omg.org/CosNaming/NamingContext:1.0",
                 "NamingContext"}],
            []};
oe_tc(rebind_context) -> 
	{tk_void,
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                     "NameComponent",
                     [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                 0},
             {tk_objref,"IDL:omg.org/CosNaming/NamingContext:1.0",
                 "NamingContext"}],
            []};
oe_tc(resolve) -> 
	{{tk_objref,[],"Object"},
         [{tk_sequence,{tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                                  "NameComponent",
                                  [{"id",{tk_string,0}},
                                   {"kind",{tk_string,0}}]},
                       0}],
         []};
oe_tc(unbind) -> 
	{tk_void,
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                     "NameComponent",
                     [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                 0}],
            []};
oe_tc(new_context) -> 
	{{tk_objref,"IDL:omg.org/CosNaming/NamingContext:1.0","NamingContext"},
         [],[]};
oe_tc(bind_new_context) -> 
	{{tk_objref,"IDL:omg.org/CosNaming/NamingContext:1.0","NamingContext"},
         [{tk_sequence,{tk_struct,"IDL:omg.org/CosNaming/NameComponent:1.0",
                                  "NameComponent",
                                  [{"id",{tk_string,0}},
                                   {"kind",{tk_string,0}}]},
                       0}],
         []};
oe_tc(destroy) -> 
	{tk_void,[],[]};
oe_tc(list) -> 
	{tk_void,
            [tk_ulong],
            [{tk_sequence,
                 {tk_struct,"IDL:omg.org/CosNaming/Binding:1.0","Binding",
                     [{"binding_name",
                       {tk_sequence,
                           {tk_struct,
                               "IDL:omg.org/CosNaming/NameComponent:1.0",
                               "NameComponent",
                               [{"id",{tk_string,0}},{"kind",{tk_string,0}}]},
                           0}},
                      {"binding_type",
                       {tk_enum,"IDL:omg.org/CosNaming/BindingType:1.0",
                           "BindingType",
                           ["nobject","ncontext"]}}]},
                 0},
             {tk_objref,"IDL:omg.org/CosNaming/BindingIterator:1.0",
                 "BindingIterator"}]};
oe_tc(_) -> undefined.

oe_get_interface() -> 
	[{"list", oe_tc(list)},
	{"destroy", oe_tc(destroy)},
	{"bind_new_context", oe_tc(bind_new_context)},
	{"new_context", oe_tc(new_context)},
	{"unbind", oe_tc(unbind)},
	{"resolve", oe_tc(resolve)},
	{"rebind_context", oe_tc(rebind_context)},
	{"bind_context", oe_tc(bind_context)},
	{"rebind", oe_tc(rebind)},
	{"bind", oe_tc(bind)}].




%%------------------------------------------------------------
%%
%% Object server implementation.
%%
%%------------------------------------------------------------


%%------------------------------------------------------------
%%
%% Function for fetching the interface type ID.
%%
%%------------------------------------------------------------

typeID() ->
    "IDL:omg.org/CosNaming/NamingContext:1.0".


%%------------------------------------------------------------
%%
%% Object creation functions.
%%
%%------------------------------------------------------------

oe_create() ->
    corba:create(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0").

oe_create_link() ->
    corba:create_link(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0").

oe_create(Env) ->
    corba:create(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0", Env).

oe_create_link(Env) ->
    corba:create_link(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0", Env).

oe_create(Env, RegName) ->
    corba:create(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0", Env, RegName).

oe_create_link(Env, RegName) ->
    corba:create_link(?MODULE, "IDL:omg.org/CosNaming/NamingContext:1.0", Env, RegName).

%%------------------------------------------------------------
%%
%% Init & terminate functions.
%%
%%------------------------------------------------------------

init(Env) ->
%% Call to implementation init
    corba:handle_init('CosNaming_NamingContext_impl', Env).

terminate(Reason, State) ->
    corba:handle_terminate('CosNaming_NamingContext_impl', Reason, State).


%%%% Operation: bind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName, CosNaming::NamingContext::AlreadyBound
%%
handle_call({OE_THIS, OE_Context, bind, [N, Obj]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', bind, [N, Obj], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: rebind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
handle_call({OE_THIS, OE_Context, rebind, [N, Obj]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', rebind, [N, Obj], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: bind_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName, CosNaming::NamingContext::AlreadyBound
%%
handle_call({OE_THIS, OE_Context, bind_context, [N, Nc]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', bind_context, [N, Nc], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: rebind_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
handle_call({OE_THIS, OE_Context, rebind_context, [N, Nc]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', rebind_context, [N, Nc], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: resolve
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
handle_call({OE_THIS, OE_Context, resolve, [N]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', resolve, [N], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: unbind
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
handle_call({OE_THIS, OE_Context, unbind, [N]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', unbind, [N], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: new_context
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, new_context, []}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', new_context, [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: bind_new_context
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotFound, CosNaming::NamingContext::AlreadyBound, CosNaming::NamingContext::CannotProceed, CosNaming::NamingContext::InvalidName
%%
handle_call({OE_THIS, OE_Context, bind_new_context, [N]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', bind_new_context, [N], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: destroy
%% 
%%   Returns: RetVal
%%   Raises:  CosNaming::NamingContext::NotEmpty
%%
handle_call({OE_THIS, OE_Context, destroy, []}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', destroy, [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: list
%% 
%%   Returns: RetVal, Bl, Bi
%%
handle_call({OE_THIS, OE_Context, list, [How_many]}, _, OE_State) ->
  corba:handle_call('CosNaming_NamingContext_impl', list, [How_many], OE_State, OE_Context, OE_THIS, false);



%%%% Standard gen_server call handle
%%
handle_call(stop, _, State) ->
    {stop, normal, ok, State};

handle_call(_, _, State) ->
    {reply, catch corba:raise(#'BAD_OPERATION'{minor=1163001857, completion_status='COMPLETED_NO'}), State}.


%%%% Standard gen_server cast handle
%%
handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_, State) ->
    {noreply, State}.


%%%% Standard gen_server handles
%%
handle_info(_, State) ->
    {noreply, State}.


code_change(OldVsn, State, Extra) ->
    corba:handle_code_change('CosNaming_NamingContext_impl', OldVsn, State, Extra).

