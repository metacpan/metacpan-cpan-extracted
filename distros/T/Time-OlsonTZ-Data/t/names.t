use warnings;
use strict;

use Test::More tests => 13;

BEGIN {
	use_ok "Time::OlsonTZ::Data", qw(
		olson_canonical_names olson_link_names olson_all_names
	);
}

my $failures;

my $cnames = olson_canonical_names;
my $lnames = olson_link_names;
my $anames = olson_all_names;

foreach($cnames, $lnames, $anames) {
	is ref($_), "HASH";
	$failures = 0;
	foreach(keys %$_) {
		m#\A[0-9A-Za-z\-\+_]+(?:/[0-9A-Za-z\-\+_]+)*\z# or $failures++;
	}
	is $failures, 0;
	$failures = 0;
	foreach(values %$_) {
		!defined($_) or $failures++;
	}
	is $failures, 0;
}

foreach($cnames, $lnames) {
	$failures = 0;
	foreach(keys %$_) {
		exists($anames->{$_}) or $failures++;
	}
	is $failures, 0;
}

$failures = 0;
foreach(keys %$anames) {
	(exists($cnames->{$_})?1:0) + (exists($lnames->{$_})?1:0) == 1
		or $failures++;
}
is $failures, 0;

1;
