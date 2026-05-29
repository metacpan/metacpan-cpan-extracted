use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'function-argument-spread.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 'last:7',
	'constructor arguments accept PairList spread with duplicate last value';
class Thing {
	let name with get;
	let count with get;
}
let thing := new Thing( ...{{ name: "first", count: 7, name: "last" }} );
thing.get_name() _ ":" _ thing.get_count();
SRC

like dies {
	eval_src(<<'SRC');
function passthrough ( ... args ) {
	return args;
}
passthrough( ...23 );
SRC
}, qr/Spread argument expects Array, Dict, or PairList, got Number/,
	'invalid spread operand reports expected spread operand types';

done_testing;
