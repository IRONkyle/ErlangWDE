%% ``The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved via the world wide web at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% The Initial Developer of the Original Code is Ericsson Utvecklings AB.
%% Portions created by Ericsson are Copyright 1999, Ericsson Utvecklings
%% AB. All Rights Reserved.''
%% 
%%     $Id$
%%
%% Author: Lennart �hman, lennart.ohman@st.se
%%
%% INVISO LogFile Merger.
%%
%% Merges all log-entries in all files in Files in chronological order
%% into what ever is handled by WorkHandlerFun. Note that Files can contain
%% several files. Both in the sence that it can be a wrapset. But also because
%% the log is spread over more than one LogFiles (i.e trace_log + ti_log).
%% It is further possible to use another reader-process (for the logfiles)
%% than the default one. This is useful if the logfiles are formatted in
%% another way than as done by a trace-port.

-module(inviso_lfm).

%% -----------------------------------------------------------------------------
%% API exports.
%% -----------------------------------------------------------------------------

-export([merge/2,merge/3,merge/4,merge/5,merge/6]).
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------------------
%% Default handler exports.
%% -----------------------------------------------------------------------------

-export([outfile_opener/1,outfile_writer/4,outfile_closer/1]).
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------------------
%% Formatting functions.
%% -----------------------------------------------------------------------------

-export([format_arguments/3,format_argument_string/2]).
%% -----------------------------------------------------------------------------
%% Internal exports.
%% -----------------------------------------------------------------------------

-export([init_receiver/7]).
%% -----------------------------------------------------------------------------

%% merge(Files,BeginHandlerFun,WorkHandlerFun,EndHandlerFun,HandlerData)=
%%   {ok,Count} | {error,Reason}
%% merge(Files,OutputFile) =
%%
%%   Files=[FileDescription,...]
%%   FileDescription=FileSet | {reader,Mod,Func,FileSet}
%%   FileSet={Node,LogFiles} | {Node,[LogFiles,...]}
%%     in the latter case the LogFiles must be sorted, beginning with the oldest.
%%   LogFiles=[{trace_log,Files} [,{ti_log,[FileName]}] ]
%%       either just trace_log or trace_log and ti_log.
%%     Files=[FileName] | [FileName,...]
%%       in the latter case it is a wrapset.
%%   BeginHandlerFun= ( fun(HandlerData)->{ok,NewHandleData} | {error,Reason} )
%%   WorkHandlerFun= ( fun(Node,Term,PidMappings,HandlerData)->
%%     {ok,NewHandlerData} | {error,Reason}
%%   EndHandlerFun= ( fun(HandlerData)->ok | {error,Reason} )
%%   Count=integer(), the total number of handled log entries.
%%
%% Merges all logfiles in Files together into one common log file, in chronological
%% order according to the time-stamps in each log. Each entry is also marked with
%% the node name in the merged log.
%% Configuration:
%% If a non-default reader shall be used, Mod:Func(ReceiverPid,LogFiles) shall
%%   spawn a reader process complying to the receiver/reader message protocoll.
%%   The default reader reads logs generated by a trace-port.
%% BeginHandler is called before any logentries are processed, typically to open
%%   the out-file, if any.
%% WorkHandlerFun is called for every log-entry. It typically writes the output.
%% EndHandlerFun is called when the last reader has finished, typically to
%%   close the outfile.
%%
%% Using merge/2 assumes you want to use default handlers writing to a file.
merge(Files,OutputFile) when is_list(OutputFile) ->
    merge(Files,fun outfile_opener/1,fun outfile_writer/4,fun outfile_closer/1,OutputFile,off).
merge(Files,WorkHandlerFun,HandlerData) when is_function(WorkHandlerFun) ->
    merge(Files,void,WorkHandlerFun,void,HandlerData,off);
merge(Files,OutputFile,Dbg) when is_list(OutputFile) ->
    merge(Files,fun outfile_opener/1,fun outfile_writer/4,fun outfile_closer/1,OutputFile,Dbg).
merge(Files,WorkHandlerFun,HandlerData,Dbg) when is_function(WorkHandlerFun) ->
    merge(Files,void,WorkHandlerFun,void,HandlerData,Dbg).
merge(Files,BeginHandlerFun,WorkHandlerFun,EndHandlerFun,HandlerData) ->
    merge(Files,BeginHandlerFun,WorkHandlerFun,EndHandlerFun,HandlerData,off).
merge(Files,BeginHandlerFun,WorkHandlerFun,EndHandlerFun,HandlerData,Dbg) ->
    ReceiverPid=spawn_link(?MODULE,
			   init_receiver,
			   [self(),Files,BeginHandlerFun,WorkHandlerFun,
			    EndHandlerFun,HandlerData,Dbg]),
    wait_for_response(ReceiverPid).

wait_for_response(ReceiverPid) ->
    receive
	{reply,ReceiverPid,Reply} ->
	    Reply;
	{'EXIT',ReceiverPid,Reason} ->
	    {error,Reason}
    end.
%% -----------------------------------------------------------------------------

%% =============================================================================
%% Code for the receiver process.
%% =============================================================================

%% Initial function for the receiver process. This function must be exported.
init_receiver(From,Files,BeginHandlerFun,WorkHandlerFun,EndHandlerFun,HandlerData,Dbg) ->
    case setup_readers(Files) of            % Create the reader processes.
	{ok,Readers} ->
	    process_flag(trap_exit,true),
	    if
		is_function(BeginHandlerFun) ->
		    case catch BeginHandlerFun(HandlerData) of
			{ok,NewHandlerData} ->
			    init_receiver_2(From,WorkHandlerFun,EndHandlerFun,
					    NewHandlerData,Dbg,Readers);
			{error,Reason} ->   % Faulty begin-function.
			    From ! {reply,self(),{error,{begin_handler,Reason}}};
			{'EXIT',Reason} ->
			    From ! {reply,self(),{error,{begin_handler,Reason}}}
		    end;
		true ->                     % There is no begin-handler.
		    init_receiver_2(From,WorkHandlerFun,EndHandlerFun,HandlerData,Dbg,Readers)
	    end;
	{error,Reason} ->
	    From ! {reply,self(),{error,{files,Reason}}}
    end.

init_receiver_2(From,WorkHandlerFun,EndHandlerFun,HandlerData,Dbg,Readers) ->
    {NewReaders,EntryStruct}=mk_entrystruct(Readers,Dbg),
    {Reply,NewHandlerData}=
	loop(From,WorkHandlerFun,HandlerData,NewReaders,EntryStruct,Dbg,0),
    if
	is_function(EndHandlerFun) ->
	    case EndHandlerFun(NewHandlerData) of
		ok ->
		    From ! {reply,self(),Reply};
		{error,_Reason} ->
		    From ! {reply,self(),Reply}
	    end;
	true ->                             % Reply directly then, no finish fun.
	    From ! {reply,self(),Reply}
    end.

%% Function that spawns a help process for each group of files in the list.
%% The help process will read entries from the input files in the correct order
%% and deliver them to the receiver process.
%% Note that there is a possibility to design your own readers. The default
%% reader understands trace-port generated logfiles.
%% Returns a list of {Node,Pid}.
setup_readers(Files) ->
    setup_readers_2(Files,[]).

setup_readers_2([{reader,Mod,Func,{Node,FileStruct}}|Rest],Acc) ->
    Pid=spawn_link(Mod,Func,[self(),FileStruct]),
    setup_readers_2(Rest,[{Node,Pid}|Acc]);
setup_readers_2([{Node,FileStruct}|Rest],Acc) ->
    Pid=spawn_link(inviso_lfm_tpfreader,init,[self(),FileStruct]),
    setup_readers_2(Rest,[{Node,Pid}|Acc]);
setup_readers_2([],Acc) ->
    {ok,Acc};
setup_readers_2([Faulty|_],_Acc) ->
    {error,{bad_reader_spec,Faulty}}.
%% -----------------------------------------------------------------------------

%% This is the workloop that polls each reader for messages and writes them
%% in the correct order.
loop(From,WorkHFun,HData,Readers,EntryStruct,Dbg,Count) ->
    case find_oldest_entry(EntryStruct) of
	{Pid,Node,PidMappings,Term} ->
	    case get_and_insert_new_entry(From,Node,Pid,Readers,EntryStruct,Dbg) of
		{ok,{NewReaders,NewEntryStruct}} ->
		    case WorkHFun(Node,Term,PidMappings,HData) of
			{ok,NewHData} ->
			    loop(From,WorkHFun,NewHData,NewReaders,NewEntryStruct,Dbg,Count+1);
			{error,Reason} ->   % Serious, we cant go on then.
			    stop_readers(NewReaders),
			    {{error,{writing_output_file,Reason}},HData}
		    end;
		{stop,_Reason} ->           % The original caller is no longer there!
		    stop_readers(Readers),
		    {error,HData}
	    end;
	done ->                             % No more readers.
	    {{ok,Count},HData}
    end.

%% Help function which finds the oldest entry in the EntryStruct. Note that the
%% timestamp can actually be the atom 'false'. This happens for instance if it is
%% a dropped-messages term. But since 'false' is smaller than any tuple, that
%% term will be consumed immediately as soon as it turns up in EntryList.
find_oldest_entry(EntryStruct) ->
    case list_all_entries(EntryStruct) of
	[] ->                               % The we are done!
	    done;
	EntryList when is_list(EntryList) ->   % Find smallest timestamp in here then.
	    {Pid,Node,PidMappings,_TS,Term}=
		lists:foldl(fun({P,N,PMap,TS1,T},{_P,_N,_PMap,TS0,_T}) when TS1<TS0 ->
				    {P,N,PMap,TS1,T};
			       (_,Acc) ->
				    Acc
			    end,
			    hd(EntryList),
			    EntryList),
	    {Pid,Node,PidMappings,Term}
    end.

%% Help function which signals all reader process to clean-up and terminate.
%% Returns nothing significant.
stop_readers([Pid|Rest]) ->
    Pid ! {stop,self()},
    stop_readers(Rest);
stop_readers([]) ->
    ok.
%% -----------------------------------------------------------------------------

%% Help function which tries to replace the entry by Pid in EntryStruct with
%% a new one from that process. If one is returned on request, it replaces
%% the old one in EntryStruct. If Pid is done or otherwise dissapears, Pid
%% is simply removed from Readers and the EntryStruct.
get_and_insert_new_entry(Node,Pid,Readers,EntryStruct,Dbg) ->
    get_and_insert_new_entry(void,Node,Pid,Readers,EntryStruct,Dbg).

get_and_insert_new_entry(From,Node,Pid,Readers,EntryStruct,Dbg) ->
    Pid ! {get_next_entry,self()},
    receive
	{'EXIT',From,Reason} ->              % No one is waiting for our reply!
	    {stop,Reason};                   % No use continuing then.
	{next_entry,Pid,PidMappings,TS,Term} -> % We got a next entry from Pid!
	    ets:insert(EntryStruct,{Pid,Node,PidMappings,TS,Term}),
	    {ok,{Readers,EntryStruct}};
	{next_entry,Pid,{error,_Reason}} ->  % Reading an entry went wrong.
	    get_and_insert_new_entry(From,Node,Pid,Readers,EntryStruct,Dbg);
	{'EXIT',Pid,_Reason} ->              % The process has terminated.
	    ets:delete(EntryStruct,Pid),
	    NewReaders=lists:delete(Pid,Readers),
	    {ok,{NewReaders,EntryStruct}}
    end.
%% -----------------------------------------------------------------------------

%% Help function which from a list of reader processes creates the private
%% storage where the oldest entry from each reader is always kept.
%% Returns {Readers,EntryStruct}.
mk_entrystruct(Pids,Dbg) ->
    TId=ets:new(list_to_atom("inviso_lfm_tab_"++pid_to_list(self())),[set]),
    mk_entrystruct_2(Pids,lists:map(fun({_,P})->P end,Pids),Dbg,TId).

mk_entrystruct_2([{Node,Pid}|Rest],Readers,Dbg,EntryStruct) ->
    {ok,{NewReaders,NewEntryStruct}}=
	get_and_insert_new_entry(Node,Pid,Readers,EntryStruct,Dbg),
    mk_entrystruct_2(Rest,NewReaders,Dbg,NewEntryStruct);
mk_entrystruct_2([],Readers,_Dbg,EntryStruct) ->
    {Readers,EntryStruct}.
%% -----------------------------------------------------------------------------

%% Help function that returns a list of our oldest entry structure.
%% [{Pid,Node,PidMappings,TimeStamp,Term},...]
list_all_entries(EntryStruct) ->
    ets:tab2list(EntryStruct).
%% -----------------------------------------------------------------------------

%% =============================================================================
%% Default handlers for the receiver
%% =============================================================================

%% These functions are also exported in order to make them available when creating
%% other funs in other modules.

%% Default begin-handler.
outfile_opener(FileName) ->
    case file:open(FileName,[write]) of
	{ok,FD} ->
	    {ok,FD};                          % Let the descriptor be handlerdata.
	{error,Reason} ->
	    {error,{open,Reason}}
    end.

%% Default work-handler.
%% DEN H�R �R L�NGT IFR�N F�RDIG!!!
outfile_writer(Node,Term,PidMappings,FD) ->
    io:format(FD,"~w ~w ~w~n",[Node,PidMappings,Term]),
    {ok,FD}.

%% Default end-handler.
outfile_closer(FD) ->
    file:close(FD),
    ok.
%% -----------------------------------------------------------------------------

%% =============================================================================
%% Formatting functions.
%% =============================================================================

%% This section contains a useful formatting function formatting an (function)
%% argument list. It also offers a working example of how to write
%% own datatype translators (which will be used by the formatting function to
%% further enhance the output).

%% format_arguments(Args,FOpts,Transaltors)=Args2 | <failure>
%%   Args=list(), list of the argument as usually given in a trace message,
%%     a stack trace or similar.
%%   FOpts=term(), formatting options understood by the translation functions.
%%   Translations=[Translator,...]
%%     Translator=fun(Term,FOpts)=TResult | {M,F}, where M:F(Term,FOpts)=TResult
%%       TResult={ok,TranslationString} | false
%%   Arg2=list(), list of Args where terms may be replaced by own representations.
%%     Note that terms not effected will remain as is, but if an own representation
%%     is choosen, that must be a string in order for any io format function to
%%     print it exactly as formatted here.
format_arguments([Arg|Rest],FOpts,Translators) -> % More than one argument.
    [format_argument(Arg,FOpts,Translators)|format_arguments(Rest,FOpts,Translators)];
format_arguments([],_FOpts,_Translators) ->
    [].                                     % The empty list.

%% Help function handling the various Erlang datatypes. There must hence be one
%% clause here for every existing datatype.
format_argument(List,FOpts,Translators) when is_list(List) ->
    case format_argument_own_datatype(List,FOpts,Translators) of
	{true,TranslationStr} ->
	    TranslationStr;
	false ->
	    format_argument_list(List,FOpts,Translators)
    end;
format_argument(Tuple,FOpts,Translators) when is_tuple(Tuple) ->
    case format_argument_own_datatype(Tuple,FOpts,Translators) of
	{true,TranslationStr} ->            % It was one of our special datatypes.
	    TranslationStr;
	false ->                            % Regular tuple.
	    format_argument_tuple(Tuple,FOpts,Translators)
    end;
format_argument(Binary,FOpts,Translators) when is_binary(Binary) ->
    case format_argument_own_datatype(Binary,FOpts,Translators) of
	{true,TranslationStr} ->            % It was one of our special datatypes..
	    TranslationStr;
	false ->                            % Regular binary.
	    format_argument_binary(Binary,FOpts,Translators)
    end;
format_argument(Atom,_FOpts,_Translators) when is_atom(Atom) ->
    Atom;
format_argument(Integer,_FOpts,_Translators) when is_integer(Integer) ->
    Integer;
format_argument(Float,_FOpts,_Translators) when is_float(Float) ->
    Float;
format_argument(Pid,_FOpts,_Translators) when is_pid(Pid) ->
    Pid;
format_argument(Port,_FOpts,_Translators) when is_port(Port) ->
    Port;
format_argument(Ref,_FOpts,_Translators) when is_reference(Ref) ->
    Ref;
format_argument(Fun,_FOpts,_Translators) when is_function(Fun) ->
    Fun.

%% Help function handling the case when an element is a list.
format_argument_list([Element|Rest],FOpts,Translators) ->
    [format_argument(Element,FOpts,Translators)|
     format_argument_list(Rest,FOpts,Translators)];
format_argument_list([],_FOpts,_Translators) ->
    [].

%% Help function handling the case when an element is a tuple.
format_argument_tuple(Tuple,FOpts,Translators) ->
    list_to_tuple(format_argument_tuple(Tuple,FOpts,Translators,size(Tuple),[])).

format_argument_tuple(_,_,_,0,List) ->
    List;
format_argument_tuple(Tuple,FOpts,Translators,Index,List) ->
    E=format_argument(element(Index,Tuple),FOpts,Translators),
    format_argument_tuple(Tuple,FOpts,Translators,Index-1,[E|List]).

%% Help function handling the case when an element is a binary.
format_argument_binary(Binary,_FOpts,_Translators) ->
    Binary.

%% Help function trying to use the translations.
format_argument_own_datatype(Term,FOpts,[Fun|Rest]) when is_function(Fun) ->
    case catch Fun(Term,FOpts) of
	{ok,TranslationStr} ->
	    {true,TranslationStr};
	_ ->
	    format_argument_own_datatype(Term,FOpts,Rest)
    end;
format_argument_own_datatype(Term,FOpts,[{M,F}|Rest]) ->
    case catch M:F(Term,FOpts) of
	{ok,TranslationStr} ->
	    {true,TranslationStr};
	_ ->
	    format_argument_own_datatype(Term,FOpts,Rest)
    end;
format_argument_own_datatype(Term,FOpts,[_|Rest]) ->
    format_argument_own_datatype(Term,FOpts,Rest);
format_argument_own_datatype(_Term,_FOpts,[]) -> % There is no applicable format.
    false.
%% -----------------------------------------------------------------------------

%% format_argument_string(String,_FOpts)={ok,QuotedString} | false
%%   String=string() | term()
%%   QuotedString="String"
%% Example of datatype checker that checks, in this case, that its argument is
%% a string. If it is, it returns a deep list of the characters to print in order
%% to make it a quoted string.
format_argument_string(List=[_|_],_FOpts) -> % Must be at least one element.
    case format_argument_string_2(List) of
	true ->
	    {ok,[$",List,$"]};
	false ->
	    false
    end;
format_argument_string(_,_FOpts) ->
    false.

format_argument_string_2([C|Rest]) when (((C<127) and (C>=32)) or ((C>=8) and (C=<13))) ->
    format_argument_string_2(Rest);
format_argument_string_2([_|_]) ->
    false;
format_argument_string_2([]) ->
    true.
%% -----------------------------------------------------------------------------
