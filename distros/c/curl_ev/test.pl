use strict;
use warnings;

use Test::More tests => 1;


SKIP: {
	eval {
		require Net::Curl::Multi;
		Net::Curl::Multi->can('CURLMOPT_TIMERFUNCTION') or
		die "Net::Curl::Multi is missing timer callback. Rebuild Net::Curl with libcurl 7.16.0 or newer\n";
	};

	skip "Net::Curl::Multi::EV: $@", 1 if $@;
	require_ok('Net::Curl::Multi::EV');
};
