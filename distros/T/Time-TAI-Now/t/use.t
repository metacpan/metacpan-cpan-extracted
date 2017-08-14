use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
	use_ok "Time::TAI::Now",
		qw(now_tai_rat now_tai_gsna now_tai_flt now_tai_dec);
}

1;
