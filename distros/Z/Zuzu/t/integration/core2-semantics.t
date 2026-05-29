use Test2::V0;

use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'core2-semantics.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'numeric coercion converts null/boolean/string';
( ( null + 2 ) = 2 )
	and ( ( true + 2 ) = 3 )
	and ( ( false + 2 ) = 2 )
	and ( ( "40" + 2 ) = 42 );
SRC

is eval_src(<<'SRC'), 1, 'string coercion converts null and booleans explicitly';
( ( null _ "x" ) eq "x" )
	and ( ( true _ "" ) eq "true" )
	and ( ( false _ "" ) eq "false" );
SRC

is eval_src(<<'SRC'), 1, 'truthiness for scalars and composites is stable';
( ( null ? 1 : 0 ) = 0 )
	and ( ( "" ? 1 : 0 ) = 0 )
	and ( ( "0" ? 1 : 0 ) = 1 )
	and ( ( 0 ? 1 : 0 ) = 0 )
	and ( ( [] ? 1 : 0 ) = 0 )
	and ( ( {} ? 1 : 0 ) = 0 )
	and ( ( << >> ? 1 : 0 ) = 0 )
	and ( ( <<< >>> ? 1 : 0 ) = 0 )
	and ( ( {{}} ? 1 : 0 ) = 0 )
	and ( ( [ 1 ] ? 1 : 0 ) = 1 );
SRC

is eval_src(<<'SRC'), 1, 'equality is type-aware for scalars and deep for collections';
( ( 1 == "1" ) = 0 )
	and ( ( 2 != "3" ) = 1 )
	and ( [ 1, 2 ] == [ 1, 2 ] )
	and ( << 1, 2 >> == << 2, 1 >> )
	and ( { a: 1, b: 2 } == { b: 2, a: 1 } )
	and ( <<< 1, 2 >>> == <<< 2, 1 >>> );
SRC

is eval_src(<<'SRC'), 6, 'for-loop over set visits each unique member without order guarantees';
let total := 0;
for ( let v in << 3, 1, 2 >> ) {
	total += v;
}
total;
SRC

is eval_src(<<'SRC'), 105, 'for-loop const variable is block scoped and does not leak';
let item := 100;
let total := 0;
for ( const item in [ 2, 3 ] ) {
	total += item;
}
item + total;
SRC

my $tmp = tempdir( CLEANUP => 1 );
my $mod_dir = File::Spec->catdir( $tmp, 'lib', 'check' );
make_path( $mod_dir );

open my $fh, '>:encoding(UTF-8)', File::Spec->catfile( $mod_dir, 'exports.zzm' )
	or die "Cannot write test module: $!";
print {$fh} <<'SRC';
let value := 11;
function get_value () {
	return value;
}
SRC
close $fh;

my $runtime = Zuzu::Runtime->new( lib => [ File::Spec->catdir( $tmp, 'lib' ) ] );
my $ast = $parser->parse( <<'SRC', 'import-conflict.zzs' );
let value := 99;
from check/exports import *;
SRC

like dies { $runtime->evaluate($ast) },
	qr/Import conflict: 'value' is already declared in this scope/,
	'import fails when imported name conflicts with local scope binding';

done_testing;
