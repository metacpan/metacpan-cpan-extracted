use warnings;
use strict;

use Test::More tests => 41;

BEGIN { use_ok "Time::UTC", qw(utc_day_to_ymd utc_ymd_to_day); }

use Math::BigRat 0.13;

sub match_val($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

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

eval { utc_day_to_ymd(br("0.5")); };
like $@, qr/\Anon-integer day [^\t\n\f\r ]+ is invalid /;

eval { utc_ymd_to_day(br("0.5"), br(1), br(1)); };
like $@, qr/\Ainvalid year number /;
foreach my $mo (br(0), br(13), br("0.5")) {
	eval { utc_ymd_to_day(br(1958), $mo, br(1)); };
	like $@, qr/\Ainvalid month number /;
}
foreach my $dy (br(0), br(29), br("0.5")) {
	eval { utc_ymd_to_day(br(1958), br(2), $dy); };
	like $@, qr/\Ainvalid day number /;
}

sub check($$$$) {
	my($day, $yr, $mo, $dy) = @_;
	match_vec [ utc_day_to_ymd($day) ], [ $yr, $mo, $dy ];
	match_val utc_ymd_to_day($yr, $mo, $dy), $day;
}

check(br(365*-58 - 14), br(1900), br(1), br(1));
check(br(365*-58 - 14 + 58), br(1900), br(2), br(28));
check(br(365*-58 - 14 + 59), br(1900), br(3), br(1));
check(br(-1), br(1957), br(12), br(31));
check(br(0), br(1958), br(1), br(1));
check(br(30), br(1958), br(1), br(31));
check(br(31), br(1958), br(2), br(1));
check(br(58), br(1958), br(2), br(28));
check(br(59), br(1958), br(3), br(1));
check(br(365), br(1959), br(1), br(1));
check(br(365*2 + 59), br(1960), br(2), br(29));
check(br(365*41 + 10), br(1999), br(1), br(1));
check(br(365*42 + 10 - 1), br(1999), br(12), br(31));
check(br(365*42 + 10), br(2000), br(1), br(1));
check(br(365*43 + 11 - 1), br(2000), br(12), br(31));
check(br(365*43 + 11), br(2001), br(1), br(1));

1;
