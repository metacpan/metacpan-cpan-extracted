use strict;
use warnings;

use lib 't/lib';
use Test::Mock::REST::Client;
use Test::Most;

if ( Test::Mock::REST::Client::missing_responses ) {
    Test::Most::plan(
        skip_all =>
          sprintf(
"missing saved HTTP responses in %s, rerun tests with environment variable BIGDOOR_TEST_SAVE_RESPONSES defined",
            $Test::Mock::REST::Client::response_directory )
    );
}
elsif ( ( exists $ENV{BIGDOOR_TEST_SAVE_RESPONSES} || exists $ENV{BIGDOOR_TEST_LIVESERVER} )
    && !( exists $ENV{BIGDOOR_API_KEY} && exists $ENV{BIGDOOR_API_SECRET} ) )
{
    Test::Most::plan( skip_all =>
"ENV{BIGDOOR_API_KEY} and/or ENV{BIGDOOR_API_SECRET} undefined while running against live server"
    );
}
else {
    Test::Most::plan( tests => 8 );
}

#use Smart::Comments -ENV;

our $TEST_APP_KEY    = $ENV{BIGDOOR_API_KEY}    || '28d3da80bf36fad415ab57b3130c6cb6';
our $TEST_APP_SECRET = $ENV{BIGDOOR_API_SECRET} || 'B66F956ED83AE218612CB0FBAC2EF01C';

my $module = 'WWW::BigDoor';

use_ok( $module );
can_ok( $module, 'new' );

my $client = new WWW::BigDoor( $TEST_APP_SECRET, $TEST_APP_KEY );

isa_ok( $client, $module );
can_ok( $module, 'GET' );
can_ok( $module, 'POST' );
can_ok( $module, 'PUT' );
can_ok( $module, 'DELETE' );

my $restclient = Test::Mock::REST::Client::setup_mock( $client );
use_ok( 'REST::Client' );

my $response;

$response = $client->GET( 'transaction_summary' );

# FIXME
#cmp_deeply( $response, [[], {}], 'response for GET transaction_summary matches' );

# TODO
# check if time present in params/payload
# check if sig present in params
# check if token present in payload
# check if delete_token present if method DELETE
# check if token is 32 len and [0-9A-Fa-f]
# check if time is [0-9.]
# check if sig is ? len and [0-9a-f]
# check if JSON returned is well formed
# check if JSON returned matches expected

$response = $client->GET( 'award_summary' );

# FIXME
#cmp_deeply( $response, [[], {}], 'response for GET award_summary matches' );

$response = $client->GET( 'level_summary' );

# FIXME
#cmp_deeply( $response, [[], {}], 'response for GET level_summary matches' );

$response = $client->GET( 'good_summary' );
#cmp_deeply( $response, [[], {}], 'response for GET good_summary matches' );

#$response = $client->GET( sprintf ('end_user/%s', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id} matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id} matches' );

#$response = $client->GET( sprintf ('end_user/%s/profile', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id}/profile matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id}/profile matches' );

#$response = $client->GET( sprintf ('end_user/%s/currency_balance', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id}/currency_balance matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id}/currency_balance matches' );

#$response = $client->GET( sprintf ('end_user/%s/level', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id}/level matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id}/level matches' );

#$response = $client->GET( sprintf ('end_user/%s/award', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id}/award matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id}/award matches' );

#$response = $client->GET( sprintf ('end_user/%s/good', $end_user_login) );
#is( @$response, 2, 'response for GET end_user/{user_id}/good matches' );
#is( @{$response->[0]}, 0, 'response for GET end_user/{user_id}/good matches' );
