
use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('Test::Tk') };

createapp(
);

my %hash1 = (
	key => 'value',
	number => 7,
);

#we want both hashes to be identical and
#in different variables.
my %hash2 = %hash1;

my @list1 = (qw/one two three/);

#we want lists to be identical and
#in different variables.
my @list2 = @list1;

my %chash1 = (%hash1,
	'list' => [@list1],
	'hash' => { %hash1 },
);

my %chash2 = (%hash1,
	'list' => [@list1],
	'hash' => { %hash1 },
);

my @clist1 = (@list1, [@list2], \%hash1);
my @clist2 = (@list1, [@list2], \%hash1);


@tests = (
	[sub { return 'one' }, 'one', 'scalar testing'],
	[sub { return \%hash1 }, \%hash2, 'hash testing'],
	[sub { return \@list1 }, \@list2, 'list testing'],
	[sub { return \%chash1 }, \%chash2, 'complex hash testing'],
	[sub { return \@clist1 }, \@clist2, 'complex list testing'],
);

starttesting;

