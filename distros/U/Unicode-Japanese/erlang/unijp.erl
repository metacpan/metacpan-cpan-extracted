-module(unijp).
-export([ start/0 ]).
-export([ stop/0  ]).
-export([ stop/1  ]).

-export([version_string/0]).
-export([version_tuple/0]).
-export([conv_binary/3]).

-export([version_str/0]). % compat for 0.0.49.
-export([conv/3]).        % compat for 0.0.49.

-export_type([charcode/0]).

-type charcode() :: atom().

-spec start() -> pid().
start() ->
	case whereis(unijp) of
		undefined ->
			start_2();
		Pid ->
			Pid
	end.

start_2() ->
	Self = self(),
	Ref = make_ref(),
	Pid = proc_lib:spawn(fun() -> server_init(Self, Ref) end ),
	receive
		Ref ->
			Pid;
		{Ref, {error, Reason}} ->
			error({unijp_start, Reason})
	after 10*1000 ->
		error({unijp_start, timeout})
	end.

-spec stop() -> ok.
stop() ->
	case whereis(unijp) of
		undefined ->
			ok;
		Pid ->
			stop(Pid)
	end.

-spec stop(pid()) -> ok.
stop(Pid) ->
	Pid ! { self(), close },
	Ref = erlang:monitor(process, Pid),
	receive
		ok ->
			receive
				{'DOWN', Ref, process, Pid, normal} ->
					ok;
				{'DOWN', Ref, process, Pid, Info} ->
					error_logger:error_msg("unijp:stop received abnomal exit: ~p~n", [Info]),
					ok
			after 1000 ->
				exit(noreply)
			end
	after 10000 ->
		exit(noreply)
	end.


-spec version_string() -> string().
version_string() ->
	unijp_nif:version_string().

-spec version_tuple() -> {non_neg_integer(), non_neg_integer(), non_neg_integer()}.
version_tuple() ->
	unijp_nif:version_tuple().

-spec conv(charcode() | iodata(), charcode() | iodata(), iodata()) -> string().
conv(From, To, Text) ->
	conv_compat(From, To, Text).

conv_compat(From, To, Text) ->
	From_2 = if
		is_atom(From) ->
			From;
		true ->
			unijp_nif:decode_charcode(iolist_to_binary(From))
	end,
	To_2 = if
		is_atom(To) ->
			To;
		true ->
			unijp_nif:decode_charcode(iolist_to_binary(To))
	end,
	Text_2 = iolist_to_binary(Text),
	Bin = unijp_nif:conv(From_2, To_2, Text_2),
	binary_to_list(Bin).

-spec conv_binary(charcode(), charcode(), binary()) -> binary().
conv_binary(From, To, Text) ->
	unijp_nif:conv(From, To, Text).

% compat for 0.0.49.
-spec version_str() -> string().
version_str() ->
	unijp_nif:version_string().


server_init(FromPid, Ref) ->
	try
		register(unijp, self()),
		{module, unijp_nif} = code:ensure_loaded(unijp_nif),
		FromPid ! Ref,
		ok
	of
		ok ->
			server_loop()
	catch
		Class:Reason ->
			StackTrace = erlang:get_stacktrace(),
			error_logger:error_msg("unijp:server_init aborted ~p:~p~n ~p~n", [Class, Reason, StackTrace]),
			FromPid ! {Ref, {error, {Class, Reason, StackTrace}}}
	end.

server_loop() ->
	try
		server_loop_2()
	catch
		Class:Reason ->
			StackTrace = erlang:get_stacktrace(),
			error_logger:error_msg("unijp:server_loop aborted ~p:~p~n ~p~n", [Class, Reason, StackTrace])
	end.

server_loop_2() ->
	receive
		{FromPid, close} ->
			FromPid ! ok,
			ok;
		X ->
			error_logger:error_msg("unijp:server_loop received ~p~n", [X]),
			server_loop_2()
	end.
