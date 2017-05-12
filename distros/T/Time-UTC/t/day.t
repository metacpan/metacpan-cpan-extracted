use warnings;
use strict;

use Test::More tests => 1 + 3 + 16*39 + 6;

BEGIN {
	use_ok "Time::UTC", qw(
		utc_start_segment
		utc_day_leap_seconds utc_day_seconds
		utc_check_instant
	);
}

use Math::BigRat 0.13;

sub match($$) {
	my($a, $b) = @_;
	ok ref($a) eq ref($b) && $a == $b;
}

sub br(@) { Math::BigRat->new(@_) }

my $epsilon = br("0.000000000001");

{
	no warnings "redefine";
	sub Time::UTC::Segment::_download_latest_data() { 0 }
}

my $seg = utc_start_segment();

eval { utc_day_leap_seconds($seg->start_utc_day - 1); };
like $@, qr/\Aday [0-9]+ precedes the start of UTC /;
eval { utc_day_seconds($seg->start_utc_day - 1); };
like $@, qr/\Aday [0-9]+ precedes the start of UTC /;
eval { utc_check_instant($seg->start_utc_day - 1, br(0)); };
like $@, qr/\Aday [0-9]+ precedes the start of UTC /;

for(my $n = 39; $n--; $seg = $seg->next) {
	match utc_day_leap_seconds($seg->start_utc_day), br(0);
	match utc_day_seconds($seg->start_utc_day), br(86400);
	eval { utc_check_instant($seg->start_utc_day, -$epsilon); };
	like $@, qr/ is out of range /;
	eval { utc_check_instant($seg->start_utc_day, br(0)); };
	is $@, "";
	eval { utc_check_instant($seg->start_utc_day, 86400 - $epsilon); };
	is $@, "";
	eval { utc_check_instant($seg->start_utc_day, br(86400)); };
	like $@, qr/ is out of range /;
	match utc_day_leap_seconds($seg->start_utc_day + 1), br(0);
	match utc_day_seconds($seg->start_utc_day + 1), br(86400);
	match utc_day_leap_seconds($seg->last_utc_day - 1), br(0);
	match utc_day_seconds($seg->last_utc_day - 1), br(86400);
	my $lastlen = $seg->last_day_utc_seconds;
	match utc_day_leap_seconds($seg->last_utc_day), $seg->leap_utc_seconds;
	match utc_day_seconds($seg->last_utc_day), $lastlen;
	eval { utc_check_instant($seg->last_utc_day, -$epsilon); };
	like $@, qr/ is out of range /;
	eval { utc_check_instant($seg->last_utc_day, br(0)); };
	is $@, "";
	eval { utc_check_instant($seg->last_utc_day, $lastlen - $epsilon); };
	is $@, "";
	eval { utc_check_instant($seg->last_utc_day, $lastlen); };
	like $@, qr/ is out of range /;
}

eval { utc_day_leap_seconds($seg->start_utc_day); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_day_seconds($seg->start_utc_day); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_check_instant($seg->start_utc_day, br(0)); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_day_leap_seconds($seg->start_utc_day + 1); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_day_seconds($seg->start_utc_day + 1); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_check_instant($seg->start_utc_day + 1, br(0)); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;

1;
