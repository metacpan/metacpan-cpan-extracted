use strict;
use warnings;

use Test::More tests => 2 * 2;

foreach my $m (qw(MMM::Report::Html MMM::Report::Console)) {
    use_ok($m);
    can_ok($m, qw(header footer body run));
}
