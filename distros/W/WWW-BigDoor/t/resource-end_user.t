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
    Test::Most::plan( tests => 26 );
}

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
can_ok( 'WWW::BigDoor::EndUser', 'new' );
can_ok( 'WWW::BigDoor::EndUser', 'all' );
can_ok( 'WWW::BigDoor::EndUser', 'load' );
can_ok( 'WWW::BigDoor::EndUser', 'save' );
can_ok( 'WWW::BigDoor::EndUser', 'remove' );

my $end_users = WWW::BigDoor::EndUser->all( $client );
cmp_deeply( $end_users, [], 'should be zero users at the beginning' );

my $username = Test::Mock::REST::Client::get_username();

my $end_user_payload = {end_user_login => $username,};
my $end_user_obj = new WWW::BigDoor::EndUser( $end_user_payload );

cmp_deeply(
    $end_user_obj,
    bless( {end_user_login => $username,}, 'WWW::BigDoor::EndUser' ),
    'end_user_obj matches deeply'
);

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

use_ok( 'WWW::BigDoor::Profile' );
can_ok( 'WWW::BigDoor::Profile', 'new' );
can_ok( 'WWW::BigDoor::Profile', 'all' );
can_ok( 'WWW::BigDoor::Profile', 'load' );
can_ok( 'WWW::BigDoor::Profile', 'save' );
can_ok( 'WWW::BigDoor::Profile', 'remove' );

my $profile_payload = {
    provider      => 'publisher',
    email         => 'end_user@example.com',
    first_name    => 'John',
    last_name     => 'Doe',
    display_name  => 'John Doe',
    profile_photo => 'http://example.com/image.jpg',
    example_key   => 'Example Value',
};

my $profile_obj = new WWW::BigDoor::Profile( $end_user_obj, $profile_payload );
cmp_deeply(
    $profile_obj,
    bless(
        {
            provider      => 'publisher',
            email         => 'end_user@example.com',
            first_name    => 'John',
            last_name     => 'Doe',
            display_name  => 'John Doe',
            profile_photo => 'http://example.com/image.jpg',
            example_key   => 'Example Value',
            end_user_obj  => bless(
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
            is_saved => 0,
        },
        'WWW::BigDoor::Profile',
    ),
    'profile_obj matches deeply'
);

$profile_obj->save( $client );
is( $client->get_response_code, 201, 'response for profile_obj->save matches' );
cmp_deeply(
    $profile_obj,
    bless(
        {
            provider      => 'publisher',
            email         => 'end_user@example.com',
            first_name    => 'John',
            last_name     => 'Doe',
            display_name  => 'John Doe',
            profile_photo => 'http://example.com/image.jpg',
            example_key   => 'Example Value',
            end_user_obj  => bless(
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
            is_saved => 1,
        },
        'WWW::BigDoor::Profile',
    ),
    'profile_obj matches deeply after save'
);

$profile_obj->remove( $client );
is( $client->get_response_code, 204, 'response for profile_obj->remove matches' );

$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response for end_user_obj->remove matches' );

$end_users = WWW::BigDoor::EndUser->all( $client );
cmp_deeply( $end_users, [], 'should be zero users at the end' );

