use strict;

## This test can only be run when all the backends are installed.
## It verifies that the every backend's diff output is compatible
## with every backend's patch functionality.

use Test::More qw(no_plan);

use Vcdiff;
use Vcdiff::Test;


my @backends = qw{  Vcdiff::Xdelta3  Vcdiff::OpenVcdiff  };


for my $i (0..$#backends) {
  for my $j (0..$#backends) {
    my $differ = my $differ_short = $backends[$i];
    my $patcher = my $patcher_short = $backends[$j];

    $differ_short =~ s/^Vcdiff:://;
    $patcher_short =~ s/^Vcdiff:://;

    local $ENV{VCDIFF_TEST_DIFFER_BACKEND} = $differ;
    local $ENV{VCDIFF_TEST_PATCHER_BACKEND} = $patcher;

    diag("DIFFER: $differ_short  PATCHER: $patcher_short");

    Vcdiff::Test::streaming();
  }
}
