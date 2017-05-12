use warnings;
use strict;

use Test::More tests => 39*4 + 7;

BEGIN {
	use_ok "Time::UTC", qw(
		utc_start_segment
		utc_segment_of_utc_day utc_segment_of_tai_instant
	);
}

{
	no warnings "redefine";
	sub Time::UTC::Segment::_download_latest_data() { 0 }
}

use Math::BigRat 0.13;

my $epsilon = Math::BigRat->new("0.000000000001");
my $seg = utc_start_segment();

eval { utc_segment_of_utc_day($seg->start_utc_day - 1); };
like $@, qr/\Aday [0-9]+ precedes the start of UTC /;
eval { utc_segment_of_tai_instant($seg->start_tai_instant - $epsilon); };
like $@, qr/\Ainstant [^\t\n\f\r ]+ precedes the start of UTC /;

for(my $n = 39; $n--; $seg = $seg->next) {
	ok utc_segment_of_utc_day($seg->start_utc_day) == $seg;
	ok utc_segment_of_tai_instant($seg->start_tai_instant) == $seg;
	ok utc_segment_of_utc_day($seg->last_utc_day) == $seg;
	ok utc_segment_of_tai_instant($seg->end_tai_instant - $epsilon)
		== $seg;
}

eval { utc_segment_of_utc_day($seg->start_utc_day); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_segment_of_tai_instant($seg->start_tai_instant); };
like $@, qr/\Ainstant [^\t\n\f\r ]+ has no UTC definition yet /;
eval { utc_segment_of_utc_day($seg->start_utc_day + 1); };
like $@, qr/\Aday [0-9]+ has no UTC definition yet /;
eval { utc_segment_of_tai_instant($seg->start_tai_instant + $epsilon); };
like $@, qr/\Ainstant [^\t\n\f\r ]+ has no UTC definition yet /;

1;
