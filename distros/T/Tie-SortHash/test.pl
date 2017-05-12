# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::SortHash;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$\ = "\n"; # Am I lazy or what

sub report {
  my( $ok, $test ) = @_;
  print $ok ? "ok $test" : "not ok $test";
}

my %hash = qw(
              perl   1
              python 2
              java   3
              php    4
             );

my $sortblock = q( $a cmp $b );

my $tied_ref = tie %hash, 'Tie::SortHash', \%hash;

report( $tied_ref->isa( 'Tie::SortHash' ), 2 );

report( $tied_ref->sortblock( $sortblock ), 3 );

my @keys = keys %hash;

report( $keys[0] eq 'java', 4 );

report( $keys[3] eq 'python', 5 );

report( (tied %hash)->sortblock( q( $hash{$a} <=> $hash{$b} ) ), 6 );

my @values = values %hash;

report( $values[0] == 1, 7 );

report( $values[3] == 4, 8 );

report( delete $hash{java}, 9 );

report( $hash{asp} = 5, 10 );

@values = values %hash;

report( $values[3] = 5, 11 );

report( ! undef %hash, 12 );
