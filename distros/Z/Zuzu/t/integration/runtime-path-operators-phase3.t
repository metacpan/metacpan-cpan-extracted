use Test2::V0;
use File::Spec;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( '.', 'stdlib', 'modules' ) ],
	);
	my $ast = $parser->parse( $src, 'runtime-path-operators-phase3.zzs' );
	return $runtime->evaluate($ast);
}

is(
	eval_src('let src := { users: [ { name: "Ada" }, { name: "Bob" } ] }; src @ "/users/#0/name";'),
	'Ada',
	'@ resolves first match from string path via default ZPath class',
);

is(
	eval_src('let src := { users: [ { name: "Ada" }, { name: "Bob" } ] }; src @@ "/users/*/name";'),
	object {
		call items => array {
			item 'Ada';
			item 'Bob';
			end;
		};
	},
	'@@ returns all matches via path traversal',
);

is(
	eval_src('let src := { users: [ { name: "Ada" } ] }; src @? "/users/#5/name";'),
	0,
	'@? returns false for missing path',
);

is(
	eval_src('from std/internals import setprop; from std/path/z import ZPath; setprop( "paths", ZPath ); let src := { users: [ { name: "Ada" } ] }; src @ "/users/#0/name";'),
	'Ada',
	'paths special property can override class lexically',
);

like(
	dies { eval_src('let src := { x: 1 }; src @ 42;') },
	qr/path operand must be String or Object/,
	'non-string, non-object path operands throw type error',
);

like(
	dies { eval_src('from std/internals import setprop; setprop( "paths", 42 ); let src := { users: [ { name: "Ada" } ] }; src @ "/users/#0/name";') },
	qr/paths special property must be Class or null/,
	'paths special property enforces Class-or-null contract',
);

done_testing;
