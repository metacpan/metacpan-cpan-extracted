
# fifo.t

BEGIN { $| = 1; print "1..9\n"; }
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
my $th = tie %h, $package,
	SIZE	=> $csize,
	FIFO	=> 1;

my $exp = q|25	= bless([{
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
		'FIFO'	=> 1,
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
$exp = q|34	= bless([{
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
		'FIFO'	=> 1,
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
$exp = q|53	= bless([{
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
		'FIFO'	=> 1,
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

# test 6	add key	to a,b,c	should have cache update
$exp = q|55	= bless([{
		'a'	=> 0,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'd'	=> 0,
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
			'd'	=> 12,
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
2,13,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 3,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'FIFO'	=> 1,
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
$th->addkey('d','b');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 7	delete key from a,b,c,d - should not have cache update
$exp = q|53	= bless([{
		'a'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'd'	=> 0,
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
			'c'	=> 2,
			'd'	=> 12,
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
2,13,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 3,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'FIFO'	=> 1,
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
$th->delkey('b');
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 8	fill the cache
$exp = q|93	= bless([{
		'a'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'd'	=> 0,
		'dog'	=> 1,
		'eight'	=> 7,
		'five'	=> 4,
		'four'	=> 3,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'nine'	=> 8,
		'over'	=> 1,
		'quick'	=> 1,
		'seven'	=> 6,
		'six'	=> 5,
		'ten'	=> 9,
		'the'	=> 1,
		'three'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'three value',
		'3'	=> 'four value',
		'4'	=> 'five value',
		'5'	=> 'six value',
		'6'	=> 'seven value',
		'7'	=> 'eight value',
		'8'	=> 'nine value',
		'9'	=> 'ten value',
	},
{
		'0'	=> {
			'a'	=> 0,
			'c'	=> 2,
			'd'	=> 12,
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
			'three'	=> 13,
		},
		'3'	=> {
			'four'	=> 14,
		},
		'4'	=> {
			'five'	=> 15,
		},
		'5'	=> {
			'six'	=> 16,
		},
		'6'	=> {
			'seven'	=> 17,
		},
		'7'	=> {
			'eight'	=> 18,
		},
		'8'	=> {
			'nine'	=> 19,
		},
		'9'	=> {
			'ten'	=> 20,
		},
	},
10,21,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 11,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'FIFO'	=> 1,
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'0'	=> 1,
			'1'	=> 2,
			'2'	=> 3,
			'3'	=> 4,
			'4'	=> 5,
			'5'	=> 6,
			'6'	=> 7,
			'7'	=> 8,
			'8'	=> 9,
			'9'	=> 10,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
foreach (qw( three four five six seven eight nine ten )) {
  $h{$_} = $_ .' value';
}
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 9	push off the first item
$exp = q|89	= bless([{
		'brown'	=> 1,
		'dog'	=> 1,
		'eight'	=> 7,
		'five'	=> 4,
		'four'	=> 3,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'nine'	=> 8,
		'over'	=> 1,
		'pushit'	=> 10,
		'quick'	=> 1,
		'seven'	=> 6,
		'six'	=> 5,
		'ten'	=> 9,
		'the'	=> 1,
		'three'	=> 2,
	},
{
		'1'	=> 'store2',
		'10'	=> 'eleventh item',
		'2'	=> 'three value',
		'3'	=> 'four value',
		'4'	=> 'five value',
		'5'	=> 'six value',
		'6'	=> 'seven value',
		'7'	=> 'eight value',
		'8'	=> 'nine value',
		'9'	=> 'ten value',
	},
{
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
			'pushit'	=> 21,
		},
		'2'	=> {
			'three'	=> 13,
		},
		'3'	=> {
			'four'	=> 14,
		},
		'4'	=> {
			'five'	=> 15,
		},
		'5'	=> {
			'six'	=> 16,
		},
		'6'	=> {
			'seven'	=> 17,
		},
		'7'	=> {
			'eight'	=> 18,
		},
		'8'	=> {
			'nine'	=> 19,
		},
		'9'	=> {
			'ten'	=> 20,
		},
	},
11,22,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'AI'	=> 12,
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'FIFO'	=> 1,
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'SIZE'	=> 10,
		'STACK'	=> {
			'1'	=> 2,
			'10'	=> 11,
			'2'	=> 3,
			'3'	=> 4,
			'4'	=> 5,
			'5'	=> 6,
			'6'	=> 7,
			'7'	=> 8,
			'8'	=> 9,
			'9'	=> 10,
		},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKeyCache');
|;
$h{pushit} = 'eleventh item';
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

