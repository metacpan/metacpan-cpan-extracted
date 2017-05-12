use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::GPS", qw(gps_instant_to_mjd gps_mjd_to_instant); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($instant, $mjd) = @_;
	$instant = Math::BigRat->new($instant);
	$mjd = Math::BigRat->new($mjd);
	match gps_instant_to_mjd($instant), $mjd;
	match gps_mjd_to_instant($mjd), $instant;
}

check("19", "36204");
check("599616019", "43144");
check("599616105.4", "43144.001");
check("599616020", (43144*86400+1)."/86400");

1;
