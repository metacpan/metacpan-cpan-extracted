# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use lib 'lib';
BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::OffsetArray;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my @a;
my @b = qw( a b c d e );

tie @a, 'Tie::OffsetArray', 1, \@b; # offset=1; use given array.

$a[0] = 'x';                        # assign to $b[1];
$a[-1] = 'y';                       # assign to $b[-1];

tied(@a)->array->[0] = 'z';         # assign to $b[0].

print
join('',@b) eq 'zxcdy'
? "ok 2\n"
: "not ok 2\n";

