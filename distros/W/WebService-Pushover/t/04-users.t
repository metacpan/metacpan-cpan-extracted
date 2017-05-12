#!perl -t

use warnings;
use strict;
use Test::More;
use Test::Deep;

use lib "t/lib";
use Test::MockPushover;


use_ok "WebService::Pushover" or BAIL_OUT "WebService::Pushover failed. Cannot continue testing";

my $API_TOKEN  = "abcdefghijklmnopqrstuvwxyz1234";
my $USER_TOKEN = "1234abcdefghijklmnopqrstuvwxyz";

spin_mock_server(user_token => $USER_TOKEN, api_token => $API_TOKEN);

my $user  = '0123abcdefghijklmnopqrstuvwxyz';
my $token = 'abcdefghijklmnopqrstuvwxyz0123';

pushover_ok 'user', {
	token   => $token,
	user    => $user,
},{
	headers => ignore,
	path    => '/1/users/validate.json',
	data    => {
		user    => $user,
		token   => $token,
	},
}, "passing tokens to user() overrides the built-ins";

pushover_ok 'user', {},{
	headers => ignore,
	path    => '/1/users/validate.json',
	data    => {
		user    => $USER_TOKEN,
		token   => $API_TOKEN,
	},
}, "passing no token/user to user() uses built-ins";

pushover_ok 'user', {
	device    => 'abcdefghijklmnopqrstuvwxy',
},{
	headers => ignore,
	path    => '/1/users/validate.json',
	data    => {
		device    => 'abcdefghijklmnopqrstuvwxy',
		token     => $API_TOKEN,
		user      => $USER_TOKEN,
	},
}, "user() with all the options gets generated properly";

done_testing;
