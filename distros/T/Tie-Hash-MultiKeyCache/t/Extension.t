
# Extension.t

BEGIN { $| = 1; print "1..40\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Data::Dumper::Sorted;

$package = 'Tie::Hash::MultiKeyCache';
eval "require $package";

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

my $dd = new Data::Dumper::Sorted;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my %h;

# test 2	check accessor
my $csize = 10;
my $th = tie %h, $package, SIZE => $csize;

my $exp = q|24	= bless([{
	},
{
	},
{
	},
0,0,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 1,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
my $got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3	recheck accessor
$th = tied %h;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 4	store value set
$exp = q|33	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'c'	=> 0,
	},
{
		'0'	=> 'store1',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
	},
1,3,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 2,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{qw(a b c)} = 'store1';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 5	store value set 2
$exp = q|52	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'over'	=> 1,
		'quick'	=> 1,
		'the'	=> 1,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
	},
2,12,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 3,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 2,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{[qw(the quick brown fox jumped over the lazy dog)]} = 'store2';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 6	store value set 3
$exp = q|59	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'over'	=> 1,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
	},
3,14,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 4,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 2,
			'2'	=> 3,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{qw( x y )} = 'store3';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 7	store value set 4
$exp = q|74	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
4,20,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 5,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 2,
			'2'	=> 3,
			'3'	=> 4,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{qw(in memory of neel and prey)} = 'store4';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 8	fetch a value
$exp = q|74	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
4,20,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 6,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 5,
			'2'	=> 3,
			'3'	=> 4,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $h{'fox'};
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

############## plan, add several more keysets or individual keys, delete @{$h}{@keys} and  delete $h[@keys] to track effect

# test 9	add several more key sets
$exp = q|99	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lady'	=> 5,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		'the'	=> 1,
		'two'	=> 4,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 9,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 5,
			'2'	=> 3,
			'3'	=> 4,
			'4'	=> 6,
			'5'	=> 7,
			'6'	=> 8,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{['one','two']} = 'store5';
$h{[qw(fat lady sings)]} = 'store6';
$h{[qw( q r s )]} = 'store7';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 10	# try to lock non-existent key
print "did not return 'false' for bogus lock\nnot "
	if $th->lock('not-there');
&ok;

# test 11	check unchanged object
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 12	lock oldest key
print "lock failed\nnot "
	unless $th->lock('b');
&ok;

# test 13	check object
$exp = q|99	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lady'	=> 5,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		'the'	=> 1,
		'two'	=> 4,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 9,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 5,
			'2'	=> 3,
			'3'	=> 4,
			'4'	=> 6,
			'5'	=> 7,
			'6'	=> 8,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 14	add 3 more items to max out cache size
$exp = q|120	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'lady'	=> 5,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		't'	=> 7,
		'the'	=> 1,
		'two'	=> 4,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
10,34,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 12,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 5,
			'2'	=> 3,
			'3'	=> 4,
			'4'	=> 6,
			'5'	=> 7,
			'6'	=> 8,
			'7'	=> 9,
			'8'	=> 10,
			'9'	=> 11,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{qw(t u)} = 't and u';
$h{qw(v w)} = 'v and w';
$h{qw( last item )} = 'tis the last';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 15	add one to push oldest item off the cache
$exp = q|118	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'lady'	=> 5,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		't'	=> 7,
		'the'	=> 1,
		'two'	=> 4,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 13,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 5,
			'10'	=> 12,
			'3'	=> 4,
			'4'	=> 6,
			'5'	=> 7,
			'6'	=> 8,
			'7'	=> 9,
			'8'	=> 10,
			'9'	=> 11,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{end} = 'push off index 2';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 16	lock 'one'
print "failed to lock 'one'\nnot "
	unless $th->lock('one');
&ok;

# test 17	unlock 'a'
print "failed to unlock 'a'\nnot "
	unless $th->unlock('a');
&ok;

# test 18
$exp = q|118	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'lady'	=> 5,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		't'	=> 7,
		'the'	=> 1,
		'two'	=> 4,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 14,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 13,
			'1'	=> 5,
			'10'	=> 12,
			'3'	=> 4,
			'4'	=> 0,
			'5'	=> 7,
			'6'	=> 8,
			'7'	=> 9,
			'8'	=> 10,
			'9'	=> 11,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 19	test delete @keys
$exp = q|102	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 14,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 13,
			'1'	=> 5,
			'10'	=> 12,
			'3'	=> 4,
			'6'	=> 8,
			'7'	=> 9,
			'8'	=> 10,
			'9'	=> 11,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
delete $h{'fat','two'};
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 20	lock vi 7, t & u
$exp = q|102	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 14,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 13,
			'1'	=> 5,
			'10'	=> 12,
			'3'	=> 4,
			'6'	=> 8,
			'7'	=> 0,
			'8'	=> 10,
			'9'	=> 11,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->lock('u');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 21	test iteration touches each key in order, but not vi 7
$exp = q|102	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 39,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 19,
			'1'	=> 38,
			'10'	=> 32,
			'3'	=> 34,
			'6'	=> 31,
			'7'	=> 0,
			'8'	=> 36,
			'9'	=> 35,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
while (my($k,$v) = each %h) {
  ;
}
$got = $dd->DumperA($th);
if ($got eq $exp) {
  &ok;
} else {	# skip for cross platform re-arrangement of keys
  print "ok $test	# skipped\n";
  $test++
}

# test 22	re-syncronize cache age
$exp = q|102	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 64,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 43,
			'1'	=> 61,
			'10'	=> 45,
			'3'	=> 56,
			'6'	=> 60,
			'7'	=> 0,
			'8'	=> 63,
			'9'	=> 50,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
foreach(sort keys %h) {
  my $x = $h{$_};
}
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 23	lock vi 0,3,8	a,and,v
$exp = q|102	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'end'	=> 10,
		'fox'	=> 1,
		'in'	=> 3,
		'item'	=> 9,
		'jumped'	=> 1,
		'last'	=> 9,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'10'	=> 'push off index 2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
		'9'	=> 'tis the last',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'10'	=> {
			'end'	=> 34,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
		'9'	=> {
			'item'	=> 33,
			'last'	=> 32,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 64,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 61,
			'10'	=> 45,
			'3'	=> 0,
			'6'	=> 60,
			'7'	=> 0,
			'8'	=> 0,
			'9'	=> 50,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->lock('a');
$th->lock('and');
$th->lock('v');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 24	reduce cache size and flush
$exp = $csize;
$csize = 6;
$got = $th->newSize($csize);
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

# test 25	validate object
$exp = q|90	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		't'	=> 7,
		'the'	=> 1,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'3'	=> 'store4',
		'6'	=> 'store7',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 64,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 6,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 61,
			'3'	=> 0,
			'6'	=> 60,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 26	reduce cache size and flush, should leave locked items in cache
$exp = $csize;
$csize = 3;
$got = $th->newSize($csize);
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

# test 27	validate object
$exp = q|62	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
	},
11,35,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 64,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 3,
		'STACK'	=> {
			'0'	=> 0,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 28	reduce cache size and flush
$exp = $csize;
$csize = 8;
$got = $th->newSize($csize);
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

# test 29	fill cache
$h{g} = 'add g';
$h{h} = 'add h';
$h{j} = 'add j';
$h{k} = 'add k';

# 	validate object
$exp = q|82	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 11,
		'h'	=> 12,
		'in'	=> 3,
		'j'	=> 13,
		'k'	=> 14,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
	},
{
		'0'	=> 'store1',
		'11'	=> 'add g',
		'12'	=> 'add h',
		'13'	=> 'add j',
		'14'	=> 'add k',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'11'	=> {
			'g'	=> 35,
		},
		'12'	=> {
			'h'	=> 36,
		},
		'13'	=> {
			'j'	=> 37,
		},
		'14'	=> {
			'k'	=> 38,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
		},
	},
15,39,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 68,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'11'	=> 64,
			'12'	=> 65,
			'13'	=> 66,
			'14'	=> 67,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

########### copy next

# test 30	check copy matches original
my %new;
tie %new, $package, SIZE => $csize;
my $thy = $th->copy(\%new);
my $gself = $dd->DumperA($th);
my $gcopy = $dd->DumperA($thy);
print "COPY does not match ORIGINAL\n$gcopy\n$gself\nnot "
	unless $gself eq $gcopy;
&ok;

# test 31	check copy contents
my $cexp = $exp;
print "got: $gcopy\nexp: $cexp\nnot "
	unless $gcopy eq $cexp;
&ok;

# test 32	add key to locked cell
$exp = q|86	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 11,
		'h'	=> 12,
		'in'	=> 3,
		'j'	=> 13,
		'k'	=> 14,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'w'	=> 8,
		'x'	=> 8,
		'z'	=> 8,
	},
{
		'0'	=> 'store1',
		'11'	=> 'add g',
		'12'	=> 'add h',
		'13'	=> 'add j',
		'14'	=> 'add k',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'11'	=> {
			'g'	=> 35,
		},
		'12'	=> {
			'h'	=> 36,
		},
		'13'	=> {
			'j'	=> 37,
		},
		'14'	=> {
			'k'	=> 38,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'w'	=> 31,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
15,41,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 68,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'11'	=> 64,
			'12'	=> 65,
			'13'	=> 66,
			'14'	=> 67,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->addkey([qw(x z)] => 'w');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 33	delete key from locked cell
$exp = q|84	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 11,
		'h'	=> 12,
		'in'	=> 3,
		'j'	=> 13,
		'k'	=> 14,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'x'	=> 8,
		'z'	=> 8,
	},
{
		'0'	=> 'store1',
		'11'	=> 'add g',
		'12'	=> 'add h',
		'13'	=> 'add j',
		'14'	=> 'add k',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'11'	=> {
			'g'	=> 35,
		},
		'12'	=> {
			'h'	=> 36,
		},
		'13'	=> {
			'j'	=> 37,
		},
		'14'	=> {
			'k'	=> 38,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
15,41,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 68,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'11'	=> 64,
			'12'	=> 65,
			'13'	=> 66,
			'14'	=> 67,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->delkey('w');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 34	add key to regular cell
$exp = q|86	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 11,
		'h'	=> 12,
		'i'	=> 13,
		'in'	=> 3,
		'j'	=> 13,
		'k'	=> 14,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'x'	=> 8,
		'z'	=> 8,
	},
{
		'0'	=> 'store1',
		'11'	=> 'add g',
		'12'	=> 'add h',
		'13'	=> 'add j',
		'14'	=> 'add k',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'11'	=> {
			'g'	=> 35,
		},
		'12'	=> {
			'h'	=> 36,
		},
		'13'	=> {
			'i'	=> 41,
			'j'	=> 37,
		},
		'14'	=> {
			'k'	=> 38,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
15,42,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 69,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'11'	=> 64,
			'12'	=> 65,
			'13'	=> 68,
			'14'	=> 67,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->addkey('i','j');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 35	delete key from locked cell
$exp = q|84	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 11,
		'h'	=> 12,
		'i'	=> 13,
		'in'	=> 3,
		'k'	=> 14,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		't'	=> 7,
		'u'	=> 7,
		'v'	=> 8,
		'x'	=> 8,
		'z'	=> 8,
	},
{
		'0'	=> 'store1',
		'11'	=> 'add g',
		'12'	=> 'add h',
		'13'	=> 'add j',
		'14'	=> 'add k',
		'3'	=> 'store4',
		'7'	=> 't and u',
		'8'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'11'	=> {
			'g'	=> 35,
		},
		'12'	=> {
			'h'	=> 36,
		},
		'13'	=> {
			'i'	=> 41,
		},
		'14'	=> {
			'k'	=> 38,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'7'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'8'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
15,42,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 70,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'11'	=> 64,
			'12'	=> 65,
			'13'	=> 69,
			'14'	=> 67,
			'3'	=> 0,
			'7'	=> 0,
			'8'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->delkey('j');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 36	reorder vals
$exp = q|84	= bless([{
		'a'	=> 0,
		'and'	=> 5,
		'b'	=> 0,
		'c'	=> 0,
		'g'	=> 1,
		'h'	=> 2,
		'i'	=> 3,
		'in'	=> 5,
		'k'	=> 4,
		'memory'	=> 5,
		'neel'	=> 5,
		'of'	=> 5,
		'prey'	=> 5,
		't'	=> 6,
		'u'	=> 6,
		'v'	=> 7,
		'x'	=> 7,
		'z'	=> 7,
	},
{
		'0'	=> 'store1',
		'1'	=> 'add g',
		'2'	=> 'add h',
		'3'	=> 'add j',
		'4'	=> 'add k',
		'5'	=> 'store4',
		'6'	=> 't and u',
		'7'	=> 'v and w',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'g'	=> 35,
		},
		'2'	=> {
			'h'	=> 36,
		},
		'3'	=> {
			'i'	=> 41,
		},
		'4'	=> {
			'k'	=> 38,
		},
		'5'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'7'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
8,42,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 70,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'1'	=> 64,
			'2'	=> 65,
			'3'	=> 69,
			'4'	=> 67,
			'5'	=> 0,
			'6'	=> 0,
			'7'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->_rordvals;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 37	set up for consolidation test
$exp = q|86	= bless([{
		'a'	=> 0,
		'and'	=> 5,
		'b'	=> 0,
		'c'	=> 0,
		'hjk'	=> 9,
		'i'	=> 3,
		'in'	=> 5,
		'kjh'	=> 10,
		'memory'	=> 5,
		'neel'	=> 5,
		'not'	=> 8,
		'of'	=> 5,
		'prey'	=> 5,
		'store4'	=> 8,
		't'	=> 6,
		'u'	=> 6,
		'v'	=> 7,
		'x'	=> 7,
		'z'	=> 7,
	},
{
		'0'	=> 'store1',
		'10'	=> 'add j',
		'3'	=> 'add j',
		'5'	=> 'store4',
		'6'	=> 't and u',
		'7'	=> 'v and w',
		'8'	=> 'store4',
		'9'	=> 'add j',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'10'	=> {
			'kjh'	=> 45,
		},
		'3'	=> {
			'i'	=> 41,
		},
		'5'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'7'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
		'8'	=> {
			'not'	=> 42,
			'store4'	=> 43,
		},
		'9'	=> {
			'hjk'	=> 44,
		},
	},
11,46,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 73,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 0,
			'10'	=> 72,
			'3'	=> 69,
			'5'	=> 0,
			'6'	=> 0,
			'7'	=> 0,
			'8'	=> 70,
			'9'	=> 71,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{qw( not store4 )} = 'store4';
$h{'hjk'} = 'add j';
$h{'kjh'} = 'add j';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 38	consolidate
$exp = q|77	= bless([{
		'a'	=> 1,
		'and'	=> 2,
		'b'	=> 1,
		'c'	=> 1,
		'hjk'	=> 0,
		'i'	=> 0,
		'in'	=> 2,
		'kjh'	=> 0,
		'memory'	=> 2,
		'neel'	=> 2,
		'not'	=> 2,
		'of'	=> 2,
		'prey'	=> 2,
		'store4'	=> 2,
		't'	=> 3,
		'u'	=> 3,
		'v'	=> 4,
		'x'	=> 4,
		'z'	=> 4,
	},
{
		'0'	=> 'add j',
		'1'	=> 'store1',
		'2'	=> 'store4',
		'3'	=> 't and u',
		'4'	=> 'v and w',
	},
{
		'0'	=> {
			'hjk'	=> 44,
			'i'	=> 41,
			'kjh'	=> 45,
		},
		'1'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'2'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'not'	=> 42,
			'of'	=> 16,
			'prey'	=> 19,
			'store4'	=> 43,
		},
		'3'	=> {
			't'	=> 28,
			'u'	=> 29,
		},
		'4'	=> {
			'v'	=> 30,
			'x'	=> 39,
			'z'	=> 40,
		},
	},
5,46,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 73,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
			'0'	=> 72,
			'1'	=> 0,
			'2'	=> 0,
			'3'	=> 0,
			'4'	=> 0,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$th->consolidate;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 39	clear
$exp = q|24	= bless([{
	},
{
	},
{
	},
0,0,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 1,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 8,
		'STACK'	=> {
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
%h = ();
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 40	verify that copied hash is untouched
$got = $dd->DumperA($thy);
print "got: $got\nexp: $cexp\nnot "
	unless $got eq $cexp;
&ok;

