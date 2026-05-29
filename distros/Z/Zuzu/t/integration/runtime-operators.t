use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;

	my $ast = $parser->parse( $src, 'runtime-operators.zzs' );

	return $runtime->evaluate($ast);
}

is(
	eval_src('let x := true ⊻ true; x;'),
	0,
	'integration smoke: unicode boolean alias parses and executes end-to-end',
);

is(
	eval_src('let m := "FoObAr" ~ /(foo)(bar)/i; m[1] _ ":" _ m[2];'),
	'FoO:bAr',
	'integration smoke: regex captures flow through parser and runtime',
);

my $assignment_condition_src = <<'SRC';
let mystr := "foo";
let match;
if ( match := mystr ~ /(foo)/ ) {
	match[1];
}
SRC

is(
	eval_src($assignment_condition_src),
	'foo',
	'integration smoke: assignment-in-condition executes via embedding API',
);

done_testing;
