use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Time::UTC::Now", qw(utc_day_to_mjdn); }

sub check($$) {
	my($day, $mjdn) = @_;
	is utc_day_to_mjdn($day), $mjdn;
}

check(-1, 36203);
check(0, 36204);
check(365*41 + 10, 51179);

1;
