use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'std-marshal-default-operator.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'std/marshal dumps and loads functions using default operator';
from std/marshal import dump, load;

let defaults := function () {
	return { a: 1 } default { b: 2 };
};

let loaded := load( dump(defaults) );
let merged := loaded();
merged{"a"} = 1
	and merged{"b"} = 2
	and merged instanceof Dict;
SRC

done_testing;
