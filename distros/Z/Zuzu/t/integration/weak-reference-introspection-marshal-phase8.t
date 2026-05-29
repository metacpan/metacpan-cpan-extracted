use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
	my $ast = $parser->parse( $src, 'weak-reference-marshal-phase8.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'equality and typeof use resolved weak values';
class Box {}
let owner := new Box();
let arr := [];
let dict := {};
let pairs := new PairList();
arr.push_weak(owner);
dict.set_weak( "owner", owner );
pairs.add_weak( "owner", owner );
let live := ( arr == [ owner ] )
	and ( dict == { owner: owner } )
	and ( pairs == {{ owner: owner }} )
	and typeof arr[0] eq "Box";
owner := null;
live
	and ( arr == [ null ] )
	and ( dict == { owner: null } )
	and ( pairs == {{ owner: null }} )
	and typeof arr[0] eq "Null";
SRC

is eval_src(<<'SRC'), 1, 'object_slots and std/dump expose resolved values';
from std/dump import Dumper;
from std/internals import object_slots;
class Holder {
	let parent but weak;
}
let owner := new Holder();
let holder := new Holder();
holder{"parent"} := owner;
let slots := object_slots(holder);
let live := slots{"parent"} != null;
slots := null;
owner := null;
let dead_slots := object_slots(holder);
let text := Dumper.dump( holder, { sort_keys: true } );
live
	and dead_slots{"parent"} ≡ null
	and text eq "new Holder(parent:null)";
SRC

is eval_src(<<'SRC'), 1, 'marshal preserves live weak collection edges';
from std/internals import ref_id;
from std/marshal import dump, load;
class Box {}
let owner := new Box();
let arr := [];
arr.push_weak(owner);
arr.push(owner);
let loaded := load( dump(arr) );
let live := loaded[0] ≢ null
	and ref_id( loaded[0] ) = ref_id( loaded[1] );
loaded[1] := null;
owner := null;
live and loaded[0] ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'marshal weak-only collection edges load as null';
from std/marshal import dump, load;
class Box {}
let owner := new Box();
let arr := [];
let dict := {};
let pairs := new PairList();
let set := << >>;
let bag := <<< >>>;
arr.push_weak(owner);
dict.set_weak( "owner", owner );
pairs.add_weak( "owner", owner );
set.add_weak(owner);
bag.add_weak(owner);
let loaded := load( dump([ arr, dict, pairs, set, bag ]) );
loaded[0][0] ≡ null
	and loaded[1]{"owner"} ≡ null
	and loaded[2]{"owner"} ≡ null
	and loaded[3].contains(null)
	and loaded[4].contains(null);
SRC

is eval_src(<<'SRC'), 1, 'marshal preserves weak object fields';
from std/internals import ref_id;
from std/marshal import dump, load;
class Node {
	let parent with get, set but weak;
}
let parent := new Node();
let child := new Node();
child.set_parent(parent);
let loaded := load( dump([ parent, child ]) );
let loaded_parent := loaded[0];
let loaded_child := loaded[1];
let live := loaded_child.get_parent() ≢ null
	and ref_id( loaded_child.get_parent() ) = ref_id(loaded_parent);
loaded_parent := null;
loaded[0] := null;
parent := null;
live and loaded_child.get_parent() ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'marshal keeps scalar weak records readable';
from std/marshal import dump, load;
let arr := [];
let dict := {};
arr.push_weak("scalar");
dict.set_weak( "owner", "scalar" );
let loaded := load( dump([ arr, dict ]) );
loaded[0][0] eq "scalar" and loaded[1]{"owner"} eq "scalar";
SRC

done_testing;
