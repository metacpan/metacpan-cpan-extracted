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

pushover_ok 'receipt', {
	receipt => 'myreceipt001234567890123456789',
	token   => $token,
},{
	headers => ignore,
	path    => '/1/receipts/myreceipt001234567890123456789.json',
	data    => {
		token   => $token,
	},
}, "passing tokens to receipts() overrides the built-ins";

pushover_ok 'receipt', {
	receipt => 'myreceipt001234567890123456789',
},{
	headers => ignore,
	path    => '/1/receipts/myreceipt001234567890123456789.json',
	data    => {
		token   => $API_TOKEN,
	},
}, "passing no token/user to receipts() uses built-ins";

done_testing;
