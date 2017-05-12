use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::TCB", qw(tcb_instant_to_mjd tcb_mjd_to_instant); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($instant, $mjd) = @_;
	$instant = Math::BigRat->new($instant);
	$mjd = Math::BigRat->new($mjd);
	match tcb_instant_to_mjd($instant), $mjd;
	match tcb_mjd_to_instant($mjd), $instant;
}

check("-1059696000", "36204.0003725");
check("0", "48469.0003725");
check("-32.184", "48469");
check("-31.184", (48469*86400+1)."/86400");

1;
