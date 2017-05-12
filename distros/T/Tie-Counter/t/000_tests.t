# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
    $| = 1;
    my $n = $] < 5.008 ? 5 : 7;
    print "1..$n\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Counter;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

tie my $counter => 'Tie::Counter';

print $counter == 0    ? "ok 2\n" : "not ok 2\n";
print $counter == 1    ? "ok 3\n" : "not ok 3\n";
$counter = 'aa';
print $counter eq 'aa' ? "ok 4\n" : "not ok 4\n";
print $counter eq 'ab' ? "ok 5\n" : "not ok 5\n";

if ($] >= 5.008) {
    tie my $other_counter => 'Tie::Counter', "Perl";

    print "$other_counter camel" eq 'Perl camel' ? "ok 6\n" : "not ok 6\n";
    print "$other_counter camel" eq 'Perm camel' ? "ok 7\n" : "not ok 7\n";
}
