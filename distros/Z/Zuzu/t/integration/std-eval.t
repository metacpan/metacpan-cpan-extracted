use Test2::V0;

use Zuzu qw( zuzu_eval );

my $test_lib = [ 'stdlib/test-modules', 'stdlib/modules' ];

is(
	zuzu_eval( <<'ZZS' ),
from std/eval import eval;
let x := 41;
eval("x += 1;");
x;
ZZS
	42,
	'std/eval can update caller scope symbols',
);

is(
	zuzu_eval( <<'ZZS' ),
from std/eval import eval;
function f () {
	let answer := 40;
	return eval("answer + 2;");
}
f();
ZZS
	42,
	'std/eval can read lexical symbols in function scope',
);

like(
	dies {
		zuzu_eval( <<'ZZS' );
from std/eval import eval;
eval("let x :=");
ZZS
	},
	qr/E_COMPILE_SYNTAX|Expected|syntax/i,
	'std/eval throws for invalid Zuzu code',
);

like(
	dies {
		zuzu_eval(
			<<'ZZS',
from std/eval import eval;
eval("from std/io import Path;");
ZZS
			{ deny => [ 'fs' ] },
		);
	},
	qr/Cannot find module 'std\/io' in lib paths/,
	'std/eval uses caller runtime policy when loading modules',
);

like(
	dies {
		zuzu_eval( <<'ZZS' );
from std/eval import eval;
eval("from std/io import Path;", deny_fs: true);
ZZS
	},
	qr/Cannot find module 'std\/io' in lib paths/,
	'std/eval can add deny_fs for nested evaluation',
);

like(
	dies {
		zuzu_eval( <<'ZZS' );
from std/eval import eval;
eval("from std/db import connect;", deny_db: true);
ZZS
	},
	qr/Cannot find module 'std\/db' in lib paths/,
	'std/eval can add deny_db for nested evaluation',
);

is(
	zuzu_eval( <<'ZZS' ),
from std/eval import eval;
eval("let y := __system__.get(\"deny_fs\");", deny_fs: true);
__system__.get("deny_fs");
ZZS
	0,
	'additional denials in eval do not mutate parent runtime policy',
);

is(
	zuzu_eval(
		<<'ZZS',
from std/eval import eval;
from std/math import Math;

let counter := 1;
eval("counter += 4;");

eval("let eval_local := 42;");
let let_hidden := false;
try {
	eval("eval_local;");
}
catch {
	let_hidden := true;
}

let collision_result := eval("from std/math import Math; Math.pi;");
let collision_ok := collision_result = Math.pi;

eval("from std/string import split;");
let import_hidden := false;
try {
	eval("split(\"a,b\", \",\");");
}
catch {
	import_hidden := true;
}

eval("function eval_helper () { return 9; }");
let function_hidden := false;
try {
	eval("eval_helper();");
}
catch {
	function_hidden := true;
}

eval("class EvalLocalThing;");
let class_hidden := false;
try {
	eval("new EvalLocalThing();");
}
catch {
	class_hidden := true;
}

"" _ counter
	_ ":" _ ( let_hidden ? "1" : "0" )
	_ ":" _ ( collision_ok ? "1" : "0" )
	_ ":" _ ( import_hidden ? "1" : "0" )
	_ ":" _ ( function_hidden ? "1" : "0" )
	_ ":" _ ( class_hidden ? "1" : "0" );
ZZS
		{ lib => $test_lib },
	),
	'5:1:1:1:1:1',
	'std/eval executes in a nested lexical scope',
);

is(
	zuzu_eval(
		<<'ZZS',
from std/eval import eval;
from test/eval_policy import eval_policy_require_fs;

let before := eval_policy_require_fs();
let clib_overlay := eval("__system__{deny_clib};", deny_clib: true);
let module_message := "";
try {
	eval("eval_policy_require_fs();", deny_fs: true);
}
catch ( Exception e ) {
	module_message := e{message};
}
let restored := eval_policy_require_fs();
let nested := eval(
	"eval(\"__system__{deny_fs};\", deny_fs: false);",
	deny_fs: true,
);

before
	_ ":" _ ( clib_overlay ? "1" : "0" )
	_ ":" _ module_message
	_ ":" _ restored
	_ ":" _ ( nested ? "1" : "0" )
	_ ":" _ ( __system__{deny_fs} ? "1" : "0" );
ZZS
		{ lib => $test_lib },
	),
	'fs-ok:1:TEST_EVAL_POLICY_FS_DENIED:fs-ok:1:0',
	'std/eval denial overlays are dynamic and restored',
);

like(
	zuzu_eval(
		<<'ZZS',
from std/eval import eval;

let syntax_message := "";
let syntax_file := "";
let syntax_line := 0;
let syntax_code := "";
try {
	eval("let := ;");
}
catch ( Exception e ) {
	syntax_message := e{message};
	syntax_file := e{file};
	syntax_line := e{line};
	syntax_code := e{code};
}

let type_name := "";
let type_message := "";
try {
	eval("let Number n := \"text\";");
}
catch ( TypeException e ) {
	type_name := typeof e;
	type_message := e{message};
}

let named_message := "";
try {
	eval( "true;", deny_unknown: true );
}
catch ( Exception e ) {
	named_message := e{message};
}

syntax_message
	_ "|" _ syntax_file
	_ "|" _ syntax_line
	_ "|" _ syntax_code
	_ "|" _ type_name
	_ "|" _ type_message
	_ "|" _ named_message;
ZZS
		{ lib => $test_lib },
	),
	qr/Expected IDENT\|<std\/eval>\|1\|E_COMPILE_SYNTAX\|TypeException\|TypeException: 'n' must be Number, got String\|Unknown named argument 'deny_unknown' for eval/,
	'std/eval errors are catchable with stable metadata',
);

done_testing;
