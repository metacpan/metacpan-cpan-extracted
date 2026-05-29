use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'collections-advanced.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 6, 'array map works';
let arr := [ 1, 2, 3 ];
let doubled := arr.map( fn x -> x * 2 );
doubled[2];
SRC

is eval_src(<<'SRC'), 2, 'array grep keeps matching members';
let arr := [ 1, 2, 3, 4 ];
let even := arr.grep( fn x -> x mod 2 = 0 );
even.length();
SRC

is eval_src(<<'SRC'), 1, 'array any works';
let arr := [ 1, 2, 3 ];
arr.any( fn x -> x = 2 );
SRC

is eval_src(<<'SRC'), 1, 'array all works';
let arr := [ 2, 4, 6 ];
arr.all( fn x -> x mod 2 = 0 );
SRC

is eval_src(<<'SRC'), 8, 'array first returns first match';
let arr := [ 1, 8, 10 ];
arr.first( fn x -> x > 5 );
SRC

is eval_src(<<'SRC'), 2, 'array remove with predicate mutates array';
let arr := [ 1, 2, 3, 4 ];
arr.remove( fn x -> x mod 2 = 0 );
arr.length();
SRC

is eval_src(<<'SRC'), 3, 'dict keys returns set';
let d := { a: 1, b: 2, c: 3 };
let k := d.keys();
k.length();
SRC

is eval_src(<<'SRC'), 3, 'dict values returns bag';
let d := { a: 1, b: 2, c: 3 };
let v := d.values();
v.length();
SRC

is eval_src(<<'SRC'), 2, 'dict add supports key and value arguments';
let d := { a: 1 };
d.add( "b", 2 );
d.length();
SRC

is eval_src(<<'SRC'), 2, 'set map and set uniqueness are preserved';
let s := << 1, 2, 3 >>;
let t := s.map( fn x -> x mod 2 );
t.length();
SRC

is eval_src(<<'SRC'), 2, 'bag remove_first only removes one item';
let b := [ 1, 2, 2 ].to_Bag();
b.remove_first( 2 );
b.length();
SRC

is eval_src(<<'SRC'), 5, 'set union and intersection operators work';
let a := << 1, 2, 3 >>;
let b := << 3, 4 >>;
let u := a union b;
let i := a intersection b;
u.length() + i.length();
SRC

is eval_src(<<'SRC'), 1, 'set subset and superset operators work';
let a := << 1, 2 >>;
let b := << 1, 2, 3 >>;
(a subsetof b) and (b supersetof a);
SRC

is eval_src(<<'SRC'), 1, 'set equivalent and difference operators work';
let a := << 1, 2, 3 >>;
let b := << 3, 2, 1 >>;
let c := a \ << 3 >>;
(a equivalentof b) and (c.length() = 2);
SRC

is eval_src(<<'SRC'), 1, 'in works for sets and dict keys';
let s := << 1, 2, 3 >>;
let d := { foo: 10 };
(2 in s) and ((4 in s) = 0) and ("foo" in d);
SRC

is eval_src(<<'SRC'), 0, 'in uses type-aware equality for set members';
let s := << 1, 2, 3 >>;
"1" in s;
SRC

is eval_src(<<'SRC'), 1, 'dict keys can use keyword shorthand and be read back';
let d := { in: 7, while: 9 };
( d{in} = 7 ) and ( d{"while"} = 9 );
SRC

is eval_src(<<'SRC'), 1, 'dict has and get helpers work';
let d := { alpha: 1 };
( d.has("alpha") ) and ( d.get("beta", 3) = 3 );
SRC

is eval_src(<<'SRC'), 3, 'set to_Array and contains helpers work';
let s := << 1, 2, 3 >>;
let arr := s.to_Array();
arr.contains(2) and arr.length();
SRC

is eval_src(<<'SRC'), 0, 'array contains uses type-aware equality';
let arr := [ 1, 2, 3 ];
arr.contains( "1" );
SRC

is eval_src(<<'SRC'), 1, 'bag literal parses and supports contains';
let b := <<< 1, 1, 2 >>>;
b.contains(2);
SRC

is eval_src(<<'SRC'), 2, 'bag to_Set removes duplicates';
let b := <<< 1, 1, 2 >>>;
let s := b.to_Set();
s.length();
SRC

is eval_src(<<'SRC'), 3, 'set.remove uses type-aware equality';
let s := << 1, 2, 3 >>;
s.remove( "1" );
s.length();
SRC

is eval_src(<<'SRC'), 3, 'bag.remove uses type-aware equality';
let b := <<< 1, 2, 3 >>>;
b.remove( "1" );
b.length();
SRC

is eval_src(<<'SRC'), 2, 'array sort uses custom callback and returns array';
let arr := [ 2, 1, 3 ];
let out := arr.sort( function (a, b) { return b <=> a; } );
out[1];
SRC

is eval_src(<<'SRC'), 2, 'set sort returns array';
let s := << 2, 1, 3 >>;
let out := s.sort( function (a, b) { return b <=> a; } );
out[1];
SRC

is eval_src(<<'SRC'), 2, 'bag sort returns array';
let b := <<< 2, 1, 3 >>>;
let out := b.sort( function (a, b) { return b <=> a; } );
out[1];
SRC

is eval_src(<<'SRC'), "10", 'sortstr sorts by string value';
let out := [ 2, 10, 1 ].sortstr();
out[1];
SRC

is eval_src(<<'SRC'), 2, 'sortnum sorts numerically';
let out := [ "10", "2", "1" ].sortnum();
out[1];
SRC

is eval_src(<<'SRC'), 3, 'array reverse returns reversed array';
let out := [ 1, 2, 3 ].reverse();
out[0];
SRC

is eval_src(<<'SRC'), 9, 'array get and set helpers work';
let arr := [ 1, 2, 3 ];
arr.set( 1, 9 );
arr.get( 1, 0 );
SRC

is eval_src(<<'SRC'), 14, 'array reduce and reductions helpers work';
let arr := [ 1, 2, 4 ];
let total := arr.reduce(
	function (a, b) {
		return a + b;
	}
);
let running := arr.reductions(
	function (a, b) {
		return a + b;
	}
);
total + running[2];
SRC

is eval_src(<<'SRC'), 1, 'array for_each_value visits members';
let arr := [ 1, 2, 3 ];
let total := 0;
arr.for_each_value(
	fn x -> total := total + x
);
total = 6;
SRC

is eval_src(<<'SRC'), 2, 'bag count and uniq helpers work';
let b := <<< 1, 1, 2 >>>;
b.count( 1 ) + b.uniq().length() - 2;
SRC

is eval_src(<<'SRC'), 1, 'bag for_each_value visits members';
let b := <<< 2, 3 >>>;
let total := 0;
b.for_each_value(
	fn x -> total := total + x
);
total = 5;
SRC

is eval_src(<<'SRC'), 1, 'set relation and operation methods work';
let a := << 1, 2, 3 >>;
let b := << 2, 3, 4 >>;
let i := a.intersection( b );
let u := a.union( b );
let d := a.difference( b );
let s := a.symmetric_difference( b );
( a.is_subset( u ) )
	and ( u.is_superset( a ) )
	and ( a.is_disjoint( << 8 >> ) )
	and ( i.equals( << 2, 3 >> ) )
	and ( d.length() = 1 )
	and ( s.length() = 2 );
SRC

is eval_src(<<'SRC'), 1, 'set for_each_value visits members';
let s := << 1, 2, 3 >>;
let total := 0;
s.for_each_value(
	fn x -> total := total + x
);
total = 6;
SRC

is eval_src(<<'SRC'), 1, 'dict exists, defined, set, kv, sorted_keys, and for_each helpers work';
let d := { b: 2, a: 1, n: null };
d.set( "c", 3 );
let key_total := "";
let val_total := 0;
let pair_count := 0;
d.for_each_key(
	fn k -> key_total := key_total _ k
);
d.for_each_value(
	fn v -> val_total := val_total + ( v != null ? v : 0 )
);
d.for_each_pair(
	fn p -> pair_count := pair_count + 1
);
( d.exists("a") )
	and ( d.defined("a") )
	and ( ( d.defined("n") ) = 0 )
	and ( d.sorted_keys().length() = 4 )
	and ( d.kv().length() = 8 )
	and ( length key_total = 4 )
	and ( val_total = 6 )
	and ( pair_count = 4 );
SRC

is eval_src(<<'SRC'), 1, 'pairlist literal keeps duplicate keys and get returns first value';
let pl := {{ foo: 1, foo: 2, bar: 3 }};
( pl{foo} = 1 ) and ( pl.length() = 3 );
SRC

is eval_src(<<'SRC'), 1, 'pairlist assignment appends instead of replacing';
let pl := {{ foo: 1, foo: 2 }};
pl{foo} := 99;
let vals := pl.get_all( "foo" );
( vals.length() = 3 ) and ( vals[2] = 99 );
SRC

is eval_src(<<'SRC'), 1, 'pairlist constructor accepts list of Pair values';
let p1 := new Pair( pair: [ "foo", 10 ] );
let p2 := new Pair( pair: [ "foo", 20 ] );
let p3 := new Pair( pair: [ "bar", 30 ] );
let pl := new PairList( list: [ p1, p2, p3 ] );
( pl{foo} = 10 ) and ( pl.values()[1] = 20 );
SRC

is eval_src(<<'SRC'), 1, 'dict to_Array returns Pair objects';
let d := { foo: 1 };
let pairs := d.to_Array();
( pairs[0] instanceof Pair ) and ( pairs[0].key() eq "foo" );
SRC

is eval_src(<<'SRC'), 1, 'pairlist to_Array and callbacks use Pair objects';
let pl := {{ foo: 1, bar: 2 }};
let pairs := pl.to_Array();
let ok_to_array := ( pairs[1] instanceof Pair ) and ( pairs[1].value() = 2 );
let seen := "";
pl.for_each_pair(
	fn p -> seen := seen _ p.key() _ ","
);
ok_to_array and ( seen eq "foo,bar," );
SRC

done_testing;
