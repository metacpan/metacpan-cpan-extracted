use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'collection-copy.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'copy is available and returns collection kinds';
let arr := [ 1 ].copy();
let bag := <<< 1 >>>.copy();
let set := << 1 >>.copy();
let dict := { a: 1 }.copy();
let pairs := {{ a: 1 }}.copy();
( arr instanceof Array )
	and ( bag instanceof Bag )
	and ( set instanceof Set )
	and ( dict instanceof Dict )
	and ( pairs instanceof PairList );
SRC

is eval_src(<<'SRC'), 1, 'copy preserves values';
let arr := [ "a", "b" ].copy();
let bag := <<< "a", "a", "b" >>>.copy();
let set := << "a", "b" >>.copy();
let dict := { a: 1, b: 2 }.copy();
let pairs := {{ a: 1, a: 2, b: 3 }}.copy();
( arr[0] eq "a" )
	and ( arr[1] eq "b" )
	and ( bag.count("a") = 2 )
	and ( bag.contains("b") )
	and ( set.contains("a") )
	and ( set.contains("b") )
	and ( dict{"a"} = 1 )
	and ( dict{"b"} = 2 )
	and ( pairs{"a"} = 1 )
	and ( pairs.get_all("a")[1] = 2 )
	and ( pairs{"b"} = 3 );
SRC

is eval_src(<<'SRC'), 1, 'copy creates independent outer collections';
let arr := [ 1, 2 ];
let arr_copy := arr.copy();
arr_copy.push(3);
let bag := <<< 1, 2 >>>;
let bag_copy := bag.copy();
bag_copy.add(3);
let set := << 1, 2 >>;
let set_copy := set.copy();
set_copy.add(3);
let dict := { a: 1 };
let dict_copy := dict.copy();
dict_copy.set( "b", 2 );
let pairs := {{ a: 1 }};
let pairs_copy := pairs.copy();
pairs_copy.add( "b", 2 );
( arr.length() = 2 )
	and ( arr_copy.length() = 3 )
	and ( bag.length() = 2 )
	and ( bag_copy.length() = 3 )
	and ( set.length() = 2 )
	and ( set_copy.length() = 3 )
	and ( dict.length() = 1 )
	and ( dict_copy.length() = 2 )
	and ( pairs.length() = 1 )
	and ( pairs_copy.length() = 2 );
SRC

is eval_src(<<'SRC'), 1, 'copy is shallow';
class Holder {
	let String label with get, set;
}
let arr_holder := new Holder( label: "array" );
let bag_holder := new Holder( label: "bag" );
let set_holder := new Holder( label: "set" );
let dict_holder := new Holder( label: "dict" );
let pairs_holder := new Holder( label: "pairs" );
let arr := [ arr_holder ];
let bag := <<< bag_holder >>>;
let set := << set_holder >>;
let dict := { holder: dict_holder };
let pairs := {{ holder: pairs_holder }};
arr.copy()[0].set_label("array-copy");
bag.copy().to_Array().first( fn x -> x instanceof Holder ).set_label("bag-copy");
set.copy().to_Array().first( fn x -> x instanceof Holder ).set_label("set-copy");
dict.copy(){"holder"}.set_label("dict-copy");
pairs.copy(){"holder"}.set_label("pairs-copy");
( arr_holder.get_label() eq "array-copy" )
	and ( bag_holder.get_label() eq "bag-copy" )
	and ( set_holder.get_label() eq "set-copy" )
	and ( dict_holder.get_label() eq "dict-copy" )
	and ( pairs_holder.get_label() eq "pairs-copy" );
SRC

is eval_src(<<'SRC'), 1, 'pairlist copy preserves pair order and duplicates';
let pairs := {{ first: 1, dup: 2, dup: 3, last: 4 }};
let copy := pairs.copy();
let keys := copy.keys();
let dups := copy.get_all("dup");
( keys.length() = 4 )
	and ( keys[0] eq "first" )
	and ( keys[1] eq "dup" )
	and ( keys[2] eq "dup" )
	and ( keys[3] eq "last" )
	and ( dups.length() = 2 )
	and ( dups[0] = 2 )
	and ( dups[1] = 3 );
SRC

is eval_src(<<'SRC'), 1, 'array copy preserves weak metadata';
class Box {}
let owner := new Box();
let arr := [];
arr.push_weak(owner);
let copy := arr.copy();
let live := arr[0] != null and copy[0] != null;
owner := null;
live and arr[0] == null and copy[0] == null;
SRC

is eval_src(<<'SRC'), 1, 'bag copy preserves weak metadata';
class Box {}
let owner := new Box();
let bag := <<< >>>;
bag.add_weak(owner);
let copy := bag.copy();
let live := bag.contains(owner) and copy.contains(owner);
owner := null;
live and bag.contains(null) and copy.contains(null);
SRC

is eval_src(<<'SRC'), 1, 'set copy preserves weak metadata';
class Box {}
let owner := new Box();
let set := << >>;
set.add_weak(owner);
let copy := set.copy();
let live := set.contains(owner) and copy.contains(owner);
owner := null;
live and set.contains(null) and copy.contains(null);
SRC

is eval_src(<<'SRC'), 1, 'dict copy preserves weak metadata';
class Box {}
let owner := new Box();
let dict := {};
dict.set_weak( "owner", owner );
let copy := dict.copy();
let live := dict{"owner"} != null and copy{"owner"} != null;
owner := null;
live
	and dict.exists("owner")
	and copy.exists("owner")
	and dict{"owner"} == null
	and copy{"owner"} == null;
SRC

is eval_src(<<'SRC'), 1, 'pairlist copy preserves weak metadata';
class Box {}
let owner := new Box();
let pairs := new PairList();
pairs.add_weak( "owner", owner );
let copy := pairs.copy();
let live := pairs{"owner"} != null and copy{"owner"} != null;
owner := null;
live
	and pairs.exists("owner")
	and copy.exists("owner")
	and pairs{"owner"} == null
	and copy{"owner"} == null;
SRC

done_testing;
