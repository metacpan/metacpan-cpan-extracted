use utf8;
use Test2::V0;

use Zuzu::Parser;

my $parser = Zuzu::Parser->new;

my @valid_sources = (
	[
		'weak let declaration without initializer',
		<<'ZZS',
let parent but weak;
ZZS
	],
	[
		'weak let declaration with initializer',
		<<'ZZS',
let owner := null;
let parent := owner but weak;
ZZS
	],
	[
		'weak const declaration with initializer',
		<<'ZZS',
let owner := null;
const root := owner but weak;
ZZS
	],
	[
		'weak class field with generated accessors',
		<<'ZZS',
class Node {
	let parent with get, set, clear, has but weak;
}
ZZS
	],
	[
		'one-off weak lexical assignment',
		<<'ZZS',
let owner := null;
let parent;
parent := owner but weak;
ZZS
	],
	[
		'one-off weak array index assignment',
		<<'ZZS',
let owner := null;
let arr := [];
arr[0] := owner but weak;
ZZS
	],
	[
		'one-off weak dict key assignment',
		<<'ZZS',
let owner := null;
let dict := {};
dict{"parent"} := owner but weak;
ZZS
	],
	[
		'one-off weak first-match path assignment',
		<<'ZZS',
let owner := null;
let data := { parent: null };
data @ "/parent" := owner but weak;
ZZS
	],
	[
		'one-off weak all-matches path assignment',
		<<'ZZS',
let owner := null;
let data := { items: [ { parent: null } ] };
data @@ "/items/*/parent" := owner but weak;
ZZS
	],
);

for my $case ( @valid_sources ) {
	my ( $name, $source ) = @$case;
	ok(
		lives { $parser->parse( $source, "weak-contract-$name.zzs" ) },
		"$name parses",
	);
}

{
	my $ast = $parser->parse( 'let parent but weak;', 'weak-let-no-init.zzs' );
	my $stmt = $ast->statements->[0];
	is $stmt->is_weak_storage, 1, 'let without initializer stores weak metadata';
	ok !defined $stmt->init, 'weak let without initializer has no initializer';
}

{
	my $ast = $parser->parse(
		"let owner := null;\nlet parent := owner but weak;\n",
		'weak-let-init.zzs',
	);
	my $stmt = $ast->statements->[1];
	is $stmt->is_weak_storage, 1, 'let initializer weak marker is declaration metadata';
}

{
	my $ast = $parser->parse(
		"let owner := null;\nlet parent;\nparent := owner but weak;\n",
		'weak-assignment.zzs',
	);
	my $stmt = $ast->statements->[2];
	is $stmt->is_weak_write, 1, 'assignment has one-off weak metadata';
	is $stmt->op, ':=', 'weak assignment remains a simple assignment';
}

{
	my $ast = $parser->parse( <<'ZZS', 'weak-field.zzs' );
class Node {
	let parent with get, set, clear, has but weak;
}
ZZS
	my $class = $ast->statements->[0];
	is $class->fields->[0]{is_weak_storage}, 1, 'field stores weak metadata';
	my ($setter) = grep { $_->name eq 'set_parent' } @{ $class->methods };
	my ($assign) = grep { $_->can('is_weak_write') } @{ $setter->body->statements };
	is $assign->is_weak_write, 1, 'generated setter assignment preserves weak metadata';
}

my @invalid_sources = (
	[
		'weak marker is not a function argument marker',
		<<'ZZS',
let myarray := [];
let x := null;
myarray.push(x but weak);
ZZS
	],
	[
		'weak marker is not a parenthesized expression',
		<<'ZZS',
let y := null;
let x := (y but weak);
ZZS
	],
	[
		'weak marker is not valid on numeric compound assignment',
		<<'ZZS',
let x := 1;
let y := 2;
x += y but weak;
ZZS
	],
	[
		'weak marker is not valid on string compound assignment',
		<<'ZZS',
let x := "";
let y := "suffix";
x _= y but weak;
ZZS
	],
	[
		'weak marker is not valid on null-coalescing assignment',
		<<'ZZS',
let x;
let y := 1;
x ?:= y but weak;
ZZS
	],
	[
		'weak marker is not valid on maybe path assignment',
		<<'ZZS',
let owner := null;
let data := {};
data @? "/parent" := owner but weak;
ZZS
	],
);

for my $case ( @invalid_sources ) {
	my ( $name, $source ) = @$case;
	like(
		dies { $parser->parse( $source, "weak-contract-$name.zzs" ) },
		qr/but|weak|assign|Invalid|Unexpected/i,
		"$name is rejected",
	);
}

done_testing;
