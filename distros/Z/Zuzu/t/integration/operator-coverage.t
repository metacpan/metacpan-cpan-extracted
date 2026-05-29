use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'operator-coverage.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src('1 + 2;'), 3,
	'operator smoke: arithmetic expression evaluates end-to-end';

is eval_src('let x := 1; x += 4; x;'), 5,
	'operator smoke: assignment expression mutates via runtime';

is eval_src('let m := "Abc" ~ /(a)(bc)/i; m[2];'), 'bc',
	'operator smoke: regex capture operator evaluates';

is eval_src('true ⊻ true;'), 0,
	'operator smoke: unicode boolean alias parses and executes';

is eval_src('let x := 0; x ?:= 4; x;'), 0,
	'operator smoke: ternary assignment operator is available';

done_testing;
