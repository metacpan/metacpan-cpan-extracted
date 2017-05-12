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
    Test::Most::plan( tests => 22 );
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

$response = $client->GET( 'currency' );
is( @$response,        2, 'response for GET currency matches' );
is( @{$response->[0]}, 0, 'response for GET currency matches' );

$response = $client->GET( 'currency_type' );
is( @{$response->[0]}, 9, 'response for GET currency_type matches' );

my $currency = {
    pub_title            => 'Coins ',
    pub_description      => 'an example of the Purchase currency type',
    end_user_title       => 'Coins',
    end_user_description => 'can only be purchased',
    currency_type_id     => '1',
    currency_type_title  => 'Purchase',
    exchange_rate        => 900.00,
    relative_weight      => 2,
};

$response = $client->POST( 'currency', {format => 'json'}, $currency );
is( @$response, 2, 'response for POST currency matches' );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                pub_title            => 'Coins ',
                pub_description      => 'an example of the Purchase currency type',
                end_user_title       => 'Coins',
                end_user_description => 'can only be purchased',
                currency_type_id     => '1',
                currency_type_title  => 'Redeemable Purchase Currency',
                exchange_rate        => 900.00,
                relative_weight      => 2,
                id                   => ignore(),
            }
        ),
        {}
    ],
    'response for POST currency matches deeply'
);

my $currency_id = $response->[0]->{'id'};

$currency->{'pub_title'} = 'Coins';

$response = $client->PUT( sprintf( 'currency/%s', $currency_id ), {format => 'json'}, $currency );
is( @$response, 2, 'response for PUT currency matches' );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                pub_title            => 'Coins',
                pub_description      => 'an example of the Purchase currency type',
                end_user_title       => 'Coins',
                end_user_description => 'can only be purchased',
                currency_type_id     => '1',
                currency_type_title  => 'Redeemable Purchase Currency',
                exchange_rate        => 900.00,
                relative_weight      => 2,
                id                   => ignore(),
            }
        ),
        {}
    ],
    'response for GET currency/{id} matches deeply'
);

$response = $client->GET( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                pub_title            => 'Coins',
                pub_description      => 'an example of the Purchase currency type',
                end_user_title       => 'Coins',
                end_user_description => 'can only be purchased',
                currency_type_id     => '1',
                currency_type_title  => 'Redeemable Purchase Currency',
                exchange_rate        => re( '^900(\.00)' ),
                relative_weight      => 2,
                id                   => ignore(),
            }
        ),
        {}
    ],
    'response for GET currency/{id} matches deeply'
);

$response = $client->GET( 'currency', {format => 'json'} );
is( @$response,        2, 'response for GET currency matches' );
is( @{$response->[0]}, 1, 'response for GET currency matches' );

$response = $client->DELETE( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
is( $response,                  undef, 'response for DELETE currency matches' );
is( $client->get_response_code, 204,   'response for DELETE currency matches' );

$response = $client->GET( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
is( $response,                  undef, 'response for DELETE currency matches' );
is( $client->get_response_code, 404,   'response for DELETE currency matches' );
