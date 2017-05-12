#!/usr/bin/env perl

use warnings;
use strict;
use lib qw(.. .);

use Test::More tests => 1;
use TestLib qw(try);

{ my $output = try(
		[ Alias => "possibly not, seeing as the code is insane" ],
		[ mauke => "but it works! :-)" ],
		[ dngor => "Therefore Perl is insane." ],
	);
	is_deeply(
		$output,
		[ [ "a", undef ],
			[ "b", undef ],
			[ "c", "a" ],
		],
		"simple test"
	);
}

exit;
