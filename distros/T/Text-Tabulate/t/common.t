#!perl

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;

use Test::More tests => 7;

# Tests
BEGIN { use_ok('Text::Tabulate'); }

# Load the data.
$/ = '';	# paragraph mode.
my @data = split(/\n/, <DATA>);
ok($#data, 'data loaded');

# Test the routine.

while ($_ = <DATA>)
{
	# Initialisation.
	my $max = 0;
	my $ditto = '"';
	my $tab = '_+ ';

	# Load the test
	my ($test, @test) = split(/\n/, $_);
	eval $test;

	#print "$test\n", join("\n", @test), "\n\n";
	#print "max=$max\n";

	# run the test.
	my $obj = new Text::Tabulate(
		tab => $tab,
		cf => $max,
		ditto => $ditto,
	);
	my @result = $obj->common(@data);

	# Check.
	is_deeply(\@result, \@test, $test);

	#print join("\n", @result), "\n\n";
}

exit;

__DATA__
1__ X__ X___ A
1__ 2__ Y___ B
1__ 2__ 3___ C
1__ 2__ 3___ D
3__ 3__ 3___ D

$max=0;
1__ X__ X___ A
"__ 2__ Y___ B
"__ "__ 3___ C
"__ "__ "___ D
3__ 3__ 3___ D

$max=1;
1__ X__ X___ A
"__ 2__ Y___ B
"__ 2__ 3___ C
"__ 2__ 3___ D
3__ 3__ 3___ D

$max=2;
1__ X__ X___ A
"__ 2__ Y___ B
"__ "__ 3___ C
"__ "__ 3___ D
3__ 3__ 3___ D

$max=3;
1__ X__ X___ A
"__ 2__ Y___ B
"__ "__ 3___ C
"__ "__ "___ D
3__ 3__ 3___ D

$max=20; $ditto=' ';
1__ X__ X___ A
 __ 2__ Y___ B
 __  __ 3___ C
 __  __  ___ D
3__ 3__ 3___ D

