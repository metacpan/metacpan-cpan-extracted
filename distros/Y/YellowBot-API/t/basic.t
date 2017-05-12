#!perl -T

use Test::More;

my $api_key    = $ENV{API_KEY};
my $api_secret = $ENV{API_SECRET};

plan skip_all => "API_KEY and API_SECRET environment variables must be set"
    unless $api_key and $api_secret;

plan tests => 10;

use_ok( 'YellowBot::API' );

ok(my $api = YellowBot::API->new
   (api_key    => $api_key,
    api_secret => $api_secret,
   ), 'new');

$api->server($ENV{API_SERVER} || 'http://www.yellowbot.com/');

ok(my $data = $api->call('test/echo', foo => 'bar', abc => 123), 'call echo');
is($data->{foo}, 'bar', 'got response echoed back');

ok($data = $api->call('test/echo',
                          api_user_identifier => 'abcd', 
                          foo => 'bar',
                          abc => 123),
   'call echo with user');

is($data->{foo}, 'bar', 'got response echoed back again');

ok($data = $api->call('test/user_token',
                             api_user_identifier => 'abcd'),
   'call user_token with user');

ok($data->{user_token}, "Got user token: " . $data->{message});

ok($data = $api->call('test/user_token'),
   'call user_token with user');

ok(!$data->{user_token}, "No token: " . $data->{message});

