use assign::Test;

my $want = <<'...';
use strict;
use warnings;

use assign::0;

my $___1001 = [];
my $a1 = $___1001->[0];
my $b1 = $___1001->[1];
#line 6

warn "warn line 8";

my $___1002 = [];
my $a2 = $___1002->[0];
my $b2 = $___1002->[1];
#line 16

die "die line 18";
...

is + assign::0->debug("$t/line-numbers.pl"), $want,
    "assign::0->debug() works";
