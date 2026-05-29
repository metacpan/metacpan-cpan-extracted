use Test2::V0;
use Data::Dumper;

use Zuzu::Parser;

my $p = Zuzu::Parser->new;
my $ast = $p->parse(<<'SRC', "test.zzs");
function add_nums () {
	return 1 + 2;
}
SRC

# diag Dumper( $ast );
ok 1, 'base parse still succeeds';

my $ast_ops = $p->parse(<<'SRC', 'operators.zzs');
let a := not false;
let b := true xor false;
let c := true nand true;
let d := "A" eqi "a";
let e := 3 <=> 2;
let f := 1 ≶ 2;
SRC

ok $ast_ops, 'parser accepts new operator features';

my $ast_classes = $p->parse(<<'SRC', 'classes.zzs');
class Animal {
	let name;
	method get_name () {
		return name;
	}
	static method kingdom () {
		return "animalia";
	}
}
class Dog extends Animal;
let dog := new Dog( name: "Bluey" );
dog.get_name();
SRC

ok $ast_classes, 'parser accepts class and new features';

my $ast_traits = $p->parse(<<'SRC', 'traits.zzs');
trait Runner {
	method run () {
		return "ok";
	}
}
class Dog with Runner;
SRC

ok $ast_traits, 'parser accepts trait and class composition features';

my $ast_collections = $p->parse(<<'SRC', 'collections.zzs');
let arr := [ 1, 2, 3 ];
arr[1:2] := [ 9 ];
let dict := { key: 1, in: 2 };
dict{key} := 2;
dict{in} := 3;
let set := << 1, 2, 2 >>;
let bag := <<< 1, 2, 2 >>>;
let empty := ∅;
let subset := ( set subsetof << 1, 2, 3 >> );
let both := ( set union << 5 >> ) intersection << 2, 5 >>;
SRC

ok $ast_collections, 'parser accepts collection literals and lvalue forms';

my $ast_for_reuse = $p->parse(<<'SRC', 'for-reuse.zzs');
let i := 0;
for ( i in [ 1, 2, 3 ] ) {
	i += 1;
}
SRC

ok $ast_for_reuse, 'parser accepts for loops that reuse declared variables';

my $ast_for_const = $p->parse(<<'SRC', 'for-const.zzs');
for ( const item in [ 1, 2, 3 ] ) {
	item;
}
SRC

ok $ast_for_const, 'parser accepts for loops with const loop variables';

my $ast_regex = $p->parse(<<'SRC', 'regex.zzs');
let ratio := 6 / 3;
let text := "FoObAr";
let m := text ~ /(foo)(bar)/i;
if ( let cond := text ~ /foo/i ) {
	cond[0];
}
if ( m := text ~ /(foo)/i ) {
	m[1];
}
SRC

ok $ast_regex, 'parser accepts regexp literals, ~ operator, and condition let/assignment';

my $ast_path_ops = $p->parse(<<'SRC', 'path-operators-phase2.zzs');
let source := {};
let a := 1;
let b := 2;
let lhs := source @ "items[0]";
let exists := source @? "items[1]";
let many := source @@ "items[*]";
let tight1 := a@@b;
let tight2 := a@?b;
let writable := source @ "items[0]";
writable := 1;
source @ "items[0]" := 2;
source @ "items[0]" += 3;
source @? "items[1]" := 4;
source @? "items[1]" += 5;
source @@ "items[*]" := [ 3, 4 ];
source @@ "items[*]" += 6;
\( source @ "items[0]" );
\( source @@ "items[*]" );
\( source @? "items[1]" );
++( source @ "items[0]" );
( source @@ "items[*]" )++;
SRC

ok $ast_path_ops, 'parser accepts @, @?, @@ tokenization and assignment targets';

my $ast_pod = $p->parse(<<'SRC', 'pod-sections.zzs');
let before := 1;
=pod
This line is ignored by the parser.
=head1 A heading is still pod.
=cut
let after := before + 1;
SRC

ok $ast_pod, 'parser ignores pod sections that begin at start of line';

my $ast_pod_to_eof = $p->parse(<<'SRC', 'pod-to-eof.zzs');
let value := 41;
=pod
Pod may continue until end of file.
No explicit cut marker is required.
SRC

ok $ast_pod_to_eof, 'parser ignores pod sections through end of file';

my $ast_shebang = $p->parse(<<'SRC', 'shebang.zzs');
#!/usr/bin/env zuzu
let shebang_value := 7;
function shebang_result () {
	return shebang_value;
}
SRC

ok $ast_shebang, 'parser ignores leading shebang line';

my $ast_block_separator = $p->parse(<<'SRC', 'block-separator.zzs');
function block_separator_demo () {
	let x := 1;
	let y := 2
}
SRC

ok $ast_block_separator, 'parser treats semicolon as separator in blocks';

my $ast_eof_separator = $p->parse(<<'SRC', 'eof-separator.zzs');
let value := 41
SRC

ok $ast_eof_separator, 'parser allows final statement at EOF without semicolon';

my $ast_eof_return = $p->parse(<<'SRC', 'eof-return.zzs');
function eof_return () {
	return
}
SRC

ok $ast_eof_return, 'parser allows return without semicolon before block close';

my $ast_if_trailing_semicolon = $p->parse(<<'SRC', 'if-trailing-semicolon.zzs');
if ( true ) {
	say "ok";
};
SRC

ok $ast_if_trailing_semicolon, 'parser allows trailing semicolon after if block';

my $ast_extra_semicolons = $p->parse(<<'SRC', 'extra-semicolons.zzs');
say "ok"; ; ;
say "done";;;
SRC

ok $ast_extra_semicolons, 'parser treats standalone semicolons as no-op separators';

my $ast_spread_args = $p->parse(<<'SRC', 'spread-args.zzs');
function foo () {
	return 1;
}
let items := [];
let opts := {};
let obj := {};
let method_name := "method";
class Thing;
foo(...items);
foo(1, name: 2, ("other"): 3, ...items);
obj.method(...items);
obj.(method_name)(...items);
new Thing(...opts);
SRC

my $call_spread = $ast_spread_args->statements->[6]->expr;
isa_ok $call_spread, ['Zuzu::AST::Expr::Call'], 'function spread call';
is $call_spread->args->[0][0], undef, 'spread call argument is positional';
isa_ok $call_spread->args->[0][1], ['Zuzu::AST::Expr::Spread'], 'spread argument node';
isa_ok $call_spread->args->[0][1]->expr, ['Zuzu::AST::Expr::Var'], 'spread wraps inner expression';
is $call_spread->args->[0][1]->expr->name, 'items', 'spread inner expression is preserved';

my $mixed_call = $ast_spread_args->statements->[7]->expr;
is scalar @{ $mixed_call->args }, 4, 'mixed call keeps all arguments';
is $mixed_call->args->[0][0], undef, 'ordinary positional argument stays positional';
is $mixed_call->args->[1][0], 'name', 'named argument label is preserved';
ok $mixed_call->args->[2][2], 'computed named argument is marked as computed';
isa_ok $mixed_call->args->[2][0], ['Zuzu::AST::Expr::Literal'],
	'computed named argument label expression is preserved';
isa_ok $mixed_call->args->[3][1], ['Zuzu::AST::Expr::Spread'], 'mixed call has spread marker';

my $member_spread = $ast_spread_args->statements->[8]->expr;
isa_ok $member_spread, ['Zuzu::AST::Expr::MemberCall'], 'method spread call';
isa_ok $member_spread->args->[0][1], ['Zuzu::AST::Expr::Spread'], 'method call spread argument';

my $dynamic_spread = $ast_spread_args->statements->[9]->expr;
isa_ok $dynamic_spread, ['Zuzu::AST::Expr::DynamicMemberCall'], 'dynamic method spread call';
isa_ok $dynamic_spread->args->[0][1], ['Zuzu::AST::Expr::Spread'], 'dynamic method call spread argument';

my $new_spread = $ast_spread_args->statements->[10]->expr;
isa_ok $new_spread, ['Zuzu::AST::Expr::New'], 'constructor spread call';
isa_ok $new_spread->args->[0][1], ['Zuzu::AST::Expr::Spread'], 'constructor spread argument';

my $ast_ranges = $p->parse(<<'SRC', 'ranges-still-collections.zzs');
let arr := [ 1...3 ];
let set := << 1...3 >>;
let bag := <<< 1...3 >>>;
SRC

isa_ok $ast_ranges->statements->[0]->init->items->[0], ['Zuzu::AST::Expr::Range'],
	'array literal range still parses as Range';
isa_ok $ast_ranges->statements->[1]->init->items->[0], ['Zuzu::AST::Expr::Range'],
	'set literal range still parses as Range';
isa_ok $ast_ranges->statements->[2]->init->items->[0], ['Zuzu::AST::Expr::Range'],
	'bag literal range still parses as Range';

like dies {
	$p->parse(<<'SRC', 'range-in-call.zzs');
function foo () { return 1; }
foo(1...3);
SRC
}, qr/Range syntax '\.\.\.' is only valid in collection literals/,
	'range syntax is rejected in call argument lists';

like dies {
	$p->parse(<<'SRC', 'named-spread.zzs');
function foo () { return 1; }
let opts := {};
foo(a: ...opts);
SRC
}, qr/Spread arguments cannot be named/,
	'named spread is rejected';

like dies {
	$p->parse(<<'SRC', 'bare-spread.zzs');
let items := [];
let x := ...items;
SRC
}, qr/Spread argument '\.\.\.' is only valid in call argument lists/,
	'bare spread expression is rejected';

like dies {
	$p->parse(<<'SRC', 'array-spread.zzs');
let items := [];
let x := [ ...items ];
SRC
}, qr/Spread argument '\.\.\.' is only valid in call argument lists/,
	'array spread literal is rejected';

like dies {
	$p->parse(<<'SRC', 'dict-spread.zzs');
let items := {};
let x := { a: ...items };
SRC
}, qr/Spread argument '\.\.\.' is only valid in call argument lists/,
	'dict value spread is rejected';

like dies {
	$p->parse(<<'SRC', 'explicit-here-param.zzs');
let f := fn ^^ -> ^^;
SRC
}, qr/'\^\^' is reserved for the chain placeholder/,
	'explicit ^^ lambda parameter is rejected';

done_testing;
