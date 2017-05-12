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
    Test::Most::plan( tests => 43 );
}

#use Smart::Comments -ENV;

## Setup
## TODO move to module

if ( ( exists $ENV{BIGDOOR_TEST_SAVE_RESPONSES} || exists $ENV{BIGDOOR_TEST_LIVESERVER} )
    && !( exists $ENV{BIGDOOR_API_KEY} && exists $ENV{BIGDOOR_API_SECRET} ) )
{
    warn
"ENV{BIGDOOR_API_KEY} and/or ENV{BIGDOOR_API_SECRET} undefined while running against live server";
}

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

use_ok( 'WWW::BigDoor::CurrencyType' );
can_ok( 'WWW::BigDoor::CurrencyType', 'new' );
can_ok( 'WWW::BigDoor::CurrencyType', 'all' );

my $currency_types = WWW::BigDoor::CurrencyType->all( $client );
is( @{$currency_types}, 9, 'should be 9 currency types at the beginning' );

foreach my $currency_type ( @{$currency_types} ) {
    cmp_deeply(
        $currency_type,
        bless(
            {
                title                              => re( 'Points|Currency' ),
                description                        => '',
                has_dollar_exchange_rate_integrity => re( '[01]' ),
                can_be_cross_publisher             => re( '[01]' ),
                can_be_purchased                   => re( '[01]' ),
                can_be_rewarded                    => re( '[01]' ),
                id                                 => re( '\d+' ),
                created_timestamp                  => re( '\d+' ),
                modified_timestamp                 => re( '\d+' ),
                resource_name                      => 'currency_type',
                read_only                          => 0,
            },
            'WWW::BigDoor::CurrencyType'
        ),
        'currency type matches deeply'
    );
}

my $currency_type1 = WWW::BigDoor::CurrencyType->load( $client, 1 );
cmp_deeply(
    $currency_type1,
    bless(
        {
            title                              => 'Redeemable Purchase Currency',
            description                        => '',
            has_dollar_exchange_rate_integrity => 1,
            can_be_cross_publisher             => 0,
            can_be_purchased                   => 1,
            can_be_rewarded                    => 0,
            id                                 => re( '\d+' ),
            created_timestamp                  => re( '\d+' ),
            modified_timestamp                 => re( '\d+' ),
            resource_name                      => 'currency_type',
            read_only                          => 0,
        },
        'WWW::BigDoor::CurrencyType'
    ),
    'currency type 1 matches deeply'
);

use_ok( 'WWW::BigDoor::Currency' );
can_ok( 'WWW::BigDoor::Currency', 'new' );
can_ok( 'WWW::BigDoor::Currency', 'all' );
can_ok( 'WWW::BigDoor::Currency', 'load' );
can_ok( 'WWW::BigDoor::Currency', 'save' );
can_ok( 'WWW::BigDoor::Currency', 'remove' );

my $currencies = WWW::BigDoor::Currency->all( $client );
cmp_deeply( $currencies, [], 'should be zero currencies at the beginning' );

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

cmp_deeply(
    $currency_obj,
    bless(
        {
            pub_title            => 'Coins',
            pub_description      => 'an example of the Purchase currency type',
            end_user_title       => 'Coins',
            end_user_description => 'can only be purchased',
            currency_type_id     => '1',
            currency_type_title  => 'Purchase',
            exchange_rate        => '900',
            relative_weight      => 2,
        },
        'WWW::BigDoor::Currency'
    ),
    'currency Object matches deeply'
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

$currencies = WWW::BigDoor::Currency->all( $client );

cmp_deeply(
    $currencies,
    [
        bless(
            {
                pub_title                 => 'Coins',
                pub_description           => 'an example of the Purchase currency type',
                end_user_title            => 'Coins',
                end_user_description      => 'can only be purchased',
                currency_type_id          => '1',
                currency_type_title       => 'Redeemable Purchase Currency',
                exchange_rate             => '900.00',
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
        )
    ],
    'object Currency matches deeply'
);

my $currency = @$currencies[0];    # first
isa_ok( $currency, 'WWW::BigDoor::Currency' );
isa_ok( $currency, 'WWW::BigDoor::Resource' );

is( $currency->get_pub_title, 'Coins', 'Currency pub_title match' );
is(
    $currency->get_pub_description,
    'an example of the Purchase currency type',
    'currency pub_descripton match'
);
is( $currency->get_end_user_title, 'Coins', 'currency end_user_title match' );
is(
    $currency->get_end_user_description,
    'can only be purchased',
    'currency end_user_description match'
);
is( $currency->get_currency_type_id, 1, 'currency_type_id' );
is( $currency->get_currency_type_title, 'Redeemable Purchase Currency', 'currency_type_title' );
is( $currency->get_currency_type_description, q{},                   'currency_type_description' );
is( $currency->get_exchange_rate,             '900.00',              'exchange_rate matches' );
is( $currency->get_relative_weight,           2,                     'realtive_weight matches' );
is( $currency->get_id,                        $currency_obj->get_id, 'ids match' );

$currency->remove( $client );
is( $client->get_response_code, 204, 'response for DELETE currency matches' );

$currency_obj->remove( $client );
is( $client->get_response_code, 204, 'response for DELETE currency matches' );

$currencies = WWW::BigDoor::Currency->all( $client );
cmp_deeply( $currencies, [], 'should be zero currencies at the end' );
