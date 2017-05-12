use Test::More qw/no_plan/;

use lib qw(t/lib ./lib ../t/lib);
use Two;

use Inherit qw(
           :ALL
           cpan_l2s
        );

my $sum = l2s_sum 1 .. 10;
is("$sum", 55);
