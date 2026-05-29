use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
	my $ast = $parser->parse( $src, 'weak-reference-runtime-phase5.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'weak lexical declaration stores later writes weakly';
class Box {}
let owner := new Box();
let weak_ref but weak;
weak_ref := owner;
let alive := weak_ref ≢ null;
owner := null;
alive and weak_ref ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'weak let initializer stores initial value weakly';
class Box {}
let owner := new Box();
let weak_ref := owner but weak;
let alive := weak_ref ≢ null;
owner := null;
alive and weak_ref ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'one-off weak assignment does not make slot inherent';
class Box {}
let ref;
let owner := new Box();
ref := owner but weak;
owner := null;
let gone := ref ≡ null;
let strong := new Box();
ref := strong;
strong := null;
gone and ref ≢ null;
SRC

is eval_src(<<'SRC'), 1, 'weak slots store scalar values normally';
class Box {}
let weak_ref but weak;
weak_ref := "scalar";
let scalar_ok := weak_ref eq "scalar";
let owner := new Box();
weak_ref := owner;
owner := null;
scalar_ok and weak_ref ≡ null;
SRC

is eval_src(<<'SRC'), 1,
	'weak array index assignment reads null after owner clears';
class Box {}
let arr := [];
let owner := new Box();
arr[0] := owner but weak;
let alive := arr[0] ≢ null;
owner := null;
alive and arr[0] ≡ null;
SRC

is eval_src(<<'SRC'), 1,
	'weak dict key assignment reads null after owner clears';
class Box {}
let dict := {};
let owner := new Box();
dict{"parent"} := owner but weak;
let alive := dict{"parent"} ≢ null;
owner := null;
alive and dict{"parent"} ≡ null;
SRC

is eval_src(<<'SRC'), 1,
	'weak pairlist assignment reads null after owner clears';
class Box {}
let pairs := new PairList();
let owner := new Box();
pairs{"parent"} := owner but weak;
let alive := pairs{"parent"} ≢ null;
owner := null;
alive and pairs{"parent"} ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'method field assignment honours weak field metadata';
class Node {
	let parent but weak;
	method attach ( value ) {
		parent := value;
	}
	method parent_is_null () {
		return parent ≡ null;
	}
}
let child := new Node();
let owner := new Node();
child.attach(owner);
let alive := not child.parent_is_null();
owner := null;
alive and child.parent_is_null();
SRC

is eval_src(<<'SRC'), 1, 'direct object field assignment honours weak metadata';
class Node {
	let parent but weak;
}
let child := new Node();
let owner := new Node();
child{"parent"} := owner;
let alive := child{"parent"} ≢ null;
owner := null;
alive and child{"parent"} ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'weak first-match path assignment stores weakly';
class Box {}
let data := { parent: null };
let owner := new Box();
data @ "/parent" := owner but weak;
let alive := data{"parent"} ≢ null;
owner := null;
alive and data{"parent"} ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'weak all-matches path assignment stores weakly';
class Box {}
let data := { items: [ { parent: null }, { parent: null } ] };
let owner := new Box();
data @@ "/items/*/parent" := owner but weak;
let alive := data{"items"}[0]{"parent"} ≢ null
	and data{"items"}[1]{"parent"} ≢ null;
owner := null;
alive
	and data{"items"}[0]{"parent"} ≡ null
	and data{"items"}[1]{"parent"} ≡ null;
SRC

done_testing;
