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
    Test::Most::plan( tests => 20 );
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

use_ok( 'WWW::BigDoor::URL' );
can_ok( 'WWW::BigDoor::URL', 'new' );
can_ok( 'WWW::BigDoor::URL', 'all' );
can_ok( 'WWW::BigDoor::URL', 'load' );
can_ok( 'WWW::BigDoor::URL', 'save' );
can_ok( 'WWW::BigDoor::URL', 'remove' );

my $urls = WWW::BigDoor::URL->all( $client );
cmp_deeply( $urls, [], 'should be zero urls at the beginning' );

my $url_payload = {
    pub_title            => 'Test URL',
    pub_description      => 'test description',
    end_user_title       => 'end user title',
    end_user_description => 'end user description',
    url                  => 'http://example.com/',
};
my $url_obj = new WWW::BigDoor::URL( $url_payload );

cmp_deeply(
    $url_obj,
    bless(
        {
            pub_title            => 'Test URL',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            url                  => 'http://example.com/',
        },
        'WWW::BigDoor::URL'
    ),
    'url_obj matches deeply'
);

$url_obj->save( $client );
is( $client->get_response_code, 201, 'response for url_obj->save matches' );

cmp_deeply(
    $url_obj,
    bless(
        {
            pub_title            => 'Test URL',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            attributes           => [],
            is_for_end_user_ui   => undef,
            is_media_url         => undef,
            resource_name        => 'url',
            modified_timestamp   => re( '\d{10}' ),
            created_timestamp    => re( '\d{10}' ),
            read_only            => 0,
            id                   => re( '\d+' ),
            url                  => 'http://example.com/',
        },
        'WWW::BigDoor::URL'
    ),
    'url_obj matches deeply'
);

use_ok( 'WWW::BigDoor::Currency' );

my $currency_obj = new WWW::BigDoor::Currency(
    {
        pub_title            => 'Coins',
        pub_description      => 'an example of the Purchase currency type',
        end_user_title       => 'Coins',
        end_user_description => 'can only be purchased',
        currency_type_id     => '1',                                          # FIXME hardcoded
        currency_type_title  => 'Purchase',
        exchange_rate        => 900.00,
        relative_weight      => 2,
    }
);

$currency_obj->save( $client );

cmp_deeply(
    $currency_obj,
    bless(
        {
            pub_title                 => 'Coins',
            pub_description           => 'an example of the Purchase currency type',
            end_user_title            => 'Coins',
            end_user_description      => 'can only be purchased',
            currency_type_id          => '1',
            currency_type_title       => 'Redeemable Purchase Currency',
            exchange_rate             => '900',
            relative_weight           => 2,
            id                        => re( '\d+' ),
            created_timestamp         => re( '\d+' ),
            modified_timestamp        => re( '\d+' ),
            currency_type_description => '',
            read_only                 => 0,
            resource_name             => 'currency',
            urls                      => [],
        },
        'WWW::BigDoor::Currency'
    ),
    'currency Object matches deeply'
);

can_ok( 'WWW::BigDoor::URL', 'associate_with' );

$url_obj->associate_with( $currency_obj, $client );

$currency_obj->remove( $client );
is( $client->get_response_code, 204, 'response for DELETE currency matches' );

$url_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for url_obj->remove matches' );

$urls = WWW::BigDoor::URL->all( $client );
cmp_deeply( $urls, [], 'should be zero urls at the end' );
