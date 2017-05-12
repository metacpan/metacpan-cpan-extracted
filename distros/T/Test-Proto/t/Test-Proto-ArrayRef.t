#!perl -T
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Indent = 1; # prevent them getting out of hand.
use Test::More;
use Test::Proto::ArrayRef;

ok (1, 'ok is ok');

sub is_a_good_pass {
	# Todo: test this more
	ok($_[0]?1:0, , $_[1]) or diag Dumper $_[0];
}

sub is_a_good_fail {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]) or diag Dumper $_[0];
	ok(!$_[0]->is_exception, '... and not be an exception') or diag Dumper $_[0];
}

sub is_a_good_exception {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]);
	ok($_[0]->is_exception, '... and be an exception');
}


sub p { Test::Proto::Base->new(); }
sub pAr { Test::Proto::ArrayRef->new(); }

# nth
is_a_good_pass(pAr->nth(1, 'b')->validate(['a','b']), "nth: item 1 of ['a','b'] is 'b'");
is_a_good_fail(pAr->nth(1, 'a')->validate(['a','b']), "nth: item 1 of ['a','b'] is not 'a'");
is_a_good_fail(pAr->nth(2, 'b')->validate(['a','b']), "item 2 of ['a','b'] does not exist"); #~ it should fail with an out of bounds message, not be an exception

# map
is_a_good_pass(pAr->map(sub {uc shift;}, ['A','B'])->validate(['a','b']), "map passes with a transform");
is_a_good_pass(pAr->map(sub {shift;}, ['a','b'])->validate(['a','b']), "map passes with no transform");
is_a_good_fail(pAr->map(sub {uc shift;}, ['a','b'])->validate(['a','b']), "map fails when expected does not match");

# grep
is_a_good_pass(pAr->grep(sub {$_[0] eq uc $_[0]}, ['A'])->validate(['A','b']), "grep passes");
is_a_good_pass(pAr->grep(sub {$_[0] eq uc $_[0]}, [])->validate(['a','b']), "grep passes when nothing matches");
is_a_good_fail(pAr->grep(sub {$_[0] eq uc $_[0]}, ['a','b'])->validate(['A','b']), "grep fails when expected does not match");

# indexes_of
is_a_good_pass(pAr->indexes_of(sub {$_[0] eq uc $_[0]}, [0,2])->validate(['A','b', 'C']), "indexes_of passes");
is_a_good_pass(pAr->indexes_of(sub {$_[0] eq uc $_[0]}, [])->validate(['a','b']), "indexes_of passes when nothing matches");
is_a_good_fail(pAr->indexes_of(sub {$_[0] eq uc $_[0]}, [0,2])->validate(['A','b']), "indexes_of fails when expected does not match");


# grep (1 arg form)
is_a_good_pass(pAr->grep(sub {$_[0] eq uc $_[0]})->validate(['A','b']), "boolean grep passes when something matches");
is_a_good_fail(pAr->grep(sub {$_[0] eq uc $_[0]})->validate(['a','b']), "boolean grep fails when nothing matches");

# grep (1 arg form with expected)
is_a_good_pass(pAr->grep(sub {$_[0] eq uc $_[0]}, 'because')->validate(['A','b']), "boolean grep (w/reason) passes when something matches");
is_a_good_fail(pAr->grep(sub {$_[0] eq uc $_[0]}, 'because')->validate(['a','b']), "boolean grep (w/reason) fails when nothing matches");

# array_any
is_a_good_pass(pAr->array_any(sub {$_[0] eq uc $_[0]})->validate(['A','b']), "array_any passes when something matches");
is_a_good_fail(pAr->array_any(sub {$_[0] eq uc $_[0]})->validate(['a','b']), "array_any fails when nothing matches");

# array_none
is_a_good_pass(pAr->array_none(sub {$_[0] eq uc $_[0]})->validate(['a','b']), "array_none passes when nothing matches");
is_a_good_fail(pAr->array_none(sub {$_[0] eq uc $_[0]})->validate(['A','b']), "array_none fails when something matches");

# array_all
is_a_good_pass(pAr->array_all(sub {$_[0] eq uc $_[0]})->validate(['A','B']), "array_all passes when everything matches");
is_a_good_fail(pAr->array_all(sub {$_[0] eq uc $_[0]})->validate(['A','b']), "array_all fails when anything does not match");

# reduce
is_a_good_pass(pAr->reduce(sub { $_[0] + $_[1] }, 6 )->validate([1,2,3]), "reduce passes when result matches");
is_a_good_fail(pAr->reduce(sub { $_[0] + $_[1] }, 7 )->validate([1,2,3]), "reduce fails when result does not match");
is_a_good_exception(pAr->reduce(sub { $_[0] + $_[1] }, 7 )->validate([1]), "reduce is exception when subject has less than two members");

# array_eq
is_a_good_pass(pAr->array_eq(['a','b'])->validate(['a','b']), "['a','b'] is ['a','b']");
is_a_good_pass(pAr->array_eq(['a',['b']])->validate(['a',['b']]), "['a',['b']] is ['a',['b']]");
is_a_good_pass(pAr->array_eq([])->validate([]), "[] is  []");
is_a_good_fail(pAr->array_eq(['a','b'])->validate(['a']), "['a'] is not ['a','b']");
is_a_good_fail(pAr->array_eq(['a'])->validate(['a', 'b']), "['a','b'] is not ['a']");
is_a_good_fail(pAr->array_eq(['a','b'])->validate(['b','a']), "['b','a'] is not ['a','b']");

# enumerated
is_a_good_pass(pAr->enumerated([[0,'a'],[1,'b']])->validate(['a','b']), "enumerated passes correctly");
is_a_good_fail(pAr->enumerated([])->validate(['a','b']), "enumerated fails correctly");
is_a_good_pass(pAr->enumerated([])->validate([]), "enumerated passes correctly when empty");
is_a_good_fail(pAr->enumerated([[]])->validate([]), "enumerated fails correctly when empty");

# in_groups
is_a_good_pass(pAr->in_groups(2,[['a','b'],['c','d']])->validate(['a','b','c','d']), "in_groups works");
is_a_good_pass(pAr->in_groups(2,[])->validate([]), "in_groups works with empty list");
is_a_good_pass(pAr->in_groups(1,[['a'],['b'],['c'],['d']])->validate(['a','b','c','d']), "in_groups works with n=1");
is_a_good_pass(pAr->in_groups(2,[['a','b'],['c','d'],['e']])->validate(['a','b','c','d','e']), "in_groups works with remainders");
is_a_good_fail(pAr->in_groups(2,[])->validate(['a','b','c','d']), "in_groups fails when no match");
is_a_good_exception(pAr->in_groups(0,[['a'],['b'],['c'],['d']])->validate(['a','b','c','d']), "in_groups throws exceptions when n<1");

# group_when
is_a_good_pass(pAr->group_when(sub {$_[0] eq uc $_[0]}, [['A'],['B','c','d'],['E']])->validate(['A','B','c','d','E']), "group_when works");
is_a_good_pass(pAr->group_when(sub {$_[0] eq uc $_[0]}, [['a','b','c','d','e']])->validate(['a','b','c','d','e']), "group_when works when it matches nothing");
is_a_good_fail(pAr->group_when(sub {$_[0] eq uc $_[0]}, [['a','e','e','e','e']])->validate(['a','b','c','d','e']), "group_when fails appropriately");

# group_when_index
is_a_good_pass(pAr->group_when_index(p->num_gt(2), [['A','B','c'],['d'],['E']])->validate(['A','B','c','d','E']), "group_when_index works");
is_a_good_pass(pAr->group_when_index(p->num_gt(5), [['a','b','c','d','e']])->validate(['a','b','c','d','e']), "group_when_index works when it matches nothing");
is_a_good_fail(pAr->group_when_index(p->num_gt(2), [['a','e','e','e','e']])->validate(['a','b','c','d','e']), "group_when fails appropriately");

# count_items
is_a_good_pass(pAr->count_items(2)->validate(['a','b']), "count_items 2 on ['a','b'] passes");
is_a_good_fail(pAr->count_items(1)->validate(['a','b']), "count_items 1 on ['a','b'] fails");
is_a_good_pass(pAr->count_items(p->num_lt(5))->validate(['a','b']), "count_items <5 on ['a','b'] passes");
is_a_good_fail(pAr->count_items(p->num_gt(5))->validate(['a','b']), "count_items >5 on ['a','b'] fails");

# range
is_a_good_pass(pAr->range(1, ['b'])->validate(['a','b']), "range: item 1 of ['a','b'] is 'b'");
is_a_good_fail(pAr->range(1, ['a'])->validate(['a','b']), "range: item 1 of ['a','b'] is not 'a'");
is_a_good_fail(pAr->range(2, ['a'])->validate(['a','b']), "range: item 2 of ['a','b'] does not exist");
is_a_good_exception(pAr->range('', ['a'])->validate(['a','b','c','d']), "range: exception if range is empty");
is_a_good_exception(pAr->range('a', ['a'])->validate(['a','b','c','d']), "range: exception if range is not a range");
is_a_good_pass(pAr->range('1,3', ['b','d'])->validate(['a','b','c','d']), "range: comma");
is_a_good_pass(pAr->range('0,1,3', ['a','b','d'])->validate(['a','b','c','d']), "range: multiple commas");
is_a_good_pass(pAr->range('1,1,3', ['b','b','d'])->validate(['a','b','c','d']), "range: repeated elements");
is_a_good_pass(pAr->range('1,-4,-1', ['b','a','d'])->validate(['a','b','c','d']), "range: negative");
is_a_good_pass(pAr->range('0..2', ['a','b','c'])->validate(['a','b','c','d']), "range: .. operator from beginning");
is_a_good_pass(pAr->range('1..3', ['b','c','d'])->validate(['a','b','c','d']), "range: .. operator to end");
is_a_good_pass(pAr->range('1..-1', ['b','c','d'])->validate(['a','b','c','d']), "range: .. operator to -1");
is_a_good_pass(pAr->range('0..1,3', ['a','b','d'])->validate(['a','b','c','d']), "range: .. and comma");
is_a_good_pass(pAr->range('0..1,2..3', ['a','b','c','d'])->validate(['a','b','c','d']), "range: multiple ..");
is_a_good_pass(pAr->range('0..1,1..3', ['a','b','b','c','d'])->validate(['a','b','c','d']), "range: overlapping ..");
is_a_good_pass(pAr->range('0..1,1..-1', ['a','b','b','c','d'])->validate(['a','b','c','d']), "range: overlapping .. with negatives");

# reverse
is_a_good_pass(pAr->reverse([qw (d c b a)])->validate(['a','b','c','d']), "reverse passes when expected matches");
is_a_good_fail(pAr->reverse([qw (a b c d)])->validate(['a','b','c','d']), "reverse fails when expected does not match");

# array_before
is_a_good_pass(pAr->array_before('c', ['a','b'])->validate(['a','b','c','d']), "array_before passes when expected matches");
is_a_good_pass(pAr->array_before('a',[])->validate(['a','b','c','d']), "array_before passes when expected matches and is empty");
is_a_good_fail(pAr->array_before('x',[])->validate(['a','b','c','d']), "array_before fails when match does not match");
is_a_good_fail(pAr->array_before('c',[])->validate(['a','b','c','d']), "array_before fails when expected does not match");

# array_before_inclusive
is_a_good_pass(pAr->array_before_inclusive('c', ['a','b','c'])->validate(['a','b','c','d']), "array_before_inclusive passes when expected matches");
is_a_good_pass(pAr->array_before_inclusive('a',['a'])->validate(['a','b','c','d']), "array_before_inclusive passes when expected matches and is alone");
is_a_good_fail(pAr->array_before_inclusive('x',[])->validate(['a','b','c','d']), "array_before_inclusive fails when match does not match");
is_a_good_fail(pAr->array_before_inclusive('c',[])->validate(['a','b','c','d']), "array_before_inclusive fails when expected does not match");

# array_after
is_a_good_pass(pAr->array_after('b', ['c','d'])->validate(['a','b','c','d']), "array_after passes when expected matches");
is_a_good_pass(pAr->array_after('d',[])->validate(['a','b','c','d']), "array_after passes when expected matches and is empty");
is_a_good_fail(pAr->array_after('x',[])->validate(['a','b','c','d']), "array_after fails when match does not match");
is_a_good_fail(pAr->array_after('c',[])->validate(['a','b','c','d']), "array_after fails when expected does not match");

# array_after
is_a_good_pass(pAr->array_after_inclusive('b', ['b','c','d'])->validate(['a','b','c','d']), "array_after_inclusive passes when expected matches");
is_a_good_pass(pAr->array_after_inclusive('d',['d'])->validate(['a','b','c','d']), "array_after_inclusive passes when expected matches and is alone");
is_a_good_fail(pAr->array_after_inclusive('x',[])->validate(['a','b','c','d']), "array_after_inclusive fails when match does not match");
is_a_good_fail(pAr->array_after_inclusive('c',[])->validate(['a','b','c','d']), "array_after_inclusive fails when expected does not match");

# functions requiring comparison
use Test::Proto::Compare;
my $cmp_rev = Test::Proto::Compare->new()->reverse;
my $cmp_lc = sub {lc shift cmp lc shift};

# sorted
is_a_good_pass(pAr->sorted(['a','c','e'])->validate(['a','e','c']), "sorted passes correctly");
is_a_good_fail(pAr->sorted(['a','e','c'])->validate(['a','e','c']), "sorted fails correctly");
is_a_good_pass(pAr->sorted([])->validate([]), "sorted passes correctly on empty array");

is_a_good_pass(pAr->sorted(['e','c','a'], $cmp_rev)->validate(['a','e','c']), "sorted passes correctly in reverse");
is_a_good_fail(pAr->sorted(['a','e','c'], $cmp_rev)->validate(['a','e','c']), "sorted fails correctly in reverse");
is_a_good_pass(pAr->sorted([], $cmp_rev)->validate([]), "sorted passes correctly on empty array in reverse");

# ascending

is_a_good_pass(pAr->ascending->validate(['a','c','e']), "ascending passes correctly");
is_a_good_fail(pAr->ascending->validate(['a','e','c']), "ascending fails correctly");
is_a_good_pass(pAr->ascending->validate([]), "ascending passes correctly on empty array");
is_a_good_pass(pAr->ascending->validate([]), "ascending passes correctly on single item array");

# descending

is_a_good_pass(pAr->descending->validate(['e','c','a']), "descending passes correctly");
is_a_good_pass(pAr->descending($cmp_lc)->validate(['e','C','a']), "descending passes correctly with lc");
is_a_good_fail(pAr->descending->validate(['e','a','c']), "descending fails correctly");
is_a_good_pass(pAr->descending->validate([]), "descending passes correctly on empty array");
is_a_good_pass(pAr->descending->validate([]), "descending passes correctly on single item array");

# array_max
is_a_good_pass(pAr->array_max('e')->validate(['a','e','c']), "array_max passes correctly");
is_a_good_fail(pAr->array_max('e')->validate(['a','e','f']), "array_max fails correctly when a better candidate exists");
is_a_good_fail(pAr->array_max('f')->validate(['a','e','c']), "array_max fails correctly when prototype fails");
is_a_good_fail(pAr->array_max('e')->validate([]), "array_max fails correctly for []");

is_a_good_pass(pAr->array_max('E', $cmp_lc)->validate(['a','E','c']), "array_max passes correctly with lc");
is_a_good_pass(pAr->array_max('E', $cmp_lc)->validate(['a','e','E','c']), "array_max passes correctly with lc - 2 winners");
is_a_good_pass(pAr->array_max('E', $cmp_lc)->validate(['a','E','e','c']), "array_max passes correctly with lc - 2 winners, reversed");
is_a_good_fail(pAr->array_max('E', $cmp_lc)->validate(['a','E','f']), "array_max fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_max('E', $cmp_lc)->validate(['a','e','E','f']), "array_max fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_max('f', $cmp_lc)->validate(['a','E','c']), "array_max fails correctly when prototype fails with lc");
is_a_good_fail(pAr->array_max('E', $cmp_lc)->validate([]), "array_max fails correctly for [] with lc");

# array_index_of_max
is_a_good_pass(pAr->array_index_of_max(1)->validate(['a','e','c']), "array_index_of_max passes correctly");
is_a_good_fail(pAr->array_index_of_max(1)->validate(['a','e','f']), "array_index_of_max fails correctly when a better candidate exists");
is_a_good_fail(pAr->array_index_of_max(2)->validate(['a','e','c']), "array_index_of_max fails correctly when prototype fails");
is_a_good_fail(pAr->array_index_of_max(1)->validate([]), "array_index_of_max fails correctly for []");

is_a_good_pass(pAr->array_index_of_max(1, $cmp_lc)->validate(['a','E','c']), "array_index_of_max passes correctly with lc");
is_a_good_pass(pAr->array_index_of_max(1, $cmp_lc)->validate(['a','e','E','c']), "array_index_of_max passes correctly with lc - 2 winners");
is_a_good_pass(pAr->array_index_of_max(1, $cmp_lc)->validate(['a','E','e','c']), "array_index_of_max passes correctly with lc - 2 winners, reversed");
is_a_good_fail(pAr->array_index_of_max(1, $cmp_lc)->validate(['a','E','f']), "array_index_of_max fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_index_of_max(1, $cmp_lc)->validate(['a','e','E','f']), "array_index_of_max fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_index_of_max(2, $cmp_lc)->validate(['a','E','c']), "array_index_of_max fails correctly when prototype fails with lc");
is_a_good_fail(pAr->array_index_of_max(1, $cmp_lc)->validate([]), "array_index_of_max fails correctly for [] with lc");


# array_min
is_a_good_pass(pAr->array_min('e')->validate(['g','e','h']), "array_min passes correctly");
is_a_good_fail(pAr->array_min('e')->validate(['g','e','d']), "array_min fails correctly when a better candidate exists");
is_a_good_fail(pAr->array_min('f')->validate(['g','e','h']), "array_min fails correctly when prototype fails");
is_a_good_fail(pAr->array_min('e')->validate([]), "array_min fails correctly for []");

is_a_good_pass(pAr->array_min('E', $cmp_lc)->validate(['g','E','h']), "array_min passes correctly with lc");
is_a_good_pass(pAr->array_min('E', $cmp_lc)->validate(['g','e','E','h']), "array_min passes correctly with lc - 2 winners");
is_a_good_pass(pAr->array_min('E', $cmp_lc)->validate(['g','E','e','h']), "array_min passes correctly with lc - 2 winners, reversed");
is_a_good_fail(pAr->array_min('E', $cmp_lc)->validate(['g','E','d']), "array_min fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_min('E', $cmp_lc)->validate(['g','e','E','d']), "array_min fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_min('f', $cmp_lc)->validate(['g','E','h']), "array_min fails correctly when prototype fails with lc");
is_a_good_fail(pAr->array_min('E', $cmp_lc)->validate([]), "array_min fails correctly for [] with lc");

# array_index_of_min
is_a_good_pass(pAr->array_index_of_min(1)->validate(['g','e','h']), "array_index_of_min passes correctly");
is_a_good_fail(pAr->array_index_of_min(1)->validate(['g','e','d']), "array_index_of_min fails correctly when a better candidate exists");
is_a_good_fail(pAr->array_index_of_min(2)->validate(['g','e','h']), "array_index_of_min fails correctly when prototype fails");
is_a_good_fail(pAr->array_index_of_min(1)->validate([]), "array_index_of_min fails correctly for []");

is_a_good_pass(pAr->array_index_of_min(1, $cmp_lc)->validate(['g','E','h']), "array_index_of_min passes correctly with lc");
is_a_good_pass(pAr->array_index_of_min(1, $cmp_lc)->validate(['g','e','E','h']), "array_index_of_min passes correctly with lc - 2 winners");
is_a_good_pass(pAr->array_index_of_min(1, $cmp_lc)->validate(['g','E','e','h']), "array_index_of_min passes correctly with lc - 2 winners, reversed");
is_a_good_fail(pAr->array_index_of_min(1, $cmp_lc)->validate(['g','E','d']), "array_index_of_min fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_index_of_min(1, $cmp_lc)->validate(['g','e','E','d']), "array_index_of_min fails correctly when a better candidate exists with lc");
is_a_good_fail(pAr->array_index_of_min(2, $cmp_lc)->validate(['g','E','h']), "array_index_of_min fails correctly when prototype fails with lc");
is_a_good_fail(pAr->array_index_of_min(1, $cmp_lc)->validate([]), "array_index_of_min fails correctly for [] with lc");


# array_all_unique
is_a_good_pass(pAr->array_all_unique->validate(['a','b','c','d']), "array_all_unique passes correctly");
is_a_good_pass(pAr->array_all_unique->validate([]), "array_all_unique passes correctly for []");
is_a_good_pass(pAr->array_all_unique->validate(['a']), "array_all_unique passes correctly for ['a']");
is_a_good_fail(pAr->array_all_unique->validate(['a','a','a','a']), "array_all_unique fails correctly");

# array_all_same
is_a_good_pass(pAr->array_all_same->validate(['a','a','a','a']), "array_all_same passes correctly");
is_a_good_pass(pAr->array_all_same->validate([]), "array_all_same passes correctly for []");
is_a_good_pass(pAr->array_all_same->validate(['a']), "array_all_same passes correctly for ['a']");
is_a_good_fail(pAr->array_all_same->validate(['a','b','c','d']), "array_all_same fails correctly");

# subset_of, superset_of, subbag_of, superbag_of

my $testCases = [
	{
		type=>'bag,set,subset,subbag,superset,superbag',
		comment => 'Equal',
		left => [1,2,3],
		right => [1,2,3],
	},
	{
		type  =>'superset,superbag',
		comment => 'Left > Right',
		left  => [1,2,3],
		right => [1,2],
	},
	{
		type=>'subset,subbag',
		comment => 'Right > Left',
		left => [1,2],
		right => [1,2,3],
	},
	{
		type  =>'set,subset,superset,superbag',
		comment => 'Left > Right (but setwise equal)',
		left  => [1,1,2],
		right => [1,2],
	},
	{
		type  =>'set,subset,superset,subbag',
		comment => 'Right > Left (but setwise equal)',
		left  => [1,2],
		right => [1,1,2],
	},
	{
		type  =>'set,superset,subset,superbag',
		comment => '[1,2] vs [p]',
		left  => [1,2],
		right => [p],
	},
	{
		type  =>'bag,set,superset,subset,superbag,subbag',
		comment => '[1,2] vs [2,p]',
		left  => [1,2],
		right => [2,p],
	},
	{
		type  =>'bag,set,superset,subset,superbag,subbag',
		comment => '[1,2,3] vs [p,p,1]',
		left  => [1,2,3],
		right => [p,p,1],
	},
];
my $machine = sub {
	my ($method, $left, $right) = @_;
	my $fullMethod = $method.'_of';
	pAr->$fullMethod($right)->validate($left);
};
foreach my $testCase (@$testCases) {
	foreach my $method (qw(bag set superset subset superbag subbag)) {
		if ($testCase->{type} =~ /\b$method\b/) {
			ok ($machine->($method,$testCase->{left}, $testCase->{right}), "$method should pass with these arguments - ".$testCase->{comment});
		}
		else {
			ok (!$machine->($method,$testCase->{left}, $testCase->{right}), "$method should fail with these arguments - ".$testCase->{comment});
		}
	}
}

use Test::Proto::Series;
use Test::Proto::Repeatable;
use Test::Proto::Alternation;

sub pSeries { Test::Proto::Series->new(@_); }
sub pAlternation { Test::Proto::Alternation->new(@_); }
sub pRepeatable { Test::Proto::Repeatable->new(@_); }
my $rpt = pRepeatable(p);
$rpt->max(2);
isa_ok (pRepeatable, 'Test::Proto::Repeatable');
isa_ok (pRepeatable->max(2), 'Test::Proto::Repeatable'); #~ test if method chaining works
my $seriesTests = [

{ # 1
	prototype  => pSeries('a'),
	subject    => ['a'],
	value      => 1,
},
{ # 2
	prototype  => pSeries('b'),
	subject    => ['a'],
	value      => 0,
},
{ # 3
	prototype  => pSeries('a','b'),
	subject    => ['a','b'],
	value      => 1,
},
{ # 4
	prototype  => pSeries('a','b'),
	subject    => ['a','c'],
	value      => 0,
},
{ # 5
	prototype  => pSeries('a','b','c'),
	subject    => ['a','b'],
	value      => 0,
},
{ # 6
	prototype  => pSeries('a','b'),
	subject    => ['a','b','c'],
	value      => 'begins_with',
},
{ # 7
	prototype  => $rpt,
	subject    => ['a','b'],
	value      => 1,
},
{ # 8
	prototype  => $rpt,
	subject    => ['a','b','c'],
	value      => 'begins_with ends_with',
},
{ # 9
	prototype  => $rpt,
	subject    => [0],
	value      => 1,
},
{ # 10
	prototype  => pSeries(pSeries('a','b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 11
	prototype  => pAlternation(pSeries('a','b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 12
	prototype  => pAlternation(pSeries('a','b')),
	subject    => ['a'],
	value      => 0,
},
{ # 13
	prototype  => pAlternation(pSeries('a')),
	subject    => ['a', 'b'],
	value      => 'begins_with',
},
{ # 14
	prototype  => pAlternation(pSeries('a'),pRepeatable('a'),pSeries('a')),
	subject    => ['a', 'a'],
	value      => 1,
},
{ # 15
	prototype  => pAlternation(pSeries('a'),pSeries('a','b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 16
	prototype  => pSeries(pSeries('a'),pSeries('b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 17
	prototype  => pSeries(pSeries('a', 'b'),pSeries('b')),
	subject    => ['a','b'],
	value      => 0,
},
{ # 18
	prototype  => pSeries(pAlternation('a', 'b'),pSeries('b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 19
	prototype  => pSeries(pRepeatable('a'),pSeries('b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 20
	prototype  => pSeries(pRepeatable(pAlternation('a','b'))),
	subject    => ['a','b'],
	value      => 1,
},
{ # 21
	prototype  => pSeries(pRepeatable(pAlternation('a','b')), 'b'),
	subject    => ['a','b'],
	value      => 1,
},
{ # 22
	prototype  => pSeries(pRepeatable(pAlternation('a','b')), 'a','b'),
	subject    => ['a','b'],
	value      => 1,
},
{ # 23
	prototype  => pSeries('a','b', pRepeatable(pAlternation('a','b'))),
	subject    => ['a','b'],
	value      => 1,
},
{ # 24
	prototype  => pSeries('a','b', pRepeatable(pAlternation('a','b')), 'c'),
	subject    => ['a','b'],
	value      => 0,
},
{ # 25
	prototype  => pAlternation(pSeries('b'),pSeries('a','b')),
	subject    => ['a','b'],
	value      => 1,
},
{ # 26
	prototype  => pAlternation(pSeries('a'),pSeries('b')),
	subject    => ['a','b'],
	value      => 'ends_with begins_with',
},
{ # 27
	prototype  => pRepeatable('a','b'),
	subject    => ['a','b','a','b'],
	value      => 1,
},
{ # 28
	prototype  => pRepeatable('a','b'),
	subject    => ['a'],
	value      => 0,
},
];

my $i = 0;

foreach my $t (@$seriesTests){
	$i++;
	foreach my $method (qw(begins_with contains_only ends_with)){
		if ( ($t->{value} eq 1) or $t->{value} =~ /$method/ ) {
			is_a_good_pass( pAr->$method($t->{prototype})->validate($t->{subject}), "Series Test $i must pass $method");
		}
		else {
			is_a_good_fail( pAr->$method($t->{prototype})->validate($t->{subject}), "Series Test $i must fail" );
		}
	}
}





done_testing;


