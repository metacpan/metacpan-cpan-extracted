#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END { print "not ok 1\n" unless $loaded; }
use Weather::Underground;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#
# Test single-location matches:
#

$weather = Weather::Underground->new(
	place => "Montreal, Canada",
	debug => 0,
);

if ($weather) {
	print "ok 2\n";
}
else {
	print "not ok 2\n";
}

$arrayref = $weather->get_weather();

if ($arrayref) {
	print "ok 3\n";
}
else {
	print "not ok 3\n";
}

if ($arrayref->[0]->{temperature_fahrenheit} || $arrayref->[0]->{temperature_celsius}) {
	print "ok 4\n";
}
else {
	print "not ok 4\n";
}

#
# Test multi-location matches:
#
$weather = Weather::Underground->new(
	place => "London",
	debug => 0
);

if ($weather) {
	print "ok 5\n";
}
else {
	print "not ok 5\n";
}

$arrayref = $weather->get_weather();

if ($arrayref) {
	print "ok 6\n";
}
else {
	print "not ok 6\n";
}

if ($arrayref->[0]->{temperature_fahrenheit} || $arrayref->[0]->{temperature_celsius}) {
	print "ok 7\n";
}
else {
	print "not ok 7\n";
}
