use warnings;
use strict;

use Test::More tests => 9;

BEGIN {
	use_ok "Time::UTC", qw(
		utc_start_segment utc_day_seconds
		foreach_utc_segment_when_complete
	);
}

use Math::BigRat 0.02;

{
	no warnings "redefine";
	sub Time::UTC::Segment::_download_latest_data() { 0 }
}

my $done_sseg = 0;
my $sseg = utc_start_segment();

$sseg->when_complete(sub { $done_sseg++; });

my $done_segs = 0;
my $chained_segs = 0;
my $next_seg = $sseg;
foreach_utc_segment_when_complete {
	my($seg) = @_;
	$done_segs++;
	$chained_segs++ if $seg == $next_seg;
	$next_seg = $seg->next;
};

is $done_sseg, 0;
is $done_segs, 0;

utc_day_seconds(Math::BigRat->new(2000));

is $done_sseg, 1;
is $done_segs, 39;
is $chained_segs, 39;

utc_day_seconds(Math::BigRat->new(2000));

is $done_sseg, 1;
is $done_segs, 39;
is $chained_segs, 39;

1;
