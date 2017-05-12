#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Pushover;
use Test::More;
use Test::Deep;

BEGIN {
	plan skip_all => "Integration tests disabled unless both PUSHOVER_API_TOKEN"
		." and PUSHOVER_USER_TOKEN environment variables are set"
			unless $ENV{PUSHOVER_API_TOKEN} && $ENV{PUSHOVER_USER_TOKEN};
}

my $api = WebService::Pushover->new(
	api_token => $ENV{PUSHOVER_API_TOKEN},
	user_token => $ENV{PUSHOVER_USER_TOKEN}
) or BAIL_OUT("Couldn't instantiate the WebService::Pushover object. Testing cannot continue");

my $res = $api->message(message => "Test message");
cmp_deeply($res, superhashof({ status => 1 }), "Basic message() call succeeded")
	or diag explain $res;

$res = $api->message(
	message   => q|test message: abcdefghijklmnopqrstuvwxyz01234567889!@#$%^&*()-=_+`~[]\\{}\|;:'"/?.><|,
	sound     => "bike",
	timestamp => 42,
	priority  => 2,
	retry     => 30,
	expire    => 30);
cmp_deeply($res, superhashof({ status => 1, receipt => re(qr/^\w+$/) }),
	"Advanced message() call succeeded") or diag explain $res;

$res = $api->receipt(receipt => $res->{receipt});
cmp_deeply($res, superhashof({ status => 1 }),
	"receipt() call based on previous high priority message succeeded") or diag explain $res;

$res = $api->user();
cmp_deeply($res, superhashof({ status => 1 }), "user() call succeeded") or diag explain $res;

$res = $api->sounds();
cmp_deeply($res, superhashof({ status => 1, sounds => ignore }), "sounds() call succeeded")
	or diag explain $res;

done_testing;
