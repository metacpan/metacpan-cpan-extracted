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

pushover_ok 'message', {
	token   => $token,
	user    => $user,
	message => "test message",
},{
	headers => ignore,
	path    => '/1/messages.json',
	data    => {
		message => 'test+message',
		user    => $user,
		token   => $token,
	},
}, "passing tokens to message() overrides the built-ins";

pushover_ok 'message', {
	message => "test message",
},{
	headers => ignore,
	path    => '/1/messages.json',
	data    => {
		message => 'test+message',
		user    => $USER_TOKEN,
		token   => $API_TOKEN,
	},
}, "passing no token/user to message() uses built-ins";

pushover_ok 'message', {
	message => q|abcdefghijklmnopqrstuvwxyz01234567889!@#$%^&*()-=_+`~[]\\{}\|;:'"/?.><|,
},{
	headers => ignore,
	path    => '/1/messages.json',
	data    => superhashof({
		message => q|abcdefghijklmnopqrstuvwxyz01234567889!%40%23%24%25%5E%26*()-%3D_%2B%60~%5B%5D%5C%7B%7D%7C%3B%3A'%22%2F%3F.%3E%3C|,
	}),
}, "Odd characters are escaped properly";

pushover_ok 'message', {
	message   => 'test',
	device    => 'abcdefghijklmnopqrstuvwxy',
	title     => 'Title',
	timestamp => 0,
	priority  => -1,
	retry     => 300,
	expire    => 1,
	callback  => 'http://asdf.com',
	url       => 'http://perl.org',
	url_title => 'Perl!',
	sound     => 'bugle',
},{
	headers => ignore,
	path    => '/1/messages.json',
	data    => {
		message   => 'test',
		device    => 'abcdefghijklmnopqrstuvwxy',
		title     => 'Title',
		timestamp => 0,
		priority  => -1,
		retry     => 300,
		expire    => 1,
		callback  => 'http%3A%2F%2Fasdf.com',
		url       => 'http%3A%2F%2Fperl.org',
		url_title => 'Perl!',
		sound     => 'bugle',
		token     => $API_TOKEN,
		user      => $USER_TOKEN,
	},
}, "message() with all the options gets generated properly";

done_testing;
