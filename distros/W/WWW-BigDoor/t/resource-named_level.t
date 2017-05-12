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
    Test::Most::plan( tests => 53 );
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

use_ok( 'WWW::BigDoor::NamedLevelCollection' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'remove' );

my $named_level_collections = WWW::BigDoor::NamedLevelCollection->all( $client );

cmp_deeply( $named_level_collections, [], 'should be no named_level_collections at the beginning' );

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

my $named_level_collection_payload = {
    pub_title            => 'Test Named Level Collection',
    pub_description      => 'test description',
    end_user_title       => 'test user title',
    end_user_description => 'test user description',
    currency_id          => $currency_obj->get_id,
};

my $named_level_collection =
  new WWW::BigDoor::NamedLevelCollection( $named_level_collection_payload );
cmp_deeply(
    $named_level_collection,
    bless(
        {
            pub_title            => 'Test Named Level Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_obj->get_id,
        },
        'WWW::BigDoor::NamedLevelCollection'
    ),
    '$named_level_collection matches deeply'
);

$named_level_collection->save( $client );
is( $client->get_response_code, 201, 'response for $named_level_collection->save matches' );

cmp_deeply(
    $named_level_collection,
    bless(
        {
            pub_title            => 'Test Named Level Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_obj->get_id,
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_levels         => ignore(),
            read_only            => 0,
            resource_name        => 'named_level_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedLevelCollection'
    ),
    '$named_level_collection matches'
);

my @named_levels_payloads = (
    {
        pub_title                 => 'level1',
        pub_description           => 'level1 description',
        end_user_title            => 'novice',
        end_user_description      => "you don't know jack",
        named_level_collection_id => $named_level_collection->get_id,
    },
    {
        pub_title                 => 'level2',
        pub_description           => 'level2 description',
        end_user_title            => 'Neophyte',
        end_user_description      => "you kinda know something",
        named_level_collection_id => $named_level_collection->get_id,
    },
    {
        pub_title                 => 'level3',
        pub_description           => 'level3 description',
        end_user_title            => 'Expert',
        end_user_description      => "you rock",
        named_level_collection_id => $named_level_collection->get_id,
    },
);

use_ok( 'WWW::BigDoor::NamedLevel' );
can_ok( 'WWW::BigDoor::NamedLevel', 'new' );
can_ok( 'WWW::BigDoor::NamedLevel', 'load' );
can_ok( 'WWW::BigDoor::NamedLevel', 'save' );
can_ok( 'WWW::BigDoor::NamedLevel', 'remove' );

foreach my $nlp ( @named_levels_payloads ) {
    my $nl = new WWW::BigDoor::NamedLevel( $nlp );
    $nl->save( $client );
    is( $client->get_response_code, 201, 'response for WWW::BigDoor::NamedLevel->save matches' );
    cmp_deeply(
        $nl,
        bless(
            {
                pub_title                 => re( 'level\d+' ),
                pub_description           => re( 'level\d+ description' ),
                end_user_title            => ignore(),
                end_user_description      => ignore(),
                named_level_collection_id => $named_level_collection->get_id,
                attributes                => ignore(),
                created_timestamp         => re( '\d{10}' ),
                modified_timestamp        => re( '\d{10}' ),
                resource_name             => 'named_level',
                urls                      => [],
                id                        => re( '\d+' ),
                read_only                 => 0,
                threshold                 => undef,
                collection_uri            => re( 'named_level_collection' ),
            },
            'WWW::BigDoor::NamedLevel'
        ),
        '$nl matches'
    );
} ## end foreach my $nlp ( @named_levels_payloads)

$named_level_collection->load( $client );
is( $client->get_response_code, 200,
    'response for WWW::BigDoor::NamedLevelCollection->load matches' );

cmp_deeply(
    $named_level_collection,
    bless(
        {
            pub_title            => 'Test Named Level Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            currency_id          => $currency_obj->get_id,
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_levels         => ignore(),
            read_only            => 0,
            resource_name        => 'named_level_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedLevelCollection'
    ),
    '$named_level_collection matches'
);

my $nlc;
dies_ok {
    $nlc = WWW::BigDoor::NamedLevelCollection->load( $client );
}
'should die because id missing';
lives_ok {
    $nlc = WWW::BigDoor::NamedLevelCollection->load( $client, $named_level_collection->get_id() );
}
'shouldn\'t die';
cmp_deeply( $nlc, $named_level_collection, 'objects are same' );

use_ok( 'WWW::BigDoor::EndUser' );
can_ok( 'WWW::BigDoor::EndUser', 'new' );
can_ok( 'WWW::BigDoor::EndUser', 'all' );
can_ok( 'WWW::BigDoor::EndUser', 'load' );
can_ok( 'WWW::BigDoor::EndUser', 'save' );
can_ok( 'WWW::BigDoor::EndUser', 'remove' );

my $username = Test::Mock::REST::Client::get_username();

my $end_user_payload = {end_user_login => $username,};
my $end_user_obj = new WWW::BigDoor::EndUser( $end_user_payload );

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

use_ok( 'WWW::BigDoor::Level' );
can_ok( 'WWW::BigDoor::Level', 'new' );
can_ok( 'WWW::BigDoor::Level', 'all' );
can_ok( 'WWW::BigDoor::Level', 'load' );
can_ok( 'WWW::BigDoor::Level', 'save' );
can_ok( 'WWW::BigDoor::Level', 'remove' );

can_ok( 'WWW::BigDoor::NamedLevelCollection', 'get_id' );
can_ok( 'WWW::BigDoor::NamedLevelCollection', 'get_named_levels' );

my $level = WWW::BigDoor::Level->new(
    {
        end_user_login => $username,
        named_level_id => $nlc->get_named_levels->[0]->{'id'},
    }
);

$level->save( $client );
is( $client->get_response_code, 201, 'response code for level->save matches' );
cmp_deeply(
    $level,
    bless(
        {
            modified_timestamp   => re( '\d{10}' ),
            created_timestamp    => re( '\d{10}' ),
            end_user_login       => $username,
            id                   => re( '\d+' ),
            named_level_id       => $nlc->get_named_levels->[0]->{'id'},
            read_only            => 0,
            resource_name        => 'level',
            transaction_group_id => undef
        },
        'WWW::BigDoor::Level'
    ),
    'resposne for level->save matches'
);

$level->remove( $client );
is( $client->get_response_code, 204, 'response for level->remove matches' );

$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response for end_user_obj->remove matches' );

$named_level_collection->remove( $client );
is( $client->get_response_code, 204, 'response for $named_level_collection->remove matches' );

$currency_obj->remove( $client );
is( $client->get_response_code, 204, 'response for $currency_obj->remove matches' );
