use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
	my $ast = $parser->parse( $src, 'weak-reference-class-fields-phase6.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'constructor args honour weak field metadata';
class Node {
	let parent with get, has but weak;
}
let owner := new Node();
let child := new Node( parent: owner );
let alive := child.has_parent() and child.get_parent() ≢ null;
owner := null;
alive and child.get_parent() ≡ null and not child.has_parent();
SRC

is eval_src(<<'SRC'), 1, 'field initializer values are stored weakly';
class Box {}
let owner := new Box();
class Holder {
	let parent with get, has := owner but weak;
}
let holder := new Holder();
let alive := holder.has_parent() and holder.get_parent() ≢ null;
owner := null;
alive and holder.get_parent() ≡ null and not holder.has_parent();
SRC

is eval_src(<<'SRC'), 1, 'generated set accessor stores weakly';
class Node {
	let parent with get, set, has but weak;
}
let owner := new Node();
let child := new Node();
child.set_parent(owner);
let alive := child.has_parent() and child.get_parent() ≢ null;
owner := null;
alive and child.get_parent() ≡ null and not child.has_parent();
SRC

is eval_src(<<'SRC'), 1, 'generated clear accessor stores null normally';
class Node {
	let parent with get, set, clear, has but weak;
}
let owner := new Node();
let child := new Node();
child.set_parent(owner);
let alive := child.has_parent();
child.clear_parent();
alive and child.get_parent() ≡ null and not child.has_parent();
SRC

is eval_src(<<'SRC'), 1, 'weak class fields store scalar values normally';
class Node {
	let parent with get, set, has but weak;
}
let child := new Node( parent: "scalar" );
child.has_parent() and child.get_parent() eq "scalar";
SRC

is eval_src(<<'SRC'), 1, '__build__ sees constructor weak fields';
class Node {
	let parent but weak;
	let saw_parent := false;
	method __build__ () {
		saw_parent := parent ≢ null;
	}
	method saw () {
		return saw_parent;
	}
	method parent_is_null () {
		return parent ≡ null;
	}
}
let owner := new Node();
let child := new Node( parent: owner );
let saw := child.saw();
owner := null;
saw and child.parent_is_null();
SRC

is eval_src(<<'SRC'), 1, '__build__ assignment to weak fields stores weakly';
class Box {}
let source := new Box();
class Holder {
	let parent but weak;
	method __build__ () {
		parent := source;
	}
	method parent_is_null () {
		return parent ≡ null;
	}
}
let holder := new Holder();
let alive := not holder.parent_is_null();
source := null;
alive and holder.parent_is_null();
SRC

is eval_src(<<'SRC'), 1, 'weak parent field does not keep parent alive';
class Node {
	let parent with get, set, clear, has but weak;
	let children := [];
	method add_child ( child ) {
		children.push(child);
		child.set_parent(self);
		return child;
	}
}
let root := new Node();
let child := new Node();
root.add_child(child);
let alive := child.has_parent() and child.get_parent() ≢ null;
root := null;
alive and child.get_parent() ≡ null and not child.has_parent();
SRC

done_testing;
