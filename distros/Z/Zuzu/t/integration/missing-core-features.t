use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'missing-core-features.zzs' );

	return $runtime->evaluate($ast);
}

{
	local $Zuzu::Runtime::DEBUG_LEVEL = 2;
	my $stderr = '';
	open my $err_fh, '>', \$stderr or die "Cannot capture STDERR: $!";
	local *STDERR = $err_fh;
	eval {
		eval_src(<<'SRC');
debug 3, "skip";
debug 2, "show";
SRC
		1;
	} or die $@;
	is(
		$stderr,
		"show\n",
		'runtime policy smoke: debug honors DEBUG level threshold',
	);
}

{
	local $Zuzu::Runtime::DEBUG_LEVEL = 0;
	my $assert_off_src = <<'SRC';
function explode () {
	die "boom";
}
let x := 9;
assert explode();
x;
SRC
	is(
		eval_src($assert_off_src),
		9,
		'runtime policy smoke: assert is skipped when DEBUG is disabled',
	);
}

{
	local $Zuzu::Runtime::DEBUG_LEVEL = 1;
	my $e = dies {
		eval_src(<<'SRC');
assert false;
SRC
	};
	ok(
		( ref($e) eq 'HASH' and $e->{_zuzu_throw} ),
		'runtime policy smoke: assert throws when DEBUG is enabled',
	);
}

like dies {
	$parser->parse(<<'SRC', 'typed-const-reassign.zzs');
const Number n := 7;
n := 8;
SRC
}, qr/Cannot assign to const/,
	'parser smoke: const declarations remain immutable';

is(
	eval_src(<<'SRC'),
let i := 0;
let total := 0;
for ( i in [ 1, 2, 3 ] ) {
	total += i;
}
total;
SRC
	6,
	'runtime smoke: for loop can reuse already declared variable',
);

like dies {
	$parser->parse(<<'SRC', 'for-undeclared-loop-var.zzs');
for ( missing in [ 1 ] ) {
	missing;
}
SRC
}, qr/Use of undeclared identifier 'missing'/,
	'parser smoke: for loop variable must be declared when let is omitted';

done_testing;
