# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Pick;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

tie my $beatle => Tie::Pick => qw /George John Paul Ringo/;

my @test = ($beatle, $beatle, $beatle, $beatle);
   @test = sort @test;
print "@test" eq "George John Paul Ringo" ? "ok 2\n" : "not ok 2\n";

my @beatles = qw /Harrison Lennon McCartney Star/;
   $beatle  = \@beatles;

my $b1 = $beatle;
my $b2 = $beatle;

print +((grep {$_ eq $b1} @beatles) &&
        (grep {$_ eq $b2} @beatles) &&
         $b1 ne $b2) ? "ok 3\n" : "not ok 3\n";
