use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::TT", qw(tt_instant_to_mjd tt_mjd_to_instant); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($instant, $mjd) = @_;
	$instant = Math::BigRat->new($instant);
	$mjd = Math::BigRat->new($mjd);
	match tt_instant_to_mjd($instant), $mjd;
	match tt_mjd_to_instant($mjd), $instant;
}

check("0", "36204.0003725");
check("599616000", "43144.0003725");
check("599615967.816", "43144");
check("599615968.816", (43144*86400+1)."/86400");

1;
