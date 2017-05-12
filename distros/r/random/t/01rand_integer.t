use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

use random qw(integer);

my $r=rand 10;
ok ( (grep {$r == $_} 0 .. 9), "integer rand 10 is in 0..9");

no random;
$r=rand 10;
ok ( (!grep {$r == $_} 0 .. 9), "normal rand 10 is not in 0..9");
