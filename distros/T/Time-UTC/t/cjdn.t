use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::UTC", qw(utc_day_to_cjdn utc_cjdn_to_day); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub br(@) { Math::BigRat->new(@_) }

eval { utc_day_to_cjdn(br("0.5")); };
like $@, qr/\Anon-integer day [^\t\n\f\r ]+ is invalid /;

eval { utc_cjdn_to_day(br("0.5")); };
like $@, qr/\Ainvalid CJDN /;

sub check($$) {
	my($day, $cjdn) = @_;
	match utc_day_to_cjdn($day), $cjdn;
	match utc_cjdn_to_day($cjdn), $day;
}

check(br(-1), br(2436204));
check(br(0), br(2436205));
check(br(365*41 + 10), br(2451180));

1;
