use warnings;
use strict;

use Test::More 0.41 tests => 2;

BEGIN { use_ok "Time::OlsonTZ::Data", qw(olson_links olson_tzfile); }

my $failures;

my $links = olson_links;

$failures = 0;
foreach(keys %$links) {
	my $f = olson_tzfile($_);
	my $g = olson_tzfile($links->{$_});
	unless($f eq $g) {
		diag "$_ ($f) ne @{[$links->{$_}]} ($g)";
		$failures++;
	}
}
is $failures, 0;

1;
