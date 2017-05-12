#!perl -T

use Test::More;

my $api_key    = $ENV{API_KEY}    || 'abc-test' ;
my $api_secret = $ENV{API_SECRET} || 'cde-secret';

plan tests => 4;

use_ok( 'YellowBot::API' );

ok(my $api = YellowBot::API->new
   (api_key    => $api_key,
    api_secret => $api_secret,
   ), 'new');

$api->server($ENV{API_SERVER} || 'http://www.yellowbot.com/');

ok(my $url = $api->signin_url("brand" => "yellowbot", api_user_identifier => "abc123" ), 'create url');
like($url, qr{signin/partner.*api_user_identifier=abc123}, "got a partner signin url");


