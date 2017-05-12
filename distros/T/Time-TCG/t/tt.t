use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Time::TCG", qw(tcg_to_tt tt_to_tcg); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub check($$) {
	my($tcg, $tt) = map { Math::BigRat->new($_) } @_;
	match tcg_to_tt($tcg), $tt;
	match tt_to_tcg($tt), $tcg;
}

check("-1", "599615999.0000000006969290134");
check( "0", "599616000");
check( "1", "599616000.9999999993030709866");

1;
