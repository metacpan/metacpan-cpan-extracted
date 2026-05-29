use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'collections.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 5, 'array push and index assignment work';
let arr := [ 1, 2 ];
arr.push(3);
arr[1] := 5;
arr[1];
SRC

is eval_src(<<'SRC'), 9, 'array slices can be assigned';
let arr := [ 1, 2, 3, 4 ];
arr[1:2] := [ 9, 8, 7 ];
arr[1];
SRC

is eval_src(<<'SRC'), 3, 'slice expression returns new array';
let arr := [ 3, 4, 5 ];
let head := arr[0:1];
head[0];
SRC

is eval_src(<<'SRC'), 5, 'array range literal expands ascending';
let arr := [ 1...5 ];
arr.length();
SRC

is eval_src(<<'SRC'), 7, 'array range literal is inclusive';
let arr := [ 7...7 ];
arr[0];
SRC

is eval_src(<<'SRC'), 3, 'array range literal supports descending bounds';
let arr := [ 5...1 ];
arr[2];
SRC

is eval_src(<<'SRC'), 11, 'dict assignment and access work';
let d := { foo: 1 };
d{foo} := 11;
d{"foo"};
SRC

is eval_src(<<'SRC'), 3, 'set literal parses and evaluates';
let s := << 1, 2, 2, 3 >>;
s.length();
SRC

is eval_src(<<'SRC'), 3, 'set deduplicates and supports add/push';
let s := « 1, 1, 2 »;
s.push( 2, 3 );
s.length();
SRC

is eval_src(<<'SRC'), 5, 'set literal range expands and deduplicates';
let s := << 1...5, 3...1 >>;
s.length();
SRC

is eval_src(<<'SRC'), 1, 'empty set literal is supported';
let s := ∅;
s.empty();
SRC

is eval_src(<<'SRC'), 2, 'bag conversion exists from array';
let b := [ 1, 2, 2 ].to_Bag();
b.remove(2);
b.length();
SRC

is eval_src(<<'SRC'), 3, 'bag keeps duplicates';
let b := [ 1, 2, 2 ].to_Bag();
b.length();
SRC

is eval_src(<<'SRC'), 6, 'bag literal range expands including descending';
let b := <<< 1...3, 3...1 >>>;
b.length();
SRC

is eval_src(<<'SRC'), 0, 'dict helpers work';
let d := { foo: 1, bar: 2 };
d.remove("foo");
d.clear();
d.length();
SRC

done_testing;
