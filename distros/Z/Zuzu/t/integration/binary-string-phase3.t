use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'binary-string-phase3.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), 1, 'BinaryString index returns one-byte BinaryString with negative index support';
let b := to_binary( "abcd" );
( ( typeof b[1] ) eq "BinaryString" )
	and ( to_string( b[1] ) eq "b" )
	and ( to_string( b[-1] ) eq "d" );
SRC

is eval_src(<<'SRC'), 1, 'BinaryString slice supports start/length and negative starts';
let b := to_binary( "abcd" );
( to_string( b[1:2] ) eq "bc" )
	and ( to_string( b[-2:] ) eq "cd" )
	and ( to_string( b[1:0] ) eq "" );
SRC

is eval_src(<<'SRC'), 1, 'numeric bitwise operators and precedence are supported';
( ( 1 | 2 & 4 ) = 1 )
	and ( ( ( ~5 ) & 7 ) = 2 )
	and ( ( ( 1 | 2 ) & 4 ) = 0 )
	and ( ( 6 ^ 3 ) = 5 );
SRC

is eval_src(<<'SRC'), 1, 'binary bytewise operators produce BinaryString values';
let left := to_binary( "AB" );
let right := to_binary( "a~" );
( ( typeof ( left & right ) ) eq "BinaryString" )
	and ( to_string( left & right ) eq "AB" )
	and ( to_string( left | right ) eq "a~" )
	and ( to_string( left ^ right ) eq " <" )
	and ( ( ~~left ) == left );
SRC

is eval_src(<<'SRC'), 1, 'infix regex match still works with unary ~ added';
let m := ( "abc123" ~ /([0-9]+)/ );
( m[0] eq "123" ) and ( m[1] eq "123" );
SRC

like dies {
	eval_src(<<'SRC');
to_binary( "abc" ) & to_binary( "xy" );
SRC
}, qr/requires equal byte lengths/,
	'BinaryString bitwise rejects unequal lengths';

like dies {
	eval_src(<<'SRC');
to_binary( "ab" ) | 3;
SRC
}, qr/TypeException: BinaryString bitwise '\|' expects BinaryString operands on both sides/,
	'BinaryString bitwise rejects mixed BinaryString/Number operands';

like dies {
	eval_src(<<'SRC');
"abc"[0];
SRC
}, qr/Indexing expects Array or BinaryString/,
	'indexing non-Array and non-BinaryString still throws clear error';


done_testing;
