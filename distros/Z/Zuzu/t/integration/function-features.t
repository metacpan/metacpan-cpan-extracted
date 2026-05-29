use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub runtime_for {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'function-features.zzs' );
	$runtime->evaluate($ast);

	return $runtime;
}

my $runtime = runtime_for(<<'SRC');
function add (x, y) {
	return x + y;
}
SRC

is $runtime->call( 'add', 2, 5 ), 7,
	'Runtime->call invokes parsed functions (integration smoke)';

my $typed_runtime = runtime_for(<<'SRC');
function label ( Number n ) {
	return n;
}
SRC

like dies {
	$typed_runtime->call( 'label', 'nope' );
}, qr/TypeException/,
	'typed parameter mismatch still throws via embedding runtime';

like dies {
	$parser->parse(<<'SRC', 'const-param-assignment.zzs');
function bump ( Number x ) {
	x += 1;
	return x;
}
SRC
}, qr/Cannot assign to const 'x' \(compile-time\)/,
	'const parameter assignment rejection is kept as parser-level check';

like dies {
	$parser->parse(<<'SRC', 'const-param-incdec.zzs');
function bump ( Number x ) {
	++x;
	return x;
}
SRC
}, qr/Cannot assign to const 'x' \(compile-time\)/,
	'const parameter ++/-- rejection is kept as parser-level check';

like dies {
	$parser->parse(<<'SRC', 'bad-optional-order.zzs');
function bad ( a?, b ) {
	return a;
}
SRC
}, qr/cannot follow optional\/default parameters/,
	'ordering constraint remains covered as parser-only negative test';

done_testing;
