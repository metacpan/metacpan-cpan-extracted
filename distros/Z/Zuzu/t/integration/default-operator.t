use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'default-operator.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'Dict default keeps left keys and copies result';
let left := { a: 1, b: 2 };
let merged := left default { b: 20, c: 30 };
merged.set( "d", 40 );
( merged instanceof Dict )
	and merged{"a"} = 1
	and merged{"b"} = 2
	and merged{"c"} = 30
	and merged{"d"} = 40
	and left.length() = 2
	and ! left.exists("c")
	and ! left.exists("d");
SRC

is eval_src(<<'SRC'), 1, 'Dict default from PairList takes first missing default';
let merged := { a: 1 } default {{ a: 9, b: 2, b: 3 }};
( merged instanceof Dict )
	and merged.length() = 2
	and merged{"a"} = 1
	and merged{"b"} = 2;
SRC

is eval_src(<<'SRC'), 1, 'PairList default appends missing duplicate pairs in order';
let left := {{ a: 1, dup: 2, dup: 3 }};
let merged := left default {{ dup: 20, b: 4, b: 5, c: 6 }};
let keys := merged.keys();
let b := merged.get_all("b");
let dup := merged.get_all("dup");
( merged instanceof PairList )
	and keys.length() = 6
	and keys[0] eq "a"
	and keys[1] eq "dup"
	and keys[2] eq "dup"
	and keys[3] eq "b"
	and keys[4] eq "b"
	and keys[5] eq "c"
	and dup.length() = 2
	and dup[0] = 2
	and dup[1] = 3
	and b.length() = 2
	and b[0] = 4
	and b[1] = 5;
SRC

is eval_src(<<'SRC'), 1, 'null default behaves like an empty PairList';
let merged := null default {{ a: 1, a: 2 }};
let all := merged.get_all("a");
( merged instanceof PairList )
	and merged.length() = 2
	and all[0] = 1
	and all[1] = 2;
SRC

is eval_src(<<'SRC'), 1, 'default is left associative';
let merged := {{ a: 1 }} default {{ b: 2 }} default {{ b: 3, c: 4 }};
let b := merged.get_all("b");
( merged instanceof PairList )
	and merged.length() = 3
	and b.length() = 1
	and b[0] = 2
	and merged{"c"} = 4;
SRC

is eval_src(<<'SRC'), 'given:7',
	'default expression is spread as one call argument';
class Thing {
	let name with get;
	let count with get;
}
let opts := {{ name: "given" }};
let thing := new Thing( ... opts default {{ name: "fallback", count: 7 }} );
thing.get_name() _ ":" _ thing.get_count();
SRC

my $ast_spread = $parser->parse(<<'SRC', 'default-spread-precedence.zzs');
function connect () {
	return 1;
}
let opts := {};
connect(... opts default { timeout: 30 });
SRC

my $spread = $ast_spread->statements->[2]->expr->args->[0][1];
isa_ok $spread, ['Zuzu::AST::Expr::Spread'],
	'spread argument wraps a single expression';
isa_ok $spread->expr, ['Zuzu::AST::Expr::Binary'],
	'default expression binds inside spread';
is $spread->expr->op, 'default', 'spread expression is the default operator';
isa_ok $spread->expr->left, ['Zuzu::AST::Expr::Var'],
	'default left operand is preserved';
isa_ok $spread->expr->right, ['Zuzu::AST::Expr::Dict'],
	'default right operand is preserved';

my $ast_assoc = $parser->parse(<<'SRC', 'default-left-assoc.zzs');
let merged := { a: 1 } default { b: 2 } default { c: 3 };
SRC

my $assoc = $ast_assoc->statements->[0]->init;
isa_ok $assoc, ['Zuzu::AST::Expr::Binary'],
	'default chain parses as a binary expression';
is $assoc->op, 'default', 'outer default operator is preserved';
isa_ok $assoc->left, ['Zuzu::AST::Expr::Binary'],
	'default operator is left associative';
is $assoc->left->op, 'default', 'left side contains the earlier default';
isa_ok $assoc->right, ['Zuzu::AST::Expr::Dict'],
	'right side contains the final operand';

like dies {
	eval_src('({ a: 1 }) default null;');
}, qr/default operator right operand expects Dict or PairList, got Null/,
	'right null throws a clear runtime error';

like dies {
	eval_src('23 default { a: 1 };');
}, qr/default operator left operand expects Dict, PairList, or Null, got Number/,
	'invalid left operand throws a clear runtime error';

like dies {
	eval_src('({ a: 1 }) default 23;');
}, qr/default operator right operand expects Dict or PairList, got Number/,
	'invalid right operand throws a clear runtime error';

done_testing;
