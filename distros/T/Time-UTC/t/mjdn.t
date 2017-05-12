use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Time::UTC", qw(utc_day_to_mjdn utc_mjdn_to_day); }

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub br(@) { Math::BigRat->new(@_) }

eval { utc_day_to_mjdn(br("0.5")); };
like $@, qr/\Anon-integer day [^\t\n\f\r ]+ is invalid /;

eval { utc_mjdn_to_day(br("0.5")); };
like $@, qr/\Ainvalid MJDN /;

sub check($$) {
	my($day, $mjdn) = @_;
	match utc_day_to_mjdn($day), $mjdn;
	match utc_mjdn_to_day($mjdn), $day;
}

check(br(-1), br(36203));
check(br(0), br(36204));
check(br(365*41 + 10), br(51179));

1;
