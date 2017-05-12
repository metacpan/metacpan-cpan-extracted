use strict;
use Text::WagnerFischer qw(distance);

my $ko=0;
my $test=1;
my $first_distance=distance("foo","four");

if ($first_distance == 2) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

my $second_distance=distance("foo","foo");
$test++;

if ($second_distance == 0) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

my $third_distance=distance([0,1,2],"foo","four");
$test++;

if ($third_distance == 3) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

my @words=("four","foo","bar");

my @distances=distance("foo",@words);
$test++;

if (($distances[0] == 2) and ($distances[1] == 0) and ($distances[2] == 3)) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}

@distances=distance([0,5,3],"foo",@words);
$test++;

if (($distances[0] == 8) and ($distances[1] == 0) and ($distances[2] == 9)) {

	print $test.". ok\n"

} else {

	print $test.". NO <--\n";
	$ko=1;
}


if ($ko) {print "\nTest suite failed\n"} else {print "\nTest suite ok\n"}
