use utf8;
use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
	my $ast = $parser->parse( $src, 'weak-reference-collections-phase7.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 1, 'Array weak methods store dead slots as null';
class Box {
	let label with get;
}
let owner := new Box( label: "owned" );
let arr := [];
arr.push_weak(owner);
arr.unshift_weak("front");
arr.set_weak( 2, owner );
let alive := arr[1].get_label() eq "owned"
	and arr[2].get_label() eq "owned";
owner := null;
alive
	and arr[0] eq "front"
	and arr[1] ≡ null
	and arr[2] ≡ null
	and arr.length() = 3;
SRC

is eval_src(<<'SRC'), 1, 'Array ordinary set replaces weak storage strongly';
class Box {
	let label with get;
}
let weak_owner := new Box( label: "weak" );
let arr := [];
arr.push_weak(weak_owner);
weak_owner := null;
let gone := arr[0] ≡ null;
let strong_owner := new Box( label: "strong" );
arr.set( 0, strong_owner );
strong_owner := null;
gone and arr[0].get_label() eq "strong";
SRC

is eval_src(<<'SRC'), 1, 'Dict weak methods keep dead entries present';
class Box {
	let label with get;
}
let owner := new Box( label: "owned" );
let dict := {};
dict.add_weak( "owner", owner );
dict.set_weak( "other", owner );
let alive := dict{"owner"}.get_label() eq "owned"
	and dict{"other"}.get_label() eq "owned";
owner := null;
alive
	and dict.exists("owner")
	and not dict.defined("owner")
	and dict{"owner"} ≡ null
	and dict{"other"} ≡ null
	and dict.length() = 2;
SRC

is eval_src(<<'SRC'), 1, 'PairList weak methods keep dead entries present';
class Box {
	let label with get;
}
let owner := new Box( label: "owned" );
let pairs := new PairList();
pairs.add_weak( "owner", owner );
pairs.set_weak( "other", owner );
let all := pairs.get_all("owner");
let alive := pairs{"owner"}.get_label() eq "owned"
	and pairs{"other"}.get_label() eq "owned"
	and all[0].get_label() eq "owned";
all := null;
owner := null;
alive
	and pairs.exists("owner")
	and not pairs.defined("owner")
	and pairs{"owner"} ≡ null
	and pairs{"other"} ≡ null
	and pairs.get_all("owner")[0] ≡ null
	and pairs.length() = 2;
SRC

is eval_src(<<'SRC'), 1, 'Set and Bag weak methods resolve dead members';
class Box {}
let owner := new Box();
let set := << >>;
let bag := <<< >>>;
set.add_weak(owner);
bag.add_weak(owner);
let alive := set.contains(owner) and bag.contains(owner);
owner := null;
alive
	and set.length() = 1
	and bag.length() = 1
	and set.contains(null)
	and bag.contains(null);
SRC

is eval_src(<<'SRC'), 1, 'ordinary collection methods remain strong';
class Box {
	let label with get;
}
let owner := new Box( label: "owned" );
let arr := [];
let dict := {};
let set := << >>;
let bag := <<< >>>;
let pairs := new PairList();
arr.push(owner);
dict.set( "owner", owner );
set.add(owner);
bag.add(owner);
pairs.add( "owner", owner );
owner := null;
arr[0].get_label() eq "owned"
	and dict{"owner"}.get_label() eq "owned"
	and set.contains(arr[0])
	and bag.contains(arr[0])
	and pairs{"owner"}.get_label() eq "owned";
SRC

is eval_src(<<'SRC'), 1, 'weak metadata survives collection rebuilds';
class Box {}
let owner := new Box();
let arr := [ "drop" ];
let bag := <<< "drop" >>>;
let set := << "drop" >>;
let pairs := new PairList();
arr.push_weak(owner);
bag.add_weak(owner);
set.add_weak(owner);
pairs.add( "drop", "drop" );
pairs.add_weak( "owner", owner );
arr.remove( fn x -> x == "drop" );
bag.remove("drop");
set.remove("drop");
pairs.remove("drop");
let alive := arr[0] ≢ null
	and bag.contains(owner)
	and set.contains(owner)
	and pairs{"owner"} ≢ null;
owner := null;
alive
	and arr[0] ≡ null
	and bag.contains(null)
	and set.contains(null)
	and pairs{"owner"} ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'direct weak assignments keep collection metadata';
class Box {}
let owner := new Box();
let arr := [ "drop" ];
let pairs := new PairList();
arr[1] := owner but weak;
pairs.add( "drop", "drop" );
pairs{"owner"} := owner but weak;
arr.remove( fn x -> x == "drop" );
pairs.remove("drop");
let alive := arr[0] ≢ null and pairs{"owner"} ≢ null;
owner := null;
alive and arr[0] ≡ null and pairs{"owner"} ≡ null;
SRC

is eval_src(<<'SRC'), 1, 'direct strong assignment clears weak metadata';
class Box {
	let label with get;
}
let weak_owner := new Box( label: "weak" );
let arr := [ "drop" ];
arr.push_weak(weak_owner);
let strong_owner := new Box( label: "strong" );
arr[1] := strong_owner;
weak_owner := null;
strong_owner := null;
arr.remove( fn x -> x == "drop" );
arr[0].get_label() eq "strong";
SRC

done_testing;
