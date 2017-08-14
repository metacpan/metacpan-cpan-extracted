use warnings;
use strict;

use Test::More tests => 13;

BEGIN {
	use_ok "Time::UTC::Now",
		qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);
}

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

foreach my $now_utc
		(\&now_utc_rat, \&now_utc_sna, \&now_utc_flt, \&now_utc_dec) {
	$now_utc->();
	ok 1;
	$now_utc->(0);
	ok 1;
	$now_utc->(undef);
	ok 1;
}

1;
