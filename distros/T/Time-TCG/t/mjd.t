use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::TCG", qw(tcg_instant_to_mjd tcg_mjd_to_instant); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($instant, $mjd) = @_;
	$instant = Math::BigRat->new($instant);
	$mjd = Math::BigRat->new($mjd);
	match tcg_instant_to_mjd($instant), $mjd;
	match tcg_mjd_to_instant($mjd), $instant;
}

check("-599616000", "36204.0003725");
check("0", "43144.0003725");
check("-32.184", "43144");
check("-31.184", (43144*86400+1)."/86400");

1;
