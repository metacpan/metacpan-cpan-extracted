# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::Number;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "Testing printing: 500.000\n";
$number = number(value => 500, places => 3);
print "$number\n2 ok\n";
print "Testing numerical comparison:\n3 ";
print STDOUT ($number == 500) ? 'ok' : 'failed';
print "\n";
print "Testing string comparison:\n4 ";
print STDOUT ("$number" eq '500.000') ? 'ok' : 'failed';
print "\n";
print "End of tests\n";
