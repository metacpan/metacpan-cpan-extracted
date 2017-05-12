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
    Test::Most::plan( tests => 31 );
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

my $payload = {
    pub_title            => 'Coins',
    pub_description      => 'an example of the Purchase currency type',
    end_user_title       => 'Coins',
    end_user_description => 'can only be purchased',
    currency_type_id     => '1',                                          # FIXME hardcoded
    currency_type_title  => 'Purchase',
    exchange_rate        => 900.00,
    relative_weight      => 2,
};

$response = $client->POST( 'currency', {format => 'json'}, $payload );
is( @$response, 2, 'response for POST currency matches' );
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
    'response for POST currency matches deeply'
);

my $currency_id = $response->[0]->{'id'};

$response = $client->GET( 'level_summary' );

# FIXME
#cmp_deeply( $response, [[], {}], 'response for GET level_summary matches' );

$response = $client->GET( 'named_level_collection' );
cmp_deeply( $response, [[], {}], 'should return zero at the beginning' );
is( $client->get_response_code, 200, 'response for GET named_level_collection matches' );

my $named_level_collection = {
    pub_title            => 'test title',
    pub_description      => 'test description',
    end_user_title       => 'test user title',
    end_user_description => 'test user description',
    currency_id          => $currency_id,
};

$response = $client->POST( 'named_level_collection', {format => 'json'}, $named_level_collection );
is( @$response, 2, 'response for POST named_level_collection matches' );

my $named_level_collection_id = $response->[0]->{'id'};

my @named_levels = (
    {
        pub_title                 => 'level1',
        pub_description           => 'level1 description',
        end_user_title            => 'novice',
        end_user_description      => "you don't know jack",
        named_level_collection_id => $named_level_collection_id,
    },
    {
        pub_title                 => 'level2',
        pub_description           => 'level2 description',
        end_user_title            => 'Neophyte',
        end_user_description      => "you kinda know something",
        named_level_collection_id => $named_level_collection_id,

    },
    {
        pub_title                 => 'level3',
        pub_description           => 'level3 description',
        end_user_title            => 'Expert',
        end_user_description      => "you rock",
        named_level_collection_id => $named_level_collection_id,

    },
);

foreach my $named_level ( @named_levels ) {
    $response =
      $client->POST( sprintf( 'named_level_collection/%s/named_level', $named_level_collection_id ),
        {format => 'json'}, $named_level );
    is( $client->get_response_code, 201,
        'response for POST named_level_collection/{id}/named_level matches' );
    cmp_deeply(
        $response,
        [
            superhashof(
                {
                    resource_name      => 'named_level',
                    attributes         => [],
                    urls               => [],
                    created_timestamp  => re( '\d{10}' ),
                    modified_timestamp => re( '\d{10}' ),
                    read_only          => 0,
                    id                 => re( '\d+' ),
                }
            ),
            {}
        ],
        'response for POST named_level matches'
    );
} ## end foreach my $named_level ( @named_levels)

$response = $client->GET( sprintf( 'named_level_collection/%s', $named_level_collection_id ) );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                pub_title            => 'test title',
                pub_description      => 'test description',
                end_user_title       => 'test user title',
                end_user_description => 'test user description',
                currency_id          => $currency_id,
                resource_name        => 'named_level_collection',
                attributes           => [],
                urls                 => [],
                created_timestamp    => re( '\d{10}' ),
                modified_timestamp   => re( '\d{10}' ),
                read_only            => 0,
                id                   => re( '\d+' ),
            }
        ),
        {}
    ],
    'response for GET named_level_collection matches'
);
is( $client->get_response_code, 200, 'response for GET named_level_collection/{id} matches' );

$response = $client->GET( 'named_level' );
#is( @{$response->[0]}, 3, 'should return 3 named_level' );

foreach my $nl ( @{$response->[0]} ) {
    $client->DELETE(
        sprintf 'named_level_collection/%s/named_level/%s',
        $nl->{'named_level_collection_id'},
        $nl->{'id'}
    );
    is( $client->get_response_code, 204,
        'response for remove named_level_collection/{id}/named_level/{id} matches' );
}

$response = $client->DELETE( sprintf( 'named_level_collection/%s', $named_level_collection_id ) );
is( $response,                  undef, 'response for DELETE named_level_collection/{id} matches' );
is( $client->get_response_code, 204,   'response for DELETE named_level_collection/{id} matches' );

$response = $client->DELETE( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
is( $response,                  undef, 'response for DELETE currency matches' );
is( $client->get_response_code, 204,   'response for DELETE currency matches' );
