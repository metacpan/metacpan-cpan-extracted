use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

my $ast = $parser->parse(<<'SRC', 'typecheck-hints.zzs');
let Number x := 5;
let Number y := x;
let Number z := 0;
z := y;
function take ( Number n, String label := "ok" ) {
	return n;
}
take(y);
take(7);
SRC

my $let_x = $ast->statements->[0];
my $let_y = $ast->statements->[1];
my $assign_z = $ast->statements->[3];
my $fn_take = $ast->statements->[4];
my $call_y = $ast->statements->[5]->expr;
my $call_7 = $ast->statements->[6]->expr;

ok $let_x->{_skip_type_check},
	'typed literal initializer is marked as safe for runtime type checks';

ok $let_y->{_skip_type_check},
	'typed initializer from another typed variable is marked as safe';

ok $assign_z->{_skip_type_check},
	'typed assignment from another typed variable is marked as safe';

is $fn_take->{_default_typecheck_safe}{label}, 1,
	'typed function default literal is marked as safe';

is $call_y->{_arg_static_types}[0], 'Number',
	'call argument from typed variable carries static type hint';

is $call_7->{_arg_static_types}[0], 'Number',
	'call argument from literal carries static type hint';

my $spread_hint_ast = $parser->parse(<<'SRC', 'spread-typecheck-hints.zzs');
let Number y := 5;
let items := [];
function take ( Number n ) {
	return n;
}
take(y, ...items);
SRC

my $spread_hint_call = $spread_hint_ast->statements->[3]->expr;
is $spread_hint_call->{_arg_static_types}, ['Number'],
	'spread arguments do not add ordinary positional static type hints';

my $runtime = Zuzu::Runtime->new;
$runtime->evaluate($ast);

is $runtime->call('take', 9), 9,
	'optimized hints still preserve correct function behavior';

like dies {
	my $bad_ast = $parser->parse(<<'SRC_BAD', 'typecheck-hints-bad.zzs');
function take_number ( Number n ) {
	return n;
}
let any_value := "nope";
take_number(any_value);
SRC_BAD

	my $bad_runtime = Zuzu::Runtime->new;
	$bad_runtime->evaluate($bad_ast);
}, qr/TypeException/,
	'untyped call arguments still perform runtime type checks';

done_testing;
