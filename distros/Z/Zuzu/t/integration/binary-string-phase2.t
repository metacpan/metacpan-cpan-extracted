use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;
use Zuzu::Value::BinaryString;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'binary-string-phase2.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), 1, 'typeof reports BinaryString and instanceof is disjoint';
let b := to_binary( "abc" );
( ( typeof b ) eq "BinaryString" )
	and ( b instanceof BinaryString )
	and ( not ( b instanceof String ) )
	and ( "abc" instanceof String )
	and ( not ( "abc" instanceof BinaryString ) );
SRC

is eval_src(<<'SRC'), 1, 'to_binary/to_string roundtrip utf8 text';
( to_string( to_binary( "héllo" ) ) eq "héllo" );
SRC

is eval_src(<<'SRC'), 1, 'ASCII BinaryString can implicitly concatenate with String';
let b := to_binary( "abc" );
( ( b _ "def" ) eq "abcdef" )
	and ( ( ">>" _ b ) eq ">>abc" );
SRC

is eval_src(<<'SRC'), 4, 'length on BinaryString uses byte length';
length to_binary( "éé" );
SRC

is eval_src(<<'SRC'), 1, 'single-quoted literals parse as BinaryString';
let b := 'abc';
( ( typeof b ) eq "BinaryString" )
	and ( to_string(b) eq "abc" );
SRC

is eval_src(<<'SRC'), 1, 'single-quoted binary escapes decode as bytes';
let b := '\x41\n\\\'';
to_string(b) eq "A\n\\'";
SRC

like dies {
	eval_src(<<'SRC');
uc to_binary( "abc" );
SRC
}, qr/TypeException: uc expects String, got BinaryString/,
	'uc rejects BinaryString';

like dies {
	eval_src(<<'SRC');
lc to_binary( "abc" );
SRC
}, qr/TypeException: lc expects String, got BinaryString/,
	'lc rejects BinaryString';

like dies {
	eval_src(<<'SRC');
let b := to_binary( "é" );
b _ "x";
SRC
}, qr/Cannot implicitly concatenate non-ASCII BinaryString/,
	'non-ASCII BinaryString cannot implicitly concatenate with String';

like dies {
	eval_src(<<'SRC');
function takes_text ( String s ) {
	return s;
}
takes_text( to_binary( "abc" ) );
SRC
}, qr/TypeException: 's' must be String, got BinaryString/,
	'String parameter rejects BinaryString';

like dies {
	eval_src(<<'SRC');
function takes_binary ( BinaryString b ) {
	return b;
}
takes_binary( "abc" );
SRC
}, qr/TypeException: 'b' must be BinaryString, got String/,
	'BinaryString parameter rejects String';

like dies {
	my $runtime = Zuzu::Runtime->new;
	$runtime->call( 'to_string', Zuzu::Value::BinaryString->new( bytes => "\xFF" ) );
}, qr/UTF-8/,
	'to_string throws decode error for invalid UTF-8 bytes';

done_testing;
