use warnings;
use strict;

BEGIN {
	eval { require IO::File; IO::File->VERSION(1.03); };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "no usable IO::File");
	}
}

use Test::More 0.41 tests => 2;

BEGIN { use_ok "Time::OlsonTZ::Data", qw(olson_canonical_names olson_tzfile); }

my $failures = 0;
foreach(sort keys %{olson_canonical_names()}) {
	my $f = olson_tzfile($_);
	my $h = IO::File->new($f, "r");
	unless($h) {
		diag "$_: failed to open $f";
		$failures++;
		next;
	}
	local $/ = \5;
	unless($h->getline =~ /\ATZif[2-9]\z/) {
		diag "$_: $f is not of version 2 or greater";
		$failures++;
	}
}
is $failures, 0;

1;
