use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Time::UTC::Now", qw(utc_day_to_cjdn); }

sub check($$) {
	my($day, $cjdn) = @_;
	is utc_day_to_cjdn($day), $cjdn;
}

check(-1, 2436204);
check(0, 2436205);
check(365*41 + 10, 2451180);

1;
