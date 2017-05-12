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
    Test::Most::plan( tests => 51 );
}

use JSON;

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

$response = $client->GET( 'end_user' );
is( @$response,        2, 'response for GET end_user matches' );
is( @{$response->[0]}, 0, 'response for GET end_user matches' );

my $username = Test::Mock::REST::Client::get_username();

my $end_user = {end_user_login => $username,};

$response = $client->POST( 'end_user', {format => 'json'}, $end_user );
is( @$response, 2, 'response for POST end_user matches' );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                end_user_login => $username,
                guid           => ignore(),
            }
        ),
        {}
    ],
    'response for POST end_user matches deeply'
);

my $end_user_login = $response->[0]->{'end_user_login'};

$response = $client->GET( 'end_user' );
cmp_deeply(
    $response,
    [
        [
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
            }
        ],
        {}
    ],
    'response for GET end_user matches'
);

my $named_award_collection = {
    pub_title            => 'application achievements',
    pub_description      => 'a set of achievements that the user can earn',
    end_user_title       => 'achievements',
    end_user_description => 'things you can get',
};

$response = $client->POST( 'named_award_collection', {format => 'json'}, $named_award_collection );
is( @$response, 2, 'response for POST named_award_collection matches' );

my $named_award_collection_id = $response->[0]->{'id'};

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

my $award_id;

foreach my $named_award ( @named_awards ) {
    $response =
      $client->POST( sprintf( 'named_award_collection/%s/named_award', $named_award_collection_id ),
        {format => 'json'}, $named_award );
    cmp_deeply(
        $response,
        [superhashof( {id => ignore(),} ), {}],
        'response for POST named_award matches'
    );
    $award_id = $response->[0]->{'id'};
}

$response = $client->POST(
    sprintf( 'end_user/%s/award', $end_user_login ),
    {format         => 'json', verbosity => 9},
    {named_award_id => $award_id}
);
is( @$response, 2, 'response for POST end_user/{id}/award matches' );

my $user_award_id = $response->[0]->{'id'};

$response = $client->GET( sprintf( 'end_user/%s/award/%s', $end_user_login, $user_award_id ),
    {format => 'json', verbosity => 9} );

cmp_deeply(
    $response,
    [
        {
            read_only   => 0,
            named_award => {
                pub_title       => 'obligatory early achievement ',
                pub_description => 'the sort of achievement you get when you can turn on an xbox',
                end_user_title  => 'just breath',
                end_user_description      => 'congratulations you rock so hard; keep on breathing',
                relative_weight           => 1,
                named_award_collection_id => $named_award_collection_id,
                collection_uri            => re( '/named_award_collection/' ),
                id                        => re( '\d+' ),
                read_only                 => 0,
                modified_timestamp        => re( '\d{10}' ),
                created_timestamp         => re( '\d{10}' ),
                resource_name             => 'named_award',
                urls                      => [],
            },
            resource_name      => "award",
            modified_timestamp => re( '\d{10}' ),
            created_timestamp  => re( '\d{10}' ),
            end_user_login     => $username,
            id                 => $user_award_id,
        },
        {}
    ],
    'GET end_user/{id}/award/{id}'
);

$response = $client->GET( sprintf( 'end_user/%s/award', $end_user_login ),
    {format => 'json', verbosity => 9} );

cmp_deeply(
    $response,
    [
        [
            {
                read_only   => 0,
                named_award => {
                    pub_title => 'obligatory early achievement ',
                    pub_description =>
                      'the sort of achievement you get when you can turn on an xbox',
                    end_user_title       => 'just breath',
                    end_user_description => 'congratulations you rock so hard; keep on breathing',
                    relative_weight      => 1,
                    named_award_collection_id => $named_award_collection_id,
                    collection_uri            => re( '/named_award_collection/' ),
                    id                        => re( '\d+' ),
                    read_only                 => 0,
                    modified_timestamp        => re( '\d{10}' ),
                    created_timestamp         => re( '\d{10}' ),
                    resource_name             => 'named_award',
                    urls                      => [],
                },
                resource_name      => "award",
                modified_timestamp => re( '\d{10}' ),
                created_timestamp  => re( '\d{10}' ),
                end_user_login     => $username,
                id                 => $user_award_id,
            }
        ],
        {}
    ],
    'GET end_user/{id}/award/{id}'
);

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

my $currency_id            = $response->[0]->{'id'};
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

my $level_id;
foreach my $named_level ( @named_levels ) {
    $response =
      $client->POST( sprintf( 'named_level_collection/%s/named_level', $named_level_collection_id ),
        {format => 'json'}, $named_level );
    is( @$response, 2, 'response for POST named_level matches' );
    $level_id = $response->[0]->{'id'};
}

$response = $client->POST(
    sprintf( 'end_user/%s/level', $end_user_login ),
    {format         => 'json', verbosity => 9},
    {named_level_id => $level_id}
);
cmp_deeply(
    $response,
    [
        {
            transaction_group_id => undef,
            read_only            => 0,
            named_level          => {
                pub_title                 => 'level3',
                pub_description           => 'level3 description',
                end_user_title            => 'Expert',
                end_user_description      => "you rock",
                named_level_collection_id => $named_level_collection_id,
                resource_name             => "named_level",
                modified_timestamp        => re( '\d{10}' ),
                created_timestamp         => re( '\d{10}' ),
                read_only                 => 0,
                id                        => $level_id,
                collection_uri            => re( '/named_level_collection/' ),
                attributes                => [],
                threshold                 => undef,
                urls                      => [],
            },
            resource_name      => "level",
            modified_timestamp => re( '\d{10}' ),
            created_timestamp  => re( '\d{10}' ),
            end_user_login     => $username,
            id                 => re( '\d+' ),
        },
        {}
    ],
    'response for POST end_user/{id}/level matches'
);

my $user_level_id = $response->[0]->{'id'};

$response = $client->GET( sprintf( 'end_user/%s/level/%s', $end_user_login, $user_level_id ),
    {format => 'json', verbosity => 9} );
cmp_deeply(
    $response,
    [
        {
            transaction_group_id => undef,
            read_only            => 0,
            named_level          => {
                pub_title                 => 'level3',
                pub_description           => 'level3 description',
                end_user_title            => 'Expert',
                end_user_description      => "you rock",
                named_level_collection_id => $named_level_collection_id,
                resource_name             => "named_level",
                modified_timestamp        => re( '\d{10}' ),
                created_timestamp         => re( '\d{10}' ),
                read_only                 => 0,
                id                        => $level_id,
                collection_uri            => re( '/named_level_collection/' ),
                attributes                => [],
                threshold                 => undef,
                urls                      => [],
            },
            resource_name      => "level",
            modified_timestamp => re( '\d{10}' ),
            created_timestamp  => re( '\d{10}' ),
            end_user_login     => $username,
            id                 => re( '\d+' ),
        },
        {}
    ],
    'response for GET end_user/{id}/level/{id} matches'
);

$response = $client->GET( sprintf( 'end_user/%s/level', $end_user_login ),
    {format => 'json', verbosity => 9} );
cmp_deeply(
    $response,
    [
        [
            {
                transaction_group_id => undef,
                read_only            => 0,
                named_level          => {
                    pub_title                 => 'level3',
                    pub_description           => 'level3 description',
                    end_user_title            => 'Expert',
                    end_user_description      => "you rock",
                    named_level_collection_id => $named_level_collection_id,
                    resource_name             => "named_level",
                    modified_timestamp        => re( '\d{10}' ),
                    created_timestamp         => re( '\d{10}' ),
                    read_only                 => 0,
                    id                        => $level_id,
                    collection_uri            => re( '/named_level_collection/' ),
                    attributes                => [],
                    threshold                 => undef,
                    urls                      => [],
                },
                resource_name      => "level",
                modified_timestamp => re( '\d{10}' ),
                created_timestamp  => re( '\d{10}' ),
                end_user_login     => $username,
                id                 => re( '\d+' ),
            }
        ],
        {}
    ],
    'response for GET end_user/{id}/level matches'
);

my $profile = {
    provider      => 'publisher',
    email         => 'end_user@example.com',
    first_name    => 'John',
    last_name     => 'Doe',
    display_name  => 'John Doe',
    profile_photo => 'http://example.com/image.jpg',
    example_key   => 'Example Value',
};

$response =
  $client->POST( sprintf( 'end_user/%s/profile', $end_user_login ), {format => 'json'}, $profile );
cmp_deeply(
    $response,
    [
        {
            email         => 'end_user@example.com',
            first_name    => 'John',
            last_name     => 'Doe',
            display_name  => 'John Doe',
            profile_photo => 'http://example.com/image.jpg',
            example_key   => 'Example Value',
        },
        {}
    ],
    'response for POST end_user/{id}/profile matches'
);

$response = $client->GET( sprintf( 'end_user/%s/profile', $end_user_login ), {format => 'json'} );
cmp_deeply(
    $response,
    [
        [
            {
                email         => 'end_user@example.com',
                first_name    => 'John',
                last_name     => 'Doe',
                display_name  => 'John Doe',
                profile_photo => 'http://example.com/image.jpg',
                example_key   => 'Example Value',
            }
        ],
        {}
    ],
    'response for GET end_user/{id}/profile matches'
);

$response =
  $client->GET( sprintf( 'end_user/%s/profile/publisher', $end_user_login ), {format => 'json'} );
cmp_deeply(
    $response,
    [
        {
            email         => 'end_user@example.com',
            first_name    => 'John',
            last_name     => 'Doe',
            display_name  => 'John Doe',
            profile_photo => 'http://example.com/image.jpg',
            example_key   => 'Example Value',
        },
        {}
    ],
    'response for GET end_user/{id}/profile matches'
);

my $profile_id = 'publisher';

$response =
  $client->GET( sprintf( 'end_user/%s', $end_user_login ), {format => 'json', verbosity => 9} );
is( @$response, 2, 'response for GET end_user/{user_login} matches' );
cmp_deeply(
    $response,
    [
        superhashof(
            {
                end_user_login => $username,
                guid           => ignore(),
            }
        ),
        {}
    ],
    'response for GET end_user/{user_login} matches deeply'
);

$response = $client->GET( 'end_user', {format => 'json', verbosity => 9} );
cmp_deeply(
    $response,
    [
        [
            superhashof(
                {
                    end_user_login => $username,
                    guid           => ignore(),
                }
            )
        ],
        {}
    ],
    'response for GET end_user matches deeply'
);

$response = $client->GET( sprintf( 'end_user/%s/currency_balance', $end_user_login ),
    {format => 'json', verbosity => 9} );
cmp_deeply(
    $response,
    [[], {}],
    'response for GET end_user/{user_login}/currency_balance matches deeply'
);

$response = $client->GET( sprintf( 'end_user/%s/transaction', $end_user_login ),
    {format => 'json', verbosity => 9} );
cmp_deeply(
    $response,
    [[], {}],
    'response for GET end_user/{user_login}/transaction matches deeply'
);

$response =
  $client->GET( sprintf( 'end_user/%s/good', $end_user_login ),
    {format => 'json', verbosity => 9} );
cmp_deeply( $response, [[], {}], 'response for GET end_user/{user_login}/good matches deeply' );

$response = $client->GET( 'named_transaction_group', {format => 'json', verbosity => 9} );
cmp_deeply( $response, [[], {}], 'response for GET named_transaction_group matches deeply' );

my $named_transaction_group = {
    pub_title             => 'Test Transaction Group',
    pub_description       => 'test description',
    end_user_title        => 'end user title',
    end_user_description  => 'end user description',
    end_user_cap          => '-1',
    end_user_cap_interval => '-1',
};

$response = $client->POST( 'named_transaction_group', {format => 'json', verbosity => 9},
    $named_transaction_group );
cmp_deeply(
    $response,
    [
        {
            pub_title                  => 'Test Transaction Group',
            pub_description            => 'test description',
            end_user_title             => 'end user title',
            end_user_description       => 'end user description',
            end_user_cap               => '-1',
            end_user_cap_interval      => '-1',
            resource_name              => "named_transaction_group",
            modified_timestamp         => re( '\d{10}' ),
            created_timestamp          => re( '\d{10}' ),
            read_only                  => 0,
            non_secure                 => 0,
            challenge_response_enabled => JSON::false,
            id                         => re( '\d+' ),
            urls                       => [],
            named_transactions         => [],
        },
        {}
    ],
    'response for POST named_transaction_group matches deeply'
);

my $named_transaction_group_id = $response->[0]->{'id'};

my $named_transaction = {
    pub_title            => 'Test Transaction',
    pub_description      => 'test description',
    end_user_title       => 'end user title',
    end_user_description => 'end user description',
    currency_id          => $currency_id,
    amount               => '50',
};

$response =
  $client->POST( 'named_transaction', {format => 'json', verbosity => 9}, $named_transaction );
cmp_deeply(
    $response,
    [
        {
            pub_title               => 'Test Transaction',
            pub_description         => 'test description',
            end_user_title          => 'end user title',
            end_user_description    => 'end user description',
            resource_name           => "named_transaction",
            modified_timestamp      => re( '\d{10}' ),
            created_timestamp       => re( '\d{10}' ),
            read_only               => 0,
            id                      => re( '\d+' ),
            default_amount          => '1.0',
            named_good              => undef,
            currency_id             => $currency_id,
            is_source               => undef,
            variable_amount_allowed => JSON::true,
            vendor_publisher_title  => undef,
            attributes              => [],
            currency                => {
                pub_title                 => 'Coins',
                pub_description           => 'an example of the Purchase currency type',
                end_user_title            => 'Coins',
                end_user_description      => 'can only be purchased',
                currency_type_id          => '1',
                currency_type_title       => 'Redeemable Purchase Currency',
                currency_type_description => '',
                exchange_rate             => '900.00',
                relative_weight           => 2,
                id                        => re( '\d+' ),
                modified_timestamp        => re( '\d{10}' ),
                created_timestamp         => re( '\d{10}' ),
                read_only                 => 0,
                resource_name             => "currency",
                urls                      => [],
            },
            notifiable_event => JSON::false,

        },
        {}
    ],
    'response for POST named_transaction_group matches deeply'
);

my $named_transaction_id = $response->[0]->{'id'};

$response = $client->DELETE( sprintf( 'named_transaction/%s', $named_transaction_id ),
    {format => 'json', verbosity => 9} );
is( $response, undef, 'response for DELETE named_transaction/{id} matches' );

$response = $client->DELETE( sprintf( 'named_transaction_group/%s', $named_transaction_group_id ),
    {format => 'json', verbosity => 9} );
is( $response, undef, 'response for DELETE named_transaction_group/{id} matches' );

$response = $client->DELETE( sprintf( 'end_user/%s/profile/%s', $end_user_login, $profile_id ),
    {format => 'json', verbosity => 9} );
is( $response, undef, 'response for DELETE end_user/{id}/profile/{id} matches' );

$response = $client->DELETE( sprintf( 'end_user/%s/award/%s', $end_user_login, $user_award_id ),
    {format => 'json', verbosity => 9} );
is( $response, undef, 'response for DELETE end_user/{id}/award/{id} matches' );

$response = $client->DELETE( sprintf( 'end_user/%s/level/%s', $end_user_login, $user_level_id ),
    {format => 'json', verbosity => 9} );
is( $response, undef, 'response for DELETE end_user/{id}/level/{id} matches' );

$response = $client->DELETE(
    sprintf( 'named_award_collection/%s/named_award/%s', $named_award_collection_id, $award_id ) );
is( @$response, 0, 'response for DELETE named_award_collection/{id}/named_award/{id} matches' );

$response = $client->DELETE( sprintf( 'named_award_collection/%s', $named_award_collection_id ) );
is( @$response, 0, 'response for DELETE named_award_collection matches' );

$response = $client->DELETE( sprintf( 'named_level_collection/%s', $named_level_collection_id ) );
is( @$response, 0, 'response for DELETE named_level_collection matches' );

$response = $client->DELETE( sprintf( 'currency/%s', $currency_id ), {format => 'json'} );
is( @$response, 0, 'response for DELETE currency matches' );

$response = $client->DELETE( sprintf( 'end_user/%s', $end_user_login ), {format => 'json'} );
is( @$response, 0, 'response for DELETE end_user matches' );

$response = $client->DELETE( sprintf( 'end_user/%s', $end_user_login ), {format => 'json'} );
is( @$response, 0, 'response for DELETE end_user matches' );

$response =
  $client->GET( sprintf( 'end_user/%s', $end_user_login ), {format => 'json', verbosity => 9} );

cmp_deeply( $response, undef, 'response for GET end_user/{user_login} matches' );
