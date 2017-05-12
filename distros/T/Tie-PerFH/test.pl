# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::PerFH;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

tie my($font), 'Tie::PerFH';

$font = "blue";

select STDIN;

$font = "red";

select STDOUT;

if ($font eq 'blue') { print STDOUT "ok 2\n" }
else { print STDOUT "not ok 2\n" }

select STDIN;

if ($font eq 'red') { print STDOUT "ok 3\n"; }
else { print STDOUT "not ok 3\n" }

