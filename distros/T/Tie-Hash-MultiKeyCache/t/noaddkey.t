
# noaddlkey.t

BEGIN { $| = 1; print "1..7\n"; }
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
	ADDKEY	=> 0,
	DELKEY	=> 1;

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

# test 6	add key	to a,b,c	no cache update
$exp = q|54	= bless([{
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

# test 7	delete key from a,b,c,d - should have cache update
$exp = q|52	= bless([{
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
			'0'	=> 3,
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

