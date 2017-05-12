use warnings;
use strict;

use Test::More tests => 7;

BEGIN {
	use_ok "Time::OlsonTZ::Data", qw(
		olson_canonical_names olson_link_names olson_links
	);
}

my $failures;

my $cnames = olson_canonical_names;
my $lnames = olson_link_names;
my $links = olson_links;

foreach($cnames, $lnames, $links) {
	is ref($_), "HASH";
}

$failures = 0;
foreach(keys %$lnames) {
	exists $links->{$_} or $failures++;
}
is $failures, 0;

$failures = 0;
foreach(keys %$links) {
	exists $lnames->{$_} or $failures++;
}
is $failures, 0;

$failures = 0;
foreach(values %$links) {
	ref($_) eq "" or $failures++;
	defined($_) or $failures++;
	exists $cnames->{$_} or $failures++;
}
is $failures, 0;

1;
