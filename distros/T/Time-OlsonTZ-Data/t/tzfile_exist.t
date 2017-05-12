use warnings;
use strict;

use Test::More 0.41 tests => 2;

BEGIN { use_ok "Time::OlsonTZ::Data", qw(olson_canonical_names olson_tzfile); }

my $failures = 0;
foreach(sort keys %{olson_canonical_names()}) {
	my $f = olson_tzfile($_);
	unless(-f $f) {
		diag "$_: $f does not exist";
		$failures++;
	}
}
is $failures, 0;

1;
