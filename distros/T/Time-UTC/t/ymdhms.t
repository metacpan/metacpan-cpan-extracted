use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Time::UTC", qw(utc_instant_to_ymdhms utc_ymdhms_to_instant); }

use Math::BigRat 0.13;

sub match_vec($$) {
	my($a, $b) = @_;
	unless(@$a == @$b) {
		ok 0;
		return;
	}
	for(my $i = 0; $i != @$a; $i++) {
		my $aval = $a->[$i];
		my $bval = $b->[$i];
		unless(ref($aval) eq ref($bval) && $aval == $bval) {
			ok 0;
			return;
		}
	}
	ok 1;
}

sub br(@) { Math::BigRat->new(@_) }

match_vec [ utc_instant_to_ymdhms(br(33), br("14706.7")) ],
		[ br(1958), br(2), br(3), br(4), br(5), br("6.7") ];
match_vec [ utc_ymdhms_to_instant(br(1958), br(2), br(3),
					br(4), br(5), br("6.7")) ],
		[ br(33), br("14706.7") ];

1;
