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
    Test::Most::plan( tests => 18 );
}

use JSON;
#use Smart::Comments -ENV;

## Setup

## TODO move to module
our $TEST_APP_KEY    = $ENV{BIGDOOR_API_KEY}    || '28d3da80bf36fad415ab57b3130c6cb6';
our $TEST_APP_SECRET = $ENV{BIGDOOR_API_SECRET} || 'B66F956ED83AE218612CB0FBAC2EF01C';

my $module = 'WWW::BigDoor';

use_ok( $module );
can_ok( $module, 'new' );

my $client = new WWW::BigDoor( $TEST_APP_SECRET, $TEST_APP_KEY );

isa_ok( $client, $module );

## Setup

my $restclient = Test::Mock::REST::Client::setup_mock( $client );
use_ok( 'REST::Client' );

my $response;

use_ok( 'WWW::BigDoor::EndUser' );

my $username = Test::Mock::REST::Client::get_username();

my $end_user_payload = {end_user_login => $username,};

can_ok( 'WWW::BigDoor::EndUser', 'new' );
my $end_user_obj = new WWW::BigDoor::EndUser( $end_user_payload );

can_ok( 'WWW::BigDoor::EndUser', 'save' );
$end_user_obj->save( $client );
is( $client->get_response_code, 200, 'response for end_user_obj->save matches' );

cmp_deeply(
    $end_user_obj,
    bless(
        {
            end_user_login          => $username,
            best_guess_name         => $username,
            guid                    => ignore(),
            read_only               => 0,
            resource_name           => 'end_user',
            best_guess_profile_img  => undef,
            award_summaries         => [],
            level_summaries         => [],
            sent_good_summaries     => [],
            currency_balances       => [],
            received_good_summaries => [],
            modified_timestamp      => re( '\d{10}' ),
            created_timestamp       => re( '\d{10}' ),
        },
        'WWW::BigDoor::EndUser'
    ),
    'end_user_obj matches deeply'
);

use_ok( 'WWW::BigDoor::CurrencyBalance' );
can_ok( 'WWW::BigDoor::CurrencyBalance', 'new' );

my $currency_balance_obj = new WWW::BigDoor::CurrencyBalance( $end_user_obj, {} );
cmp_deeply(
    $currency_balance_obj,
    bless(
        {
            end_user_obj => bless(
                {
                    end_user_login          => $username,
                    best_guess_name         => $username,
                    guid                    => ignore(),
                    read_only               => 0,
                    resource_name           => 'end_user',
                    best_guess_profile_img  => undef,
                    award_summaries         => [],
                    level_summaries         => [],
                    sent_good_summaries     => [],
                    currency_balances       => [],
                    received_good_summaries => [],
                    modified_timestamp      => re( '\d{10}' ),
                    created_timestamp       => re( '\d{10}' ),
                },
                'WWW::BigDoor::EndUser'
            ),
        },
        'WWW::BigDoor::CurrencyBalance'
    ),
    'currency_balance_obj matches deeply after new'
);

can_ok( 'WWW::BigDoor::CurrencyBalance', 'all' );

my $currency_balances = WWW::BigDoor::CurrencyBalance->all( $client, $end_user_obj );
is( $client->get_response_code, 200,
    'response code for my $currency_balances = WWW::BigDoor::CurrencyBalance->all matches' );
cmp_deeply( $currency_balances, [], 'currency_balances matches deeply after ->all' );

can_ok( 'WWW::BigDoor::CurrencyBalance', 'load' );

can_ok( 'WWW::BigDoor::EndUser', 'remove' );
$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for end_user_obj->remove matches' );

