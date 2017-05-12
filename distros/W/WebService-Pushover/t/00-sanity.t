#!perl -t

use warnings;
use strict;
use Test::More;
use Test::Deep;

use_ok "WebService::Pushover" or BAIL_OUT "WebService::Pushover failed. Cannot continue testing";

my $API_TOKEN  = "abcdefghijklmnopqrstuvwxyz1234";
my $USER_TOKEN = "1234abcdefghijklmnopqrstuvwxyz";

subtest "Basic pushover object creation" => sub {
	my $push = WebService::Pushover->new();
	isa_ok $push, "WebService::Pushover", "new() created object of correct class";
	is $push->api_token,  undef, "api_token isn't set unless provided";
	is $push->user_token, undef, "user_token isn't set unless provided";
	is $push->debug, 0, "debug is 0 by default";
};

subtest "Enabling debugging" => sub {
	my $push = WebService::Pushover->new(debug => 1);
	is $push->debug, 1, "Debug gets set properly";
	$push = WebService::Pushover->new(debug => 'asdf');
	is $push->debug, 1, "debug is coerced into '1' for a true value";

	$push = WebService::Pushover->new(debug => 0);
	is $push->debug, 0, "debug is disabled properly";
	$push = WebService::Pushover->new(debug => '');
	is $push->debug, 0, "debug is coerced into '0' for a false value";
};

subtest "Setting default tokens" => sub {
	my $push = WebService::Pushover->new(api_token => $API_TOKEN, user_token => $USER_TOKEN);
	is $push->{api_token}, $API_TOKEN, "api_token gets set properly";
	is $push->{user_token}, $USER_TOKEN, "user_token gets set properly";
};

done_testing;
