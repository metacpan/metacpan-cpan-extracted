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

use_ok( 'WWW::BigDoor::NamedGoodCollection' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'remove' );

my $named_good_collections = WWW::BigDoor::NamedGoodCollection->all( $client );

cmp_deeply( $named_good_collections, [], 'should be no named_good_collections at the beginning' );

my $named_good_collection_payload = {
    pub_title            => 'Test Named Good Collection',
    pub_description      => 'test description',
    end_user_title       => 'test user title',
    end_user_description => 'test user description',
};

my $named_good_collection = new WWW::BigDoor::NamedGoodCollection( $named_good_collection_payload );
cmp_deeply(
    $named_good_collection,
    bless(
        {
            pub_title            => 'Test Named Good Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
        },
        'WWW::BigDoor::NamedGoodCollection'
    ),
    '$named_good_collection matches deeply'
);

$named_good_collection->save( $client );
is( $client->get_response_code, 201, 'response for $named_good_collection->save matches' );

cmp_deeply(
    $named_good_collection,
    bless(
        {
            pub_title            => 'Test Named Good Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_goods          => ignore(),
            read_only            => 0,
            resource_name        => 'named_good_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedGoodCollection'
    ),
    '$named_good_collection matches'
);

my @named_goods_payloads = (
    {
        pub_title                => 'example good',
        pub_description          => 'something you can purchase',
        end_user_title           => 'example good',
        end_user_description     => 'something you can purchase',
        relative_weight          => 1,
        named_good_collection_id => $named_good_collection->get_id,
    }
);

use_ok( 'WWW::BigDoor::NamedGood' );
can_ok( 'WWW::BigDoor::NamedGood', 'new' );
can_ok( 'WWW::BigDoor::NamedGood', 'load' );
can_ok( 'WWW::BigDoor::NamedGood', 'save' );
can_ok( 'WWW::BigDoor::NamedGood', 'remove' );

foreach my $nlp ( @named_goods_payloads ) {
    my $nl = new WWW::BigDoor::NamedGood( $nlp );
    $nl->save( $client );
    is( $client->get_response_code, 201, 'response for WWW::BigDoor::NamedGood->save matches' );
    cmp_deeply(
        $nl,
        bless(
            {
                pub_title                => 'example good',
                pub_description          => 'something you can purchase',
                end_user_title           => 'example good',
                end_user_description     => 'something you can purchase',
                relative_weight          => 1,
                named_good_collection_id => $named_good_collection->get_id,
                attributes               => ignore(),
                created_timestamp        => re( '\d{10}' ),
                modified_timestamp       => re( '\d{10}' ),
                resource_name            => 'named_good',
                urls                     => [],
                id                       => re( '\d+' ),
                read_only                => 0,
                collection_uri           => re( 'named_good_collection' ),
            },
            'WWW::BigDoor::NamedGood'
        ),
        '$nl matches'
    );
} ## end foreach my $nlp ( @named_goods_payloads)

$named_good_collection->load( $client );
is( $client->get_response_code, 200,
    'response for WWW::BigDoor::NamedGoodCollection->load matches' );

cmp_deeply(
    $named_good_collection,
    bless(
        {
            pub_title            => 'Test Named Good Collection',
            pub_description      => 'test description',
            end_user_title       => 'test user title',
            end_user_description => 'test user description',
            attributes           => ignore(),
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_goods          => ignore(),
            read_only            => 0,
            resource_name        => 'named_good_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedGoodCollection'
    ),
    '$named_good_collection matches'
);

my $nlc;
dies_ok {
    $nlc = WWW::BigDoor::NamedGoodCollection->load( $client );
}
'should die because id missing';
lives_ok {
    $nlc = WWW::BigDoor::NamedGoodCollection->load( $client, $named_good_collection->get_id() );
}
'shouldn\'t die';
cmp_deeply( $nlc, $named_good_collection, 'objects are same' );

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

use_ok( 'WWW::BigDoor::Good' );
can_ok( 'WWW::BigDoor::Good', 'new' );
can_ok( 'WWW::BigDoor::Good', 'all' );
can_ok( 'WWW::BigDoor::Good', 'load' );
can_ok( 'WWW::BigDoor::Good', 'save' );
can_ok( 'WWW::BigDoor::Good', 'remove' );

can_ok( 'WWW::BigDoor::NamedGoodCollection', 'get_id' );
can_ok( 'WWW::BigDoor::NamedGoodCollection', 'get_named_goods' );

my $good = WWW::BigDoor::Good->new(
    {
        end_user_login => $username,
        named_good_id  => $nlc->get_named_goods->[0]->{'id'},
    }
);

$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response for end_user_obj->remove matches' );

$named_good_collection->remove( $client );
is( $client->get_response_code, 204, 'response for $named_good_collection->remove matches' );
