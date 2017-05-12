use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Time::TT", qw(tt_instant_to_jepoch tt_jepoch_to_instant); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($instant, $jepoch) = @_;
	$instant = Math::BigRat->new($instant);
	$jepoch = Math::BigRat->new($jepoch);
	match tt_instant_to_jepoch($instant), $jepoch;
	match tt_jepoch_to_instant($jepoch), $instant;
}

check("-32.184", "1958");
check("599615967.816", "722099.50/365.25");
check("1325376000", "730499.5003725/365.25");

1;
