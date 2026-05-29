use Test2::V0;

use Scalar::Util qw( blessed refaddr );

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub vars_named {
	my ( $node, $name, $seen ) = @_;

	return () if !defined $node;
	$seen //= {};

	if ( blessed($node) ) {
		my $addr = refaddr($node);
		return () if defined $addr and $seen->{$addr}++;
		my @found;
		push @found, $node
			if $node->isa('Zuzu::AST::Expr::Var')
			and $node->name eq $name;
		for my $value ( values %{ $node } ) {
			push @found, vars_named( $value, $name, $seen );
		}
		return @found;
	}

	if ( ref($node) eq 'ARRAY' ) {
		my $addr = refaddr($node);
		return () if defined $addr and $seen->{$addr}++;
		return map { vars_named( $_, $name, $seen ) } @{ $node };
	}

	if ( ref($node) eq 'HASH' ) {
		my $addr = refaddr($node);
		return () if defined $addr and $seen->{$addr}++;
		return map { vars_named( $_, $name, $seen ) } values %{ $node };
	}

	return ();
}

my $reuse_block_ast = $parser->parse(<<'SRC', 'lexical-reuse-hint.zzs');
let Number counter := 1;
if (counter == 1) {
	counter := counter + 1;
}
counter;
SRC

is $reuse_block_ast->statements->[1]->then_block->reuse_current_env, 1,
	'block without declarations or calls is marked for current-env reuse';
is [ sort map { $_->{_env_depth} } vars_named( $reuse_block_ast, 'counter' ) ],
	[ 0, 0, 0, 0 ],
	'reused block variables resolve in the current env';

my $decl_block_ast = $parser->parse(<<'SRC', 'lexical-block-frame.zzs');
if (true) {
	let y := 2;
	y;
}
SRC

is $decl_block_ast->statements->[0]->then_block->reuse_current_env, 0,
	'block with lexical declarations keeps a new env';
is [ map { $_->{_env_depth} } vars_named( $decl_block_ast, 'y' ) ],
	[0],
	'block-local variable resolves in the block env';

my $closure_ast = $parser->parse(<<'SRC', 'lexical-closure-depth.zzs');
let outer := 10;
function make (v) {
	let local := v;
	return function (delta) {
		local += delta;
		return outer + local + delta;
	};
}
SRC

is [ sort map { $_->{_env_depth} } vars_named( $closure_ast, 'local' ) ],
	[ 1, 1 ],
	'closure local resolves through one captured parent env';
is [ map { $_->{_env_depth} } vars_named( $closure_ast, 'outer' ) ],
	[3],
	'outer variable resolves through the closure and enclosing call envs';
is [ sort map { $_->{_env_depth} } vars_named( $closure_ast, 'delta' ) ],
	[ 0, 0 ],
	'inner function parameter resolves in the current call env';

my $for_ast = $parser->parse(<<'SRC', 'lexical-for-depth.zzs');
let values := [1];
for (let item in values) {
	item;
}
SRC

is [ map { $_->{_env_depth} } vars_named( $for_ast, 'item' ) ],
	[0],
	'declared loop variable resolves in the loop env when body reuses it';

my $catch_ast = $parser->parse(<<'SRC', 'lexical-catch-depth.zzs');
try {
	die "boom";
} catch (e) {
	e;
}
SRC

is [ map { $_->{_env_depth} } vars_named( $catch_ast, 'e' ) ],
	[0],
	'catch variable resolves in the catch env';

my $class_ast = $parser->parse(<<'SRC', 'lexical-method-self-depth.zzs');
class Box {
	method get_self () {
		return self;
	}
}
SRC

is [ map { $_->{_env_depth} } vars_named( $class_ast, 'self' ) ],
	[0],
	'method self resolves in the method call env';

my $import_ast = $parser->parse(<<'SRC', 'lexical-import-depth.zzs');
from std/time import Time;
Time;
SRC

is [ map { $_->{_env_depth} } vars_named( $import_ast, 'Time' ) ],
	[0],
	'named imports are annotated in the current env';

my $wildcard_ast = $parser->parse(<<'SRC', 'lexical-wildcard-import-depth.zzs');
from std/time import *;
Time;
SRC

ok !exists( ( vars_named( $wildcard_ast, 'Time' ) )[0]->{_env_depth} ),
	'wildcard-import-only names are left for runtime lookup fallback';

my $closure_runtime = Zuzu::Runtime->new;
$closure_runtime->evaluate( $parser->parse(<<'SRC', 'lexical-closure-runtime.zzs') );
function make (v) {
	return function () {
		return v;
	};
}
let a := make(1);
let b := make(2);
function call_a () {
	return a();
}
function call_b () {
	return b();
}
SRC

is $closure_runtime->call('call_a'), 1,
	'first closure keeps its captured environment';
is $closure_runtime->call('call_b'), 2,
	'second closure keeps a distinct captured environment';

my $recursive_runtime = Zuzu::Runtime->new;
$recursive_runtime->evaluate( $parser->parse(<<'SRC', 'lexical-recursion-runtime.zzs') );
function fact (n) {
	if (n == 0) {
		return 1;
	}
	return n * fact(n - 1);
}
SRC

is $recursive_runtime->call( 'fact', 5 ), 120,
	'recursive calls resolve the current call frame';

my $eval_runtime = Zuzu::Runtime->new;
$eval_runtime->evaluate( $parser->parse( 'let x := 41;', 'lexical-eval-root.zzs' ) );
is $eval_runtime->eval_with_current_scope( 'x + 1', 'lexical-eval.zzs' ), 42,
	'dynamic eval caller-scope names fall back to runtime lookup';

like dies {
	my $const_runtime = Zuzu::Runtime->new;
	$const_runtime->evaluate(
		$parser->parse( 'const x := 1; x := 2;', 'lexical-const-runtime.zzs' )
	);
}, qr/Cannot assign to const/,
	'depth-optimized assignment preserves const checks';

done_testing;
