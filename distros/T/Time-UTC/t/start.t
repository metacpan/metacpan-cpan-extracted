use warnings;
use strict;

use Test::More tests => 3;

BEGIN {
	use_ok "Time::UTC", qw(
		utc_start_segment utc_start_tai_instant utc_start_utc_day
	);
}

use Math::BigRat 0.04;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

match utc_start_tai_instant(), utc_start_segment()->start_tai_instant;
match utc_start_utc_day(), utc_start_segment()->start_utc_day;

1;
