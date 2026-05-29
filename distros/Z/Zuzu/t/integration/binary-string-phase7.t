use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'binary-string-phase7.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), 1, 'compatibility: BinaryString type boundaries remain disjoint';
let payload := to_binary( "abc" );
( payload instanceof BinaryString )
	and not ( payload instanceof String )
	and ( "abc" instanceof String )
	and not ( "abc" instanceof BinaryString );
SRC

like dies {
	eval_src(<<'SRC');
function takes_text ( String text ) {
	return text;
}
takes_text( to_binary( "abc" ) );
SRC
}, qr/TypeException: 'text' must be String, got BinaryString/,
	'compatibility: String parameter rejects BinaryString';

is eval_src(<<'SRC'), 1, 'rollout strict concat mode keeps explicit conversion path';
let binary := to_binary( "A" );
( ( "prefix" _ to_string(binary) ) eq "prefixA" );
SRC

like dies {
	eval_src(<<'SRC');
let binary := ~to_binary( "A" );
let bad_concat := "prefix" _ binary;
SRC
}, qr/Cannot implicitly concatenate non-ASCII BinaryString/,
	'rollout strict concat mode rejects unsafe implicit concat';

done_testing;
