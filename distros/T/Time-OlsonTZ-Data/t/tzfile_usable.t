use warnings;
use strict;

BEGIN {
	eval {
		require DateTime::TimeZone::Tzfile;
		DateTime::TimeZone::Tzfile->VERSION(0.009);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all =>
			"no usable DateTime::TimeZone::Tzfile");
	}
}

use Test::More 0.41 tests => 2;

BEGIN { use_ok "Time::OlsonTZ::Data", qw(olson_canonical_names olson_tzfile); }

my $failures = 0;
foreach(sort keys %{olson_canonical_names()}) {
	unless(eval { DateTime::TimeZone::Tzfile->new(olson_tzfile($_)); 1}) {
		diag "$_: $@";
		$failures++;
	}
}
is $failures, 0;

1;
