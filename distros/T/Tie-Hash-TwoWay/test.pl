# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Hash::TwoWay;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

tie %hash, 'Tie::Hash::TwoWay';

my %list = (
	    one => [1, 2, 3],
	    two => [4, 5, 2],
	   );

$hash{one} = $list{one};
$hash{two} = $list{two};
$hash{single} = 'scalar';

print "not " unless exists $hash{1};
print "ok 2\n";
print "not " unless exists $hash{2}->{one};
print "ok 3\n";
print "not " unless exists $hash{2}->{two};
print "ok 4\n";
print "not " unless exists $hash{one}->{3};
print "ok 5\n";
print "not " unless exists $hash{scalar};
print "ok 6\n";
delete $hash{one};

print "not " if exists $hash{1};
print "ok 7\n";
print "not " if exists $hash{2}->{one};
print "ok 8\n";

# test secondary keys
my $secondary = scalar %hash;
print "not " unless scalar keys %$secondary == 4;
print "ok 9\n";

# this should clear the whole hash
delete $hash{2};
delete $hash{4};
delete $hash{5};
delete $hash{'scalar'};

print "not " if scalar keys %hash;
print "ok 10\n";
