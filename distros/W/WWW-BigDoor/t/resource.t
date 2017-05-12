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
    Test::Most::plan( tests => 91 );
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

## Test Named Level Collection

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

my $named_level_collection = {
    pub_title            => 'test title',
    pub_description      => 'test description',
    end_user_title       => 'test user title',
    end_user_description => 'test user description',
    currency_id          => $currency_id,
};

$response = $client->GET( 'named_level_collection' );
foreach my $nlc ( @{$response->[0]} ) {
    $client->DELETE( sprintf 'named_level_collection/%s', $nlc->{'id'} );
    is( $client->get_response_code, 204, 'response for remove named_level_collection matches' );
}

$response = $client->POST( 'named_level_collection', {format => 'json'}, $named_level_collection );
cmp_deeply(
    $response,
    [
        {
            pub_title            => 'test title',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_id,
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_levels         => [],
            read_only            => 0,
            resource_name        => 'named_level_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        {}
    ],
    'response for POST named_level_collection matches'
);

my $named_level_collection_id = $response->[0]->{'id'};

use_ok( 'WWW::BigDoor::NamedLevelCollection' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'remove' );

my $named_level_collections = WWW::BigDoor::NamedLevelCollection->all( $client );
ok( defined $named_level_collections, '$named_level_collections defined' );
is( @$named_level_collections, 1, 'retrieved 1 named level collection' );

my $nlc = @$named_level_collections[0];

### $named_level_collections

ok( defined $nlc, 'there is defined NamedLevelCollection object' );
isa_ok( $nlc, 'WWW::BigDoor::NamedLevelCollection' );
isa_ok( $nlc, 'WWW::BigDoor::Resource' );

is( $nlc->get_pub_title,       'test title',       'NamedLevelCollection pub_title match' );
is( $nlc->get_pub_description, 'test description', 'nlc pub_descripton match' );
is( $nlc->get_end_user_title,  'test user title',  'nlc end_user_title match' );
is( $nlc->get_end_user_description, 'test user description', 'nlc end_user_description match' );
is( $nlc->get_currency_id,          $currency_id,            'currency_id matches' );

use_ok( 'WWW::BigDoor::NamedLevel' );
can_ok( 'WWW::BigDoor::NamedLevel', 'new' );
can_ok( 'WWW::BigDoor::NamedLevel', 'load' );

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
    cmp_deeply(
        $response,
        [
            superhashof(
                {
                    pub_title                 => re( 'level\d' ),
                    id                        => re( '\d+' ),
                    named_level_collection_id => $named_level_collection_id,
                }
            ),
            {}
        ],
        'response for POST named_level matches'
    );
}

$response = $client->GET( sprintf( 'named_level_collection/%s', $named_level_collection_id ) );
cmp_deeply(
    $response,
    [
        {
            pub_title            => 'test title',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_id,
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_levels         => ignore(),
            read_only            => 0,
            resource_name        => 'named_level_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        {}
    ],
    'response for GET named_level_collection matches'
);

$response = $client->GET( 'named_level' );

# FIXME
cmp_deeply(
    $response,
    [superbagof( superhashof( {resource_name => 'named_level',} ) ), {}],
    'response for GET named_level matches'
);

my $named_level_id = $response->[0][0]->{'id'};

#foreach my $nl ( @{$response->[0]}) {
#    $client->DELETE( sprintf 'named_level_collection/%s/named_level/%s', $nl->{'named_level_collection_id'}, $nl->{'id'});
#    is( $client->get_response_code, 204, 'response for remove named_level_collection/{id}/named_level/{id} matches' );
#}

my $named_level = WWW::BigDoor::NamedLevel->load( $client, $named_level_id );
is( $client->get_response_code, 200, 'NamedLevel load returns 200 code' );

isa_ok( $named_level, 'WWW::BigDoor::NamedLevel' );
isa_ok( $named_level, 'WWW::BigDoor::Resource' );

cmp_deeply(
    $named_level,
    bless(
        {
            pub_title                 => 'level1',
            pub_description           => 'level1 description',
            end_user_title            => 'novice',
            end_user_description      => "you don't know jack",
            attributes                => [],
            collection_uri            => re( 'named_level_collection' ),
            named_level_collection_id => $named_level_collection_id,
            threshold                 => undef,
            id                        => re( '\d+' ),
            created_timestamp         => re( '\d+' ),
            modified_timestamp        => re( '\d+' ),
            read_only                 => 0,
            resource_name             => 'named_level',
            urls                      => [],
        },
        'WWW::BigDoor::NamedLevel'
    ),
    'object NamedLevel matches deeply'
);

# FIXME
is( $named_level->get_named_level_collection_id,
    $named_level_collection_id, 'match named_level_collection_id' );

use_ok( 'WWW::BigDoor::NamedAwardCollection' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'remove' );

my $named_award_collection = {
    pub_title            => 'application achievements',
    pub_description      => 'a set of achievements that the user can earn',
    end_user_title       => 'achievements',
    end_user_description => 'things you can get',
};

$response = $client->POST( 'named_award_collection', {format => 'json'}, $named_award_collection );
is( @$response, 2, 'response for POST named_award_collection matches' );

my $named_award_collection_id = $response->[0]->{'id'};

my $named_award_collections = WWW::BigDoor::NamedAwardCollection->all( $client );
ok( defined $named_award_collections, '$named_award_collections defined' );
is( @$named_award_collections, 1, 'retrieved 1 named award collection' );

my $nac = @$named_award_collections[0];

ok( defined $nac, 'there is defined NamedAwardCollection object' );
isa_ok( $nac, 'WWW::BigDoor::NamedAwardCollection' );
isa_ok( $nac, 'WWW::BigDoor::Resource' );

is( $nac->get_pub_title, 'application achievements', 'pub_title match' );
is(
    $nac->get_pub_description,
    'a set of achievements that the user can earn',
    'pub_descripton match'
);
is( $nac->get_end_user_title,       'achievements',             'end_user_title match' );
is( $nac->get_end_user_description, 'things you can get',       'end_user_description match' );
is( $nac->get_id,                   $named_award_collection_id, 'id matches' );

my @named_awards = (
    {
        pub_title                 => 'obligatory early achievement ',
        pub_description           => 'the sort of achievement you get when you can turn on an xbox',
        end_user_title            => 'just breath',
        end_user_description      => 'congratulations you rock so hard; keep on breathing',
        relative_weight           => 1,
        named_award_collection_id => $named_award_collection_id,
    },
);

foreach my $named_award ( @named_awards ) {
    $response =
      $client->POST( sprintf( 'named_award_collection/%s/named_award', $named_award_collection_id ),
        {format => 'json'}, $named_award );
    is( @$response, 2, 'response for POST named_award matches' );
}
my $named_award_id = $response->[0]->{'id'};

### named_award_id

use_ok( 'WWW::BigDoor::NamedAward' );
can_ok( 'WWW::BigDoor::NamedAward', 'new' );
can_ok( 'WWW::BigDoor::NamedAward', 'load' );

my $named_award = WWW::BigDoor::NamedAward->load( $client, $named_award_id );

ok( defined $named_award, 'load returns defined object' );
isa_ok( $named_award, 'WWW::BigDoor::NamedAward' );
isa_ok( $named_award, 'WWW::BigDoor::Resource' );

is( $named_award->get_named_award_collection_id,
    $named_award_collection_id, 'match named_award_collection_id' );
is(
    $named_award->get_pub_title,
    'obligatory early achievement ',
    'match $named_award->get_pub_title'
);
is(
    $named_award->get_pub_description,
    'the sort of achievement you get when you can turn on an xbox',
    'match $named_award->get_pub_description'
);
is( $named_award->get_end_user_title, 'just breath', 'match $named_award->get_end_user_title' );
is(
    $named_award->get_end_user_description,
    'congratulations you rock so hard; keep on breathing',
    'match $named_award->get_end_user_description'
);
is( $named_award->get_id, $named_award_id, 'match $named_award->get_id' );

my $named_good_collection = {
    pub_title            => 'a bunch of goods the user can get',
    pub_description      => 'some goods',
    end_user_title       => 'goods you can get',
    end_user_description => 'goods',
};

$response = $client->POST( 'named_good_collection', {format => 'json'}, $named_good_collection );
is( @$response, 2, 'response for POST named_good_collection matches' );

use_ok( 'WWW::BigDoor::NamedGoodCollection' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'remove' );

my $named_good_collections = WWW::BigDoor::NamedGoodCollection->all( $client );
ok( defined $named_good_collections, '$named_good_collections defined' );
is( @$named_good_collections, 1, 'retrieved 1 named good collection' );

my $named_good_collection_id = $response->[0]->{'id'};

my @named_goods = (
    {
        pub_title                => 'example good',
        pub_description          => 'something you can purchase',
        end_user_title           => 'example good',
        end_user_description     => 'something you can purchase',
        relative_weight          => 1,
        named_good_collection_id => $named_good_collection_id,
    },
);

foreach my $named_good ( @named_goods ) {
    $response =
      $client->POST( sprintf( 'named_good_collection/%s/named_good', $named_good_collection_id ),
        {format => 'json'}, $named_good );
    is( @$response, 2, 'response for POST named_good matches' );
}
my $named_good_id = $response->[0]->{'id'};

use_ok( 'WWW::BigDoor::NamedGood' );
can_ok( 'WWW::BigDoor::NamedGood', 'new' );
can_ok( 'WWW::BigDoor::NamedGood', 'load' );

my $named_good = WWW::BigDoor::NamedGood->load( $client, $named_good_id );

isa_ok( $named_good, 'WWW::BigDoor::NamedGood' );
isa_ok( $named_good, 'WWW::BigDoor::Resource' );

is( $named_good->get_named_good_collection_id,
    $named_good_collection_id, 'match named_good_collection_id' );
is( $named_good->get_pub_title, 'example good', 'match $named_good->get_pub_title' );
is(
    $named_good->get_pub_description,
    'something you can purchase',
    'match $named_good->get_pub_description'
);
is( $named_good->get_end_user_title, 'example good', 'match $named_good->get_end_user_title' );
is(
    $named_good->get_end_user_description,
    'something you can purchase',
    'match $named_good->get_end_user_description'
);
is( $named_good->get_id, $named_good_id, 'match $named_good->get_id' );

$named_level_collections->[0]->remove( $client );
is( $client->get_response_code, 204, 'response for remove named_level_collection matches' );

$named_award_collections->[0]->remove( $client );
is( $client->get_response_code, 204, 'response for remove named_award_collection matches' );

$named_good_collections->[0]->remove( $client );
is( $client->get_response_code, 204, 'response for remove named_good_collection matches' );

$response = $client->DELETE( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
is( @$response, 0, 'response for DELETE currency matches' );

