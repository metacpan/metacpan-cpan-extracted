-module(unijp_nif).
-export([ decode_charcode/1 ]).
-export([ version_string/0  ]).
-export([ version_tuple/0   ]).
-export([ conv/3 ]).

-on_load( load_nif_module/0 ).

-define(PACKAGE, unijp).

-spec load_nif_module() -> ok | {error, { bad_lib
                                        | load
                                        | load_failed
                                        | old_code
                                        | reload
                                        | upgrade, string()}}.
load_nif_module() ->
	LibDir = nif_dir(),
	Path = filename:join([LibDir, "unijp_nif"]),
	erlang:load_nif(Path, none).

nif_dir() ->
	case os:getenv("UNIJP_INPLACE_NIF_MODULE_DIR") of
		false ->
			PrivDir = code:priv_dir(?PACKAGE),
			filename:join([PrivDir, "lib"]);
		Dir ->
			Dir
	end.

version_string() ->
	erlang:nif_error("unijp_nif not loaded", []).

version_tuple() ->
	erlang:nif_error("unijp_nif not loaded", []).

conv(From, To, Text) ->
	erlang:nif_error("unijp_nif not loaded", [From, To, Text]).

decode_charcode(Name) ->
	erlang:nif_error("unijp_nif not loaded", [Name]).
