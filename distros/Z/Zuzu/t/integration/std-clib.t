use Test2::V0;

use File::Spec;

use Zuzu::Parser;
use Zuzu::Runtime;

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my @runtime_lib = (
	File::Spec->catdir( $repo_root, 'stdlib', 'test-modules' ),
	File::Spec->catdir( $repo_root, 'stdlib', 'modules' ),
);
my $parser = Zuzu::Parser->new;

sub evaluate_source {
	my ( $source ) = @_;

	my $runtime = Zuzu::Runtime->new( lib => \@runtime_lib );
	my $ast = $parser->parse( $source, 'std-clib-integration.zzs' );
	$runtime->evaluate($ast);

	return $runtime;
}

sub source_dies_like {
	my ( $pattern, $name, $source ) = @_;

	like dies {
		evaluate_source($source);
	}, $pattern, $name;

	return;
}

ok evaluate_source(<<'SRC'), 'double close is harmless';
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
lib.close();
lib.close();
SRC

source_dies_like(
	qr/closed CLibrary/,
	'closing library invalidates existing functions',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
let greet := lib.func(
	"greet",
	[],
	{
		type: "binary",
		terminated_by: "nul",
		free: "greet_free"
	},
);
lib.close();
greet.call();
SRC
);

source_dies_like(
	qr/CLibrary is closed/,
	'closed library rejects symbol lookup',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
lib.close();
lib.has_symbol("greet");
SRC
);

source_dies_like(
	qr/Could not bind C function 'not_a_symbol'/,
	'missing C symbol reports a binding error',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
lib.func("not_a_symbol", [], "null");
SRC
);

source_dies_like(
	qr/parameter 0 int descriptor only supports bits=64/,
	'unsupported descriptor reports a validation error',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
lib.func("greet_add_i64", [ { type: "int", bits: 32 } ], "null");
SRC
);

source_dies_like(
	qr/Function 'greet' expects 0 arguments, got 1/,
	'arity errors are caught before the native call',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
let greet := lib.func(
	"greet",
	[],
	{
		type: "binary",
		terminated_by: "nul",
		free: "greet_free"
	},
);
greet.call(1);
SRC
);

source_dies_like(
	qr/argument 0 must be Boolean, got Number/,
	'argument type errors are caught before the native call',
	<<'SRC',
from std/clib import CLib;

let lib := CLib.open("t/fixtures/example_clib/libgreet.so");
let bool_not := lib.func("greet_not", [ "bool" ], "bool");
bool_not.call(1);
SRC
);

done_testing;
