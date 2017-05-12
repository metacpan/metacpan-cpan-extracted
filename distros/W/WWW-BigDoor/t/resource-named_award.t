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
    Test::Most::plan( tests => 46 );
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

use_ok( 'WWW::BigDoor::NamedAwardCollection' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'new' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'all' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'save' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'remove' );

my $named_award_collections = WWW::BigDoor::NamedAwardCollection->all( $client );

cmp_deeply( $named_award_collections, [], 'should be no named_award_collections at the beginning' );

my $named_award_collection_payload = {
    pub_title            => 'application achievements',
    pub_description      => 'a set of achievements that the user can earn',
    end_user_title       => 'achievements',
    end_user_description => 'things you can get',
};

my $named_award_collection =
  new WWW::BigDoor::NamedAwardCollection( $named_award_collection_payload );
cmp_deeply(
    $named_award_collection,
    bless(
        {
            pub_title            => 'application achievements',
            pub_description      => 'a set of achievements that the user can earn',
            end_user_title       => 'achievements',
            end_user_description => 'things you can get',
        },
        'WWW::BigDoor::NamedAwardCollection'
    ),
    '$named_award_collection matches deeply'
);

$named_award_collection->save( $client );
is( $client->get_response_code, 201, 'response for $named_award_collection->save matches' );

cmp_deeply(
    $named_award_collection,
    bless(
        {
            pub_title            => 'application achievements',
            pub_description      => 'a set of achievements that the user can earn',
            end_user_title       => 'achievements',
            end_user_description => 'things you can get',
            non_secure           => 0,
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_awards         => ignore(),
            read_only            => 0,
            resource_name        => 'named_award_collection',
            urls                 => [],
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedAwardCollection'
    ),
    '$named_award_collection matches'
);

my @named_awards_payloads = (
    {
        pub_title                 => 'obligatory early achievement ',
        pub_description           => 'the sort of achievement you get when you can turn on an xbox',
        end_user_title            => 'just breath',
        end_user_description      => 'congratulations you rock so hard; keep on breathing',
        relative_weight           => 1,
        named_award_collection_id => $named_award_collection->get_id,
    },
);

use_ok( 'WWW::BigDoor::NamedAward' );
can_ok( 'WWW::BigDoor::NamedAward', 'new' );
can_ok( 'WWW::BigDoor::NamedAward', 'load' );
can_ok( 'WWW::BigDoor::NamedAward', 'save' );
can_ok( 'WWW::BigDoor::NamedAward', 'remove' );

foreach my $nlp ( @named_awards_payloads ) {
    my $nl = new WWW::BigDoor::NamedAward( $nlp );
    $nl->save( $client );
    is( $client->get_response_code, 201, 'response for WWW::BigDoor::NamedAward->save matches' );
    cmp_deeply(
        $nl,
        bless(
            {
                pub_title       => 'obligatory early achievement ',
                pub_description => 'the sort of achievement you get when you can turn on an xbox',
                end_user_title  => 'just breath',
                end_user_description      => 'congratulations you rock so hard; keep on breathing',
                relative_weight           => 1,
                named_award_collection_id => $named_award_collection->get_id,
                created_timestamp         => re( '\d{10}' ),
                modified_timestamp        => re( '\d{10}' ),
                resource_name             => 'named_award',
                urls                      => [],
                id                        => re( '\d+' ),
                read_only                 => 0,
                collection_uri            => re( 'named_award_collection' ),
            },
            'WWW::BigDoor::NamedAward'
        ),
        '$nl matches'
    );
} ## end foreach my $nlp ( @named_awards_payloads)

$named_award_collection->load( $client );
is( $client->get_response_code, 200,
    'response for WWW::BigDoor::NamedAwardCollection->load matches' );

cmp_deeply(
    $named_award_collection,
    bless(
        {
            pub_title            => 'application achievements',
            pub_description      => 'a set of achievements that the user can earn',
            end_user_title       => 'achievements',
            end_user_description => 'things you can get',
            created_timestamp    => re( '\d{10}' ),
            modified_timestamp   => re( '\d{10}' ),
            named_awards         => ignore(),
            read_only            => 0,
            resource_name        => 'named_award_collection',
            urls                 => [],
            non_secure           => 0,
            id                   => re( '\d+' ),
        },
        'WWW::BigDoor::NamedAwardCollection'
    ),
    '$named_award_collection matches'
);

my $nac;
dies_ok {
    $nac = WWW::BigDoor::NamedAwardCollection->load( $client );
}
'should die because id missing';
lives_ok {
    $nac = WWW::BigDoor::NamedAwardCollection->load( $client, $named_award_collection->get_id() );
}
'shouldn\'t die';
cmp_deeply( $nac, $named_award_collection, 'objects are same' );

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

use_ok( 'WWW::BigDoor::Award' );
can_ok( 'WWW::BigDoor::Award', 'new' );
can_ok( 'WWW::BigDoor::Award', 'all' );
can_ok( 'WWW::BigDoor::Award', 'load' );
can_ok( 'WWW::BigDoor::Award', 'save' );
can_ok( 'WWW::BigDoor::Award', 'remove' );

can_ok( 'WWW::BigDoor::NamedAwardCollection', 'get_id' );
can_ok( 'WWW::BigDoor::NamedAwardCollection', 'get_named_awards' );

my $award = WWW::BigDoor::Award->new(
    {
        end_user_login => $username,
        named_award_id => $nac->get_named_awards->[0]->{'id'},
    }
);

$award->save( $client );
is( $client->get_response_code, 201, 'response code for award->save matches' );
cmp_deeply(
    $award,
    bless(
        {
            modified_timestamp => re( '\d{10}' ),
            created_timestamp  => re( '\d{10}' ),
            read_only          => 0,
            resource_name      => 'award',
            named_award_id     => $nac->get_named_awards->[0]->{'id'},
            id                 => re( '\d+' ),
            end_user_login     => $username,

        },
        'WWW::BigDoor::Award'
    ),
    'response for award->save matches deeply'
);

$award->remove( $client );
is( $client->get_response_code, 204, 'response code for award->remove matches' );

$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for end_user_obj->remove matches' );

$named_award_collection->remove( $client );
is( $client->get_response_code, 204, 'response code for $named_award_collection->remove matches' );

