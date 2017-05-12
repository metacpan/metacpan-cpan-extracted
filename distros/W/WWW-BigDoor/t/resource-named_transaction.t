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
    Test::Most::plan( tests => 65 );
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

use_ok( 'WWW::BigDoor::NamedTransactionGroup' );
can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'new' );
can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'all' );
can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'load' );
can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'save' );
can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'remove' );

my $transaction_groups = WWW::BigDoor::NamedTransactionGroup->all( $client );
cmp_deeply( $transaction_groups, [], 'should be zero transaction groups at the beginning' );

my $transaction_group_payload = {
    pub_title             => 'Test Transaction Group',
    pub_description       => 'test description',
    end_user_title        => 'end user title',
    end_user_description  => 'end user description',
    end_user_cap          => '-1',
    end_user_cap_interval => '-1',
};
my $transaction_group_obj = new WWW::BigDoor::NamedTransactionGroup( $transaction_group_payload );

cmp_deeply(
    $transaction_group_obj,
    bless(
        {
            pub_title             => 'Test Transaction Group',
            pub_description       => 'test description',
            end_user_title        => 'end user title',
            end_user_description  => 'end user description',
            end_user_cap          => '-1',
            end_user_cap_interval => '-1',
        },
        'WWW::BigDoor::NamedTransactionGroup'
    ),
    'transaction_group_obj matches deeply'
);

$transaction_group_obj->save( $client );
is( $client->get_response_code, 201, 'response for transaction_group_obj->save matches' );

cmp_deeply(
    $transaction_group_obj,
    bless(
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
        'WWW::BigDoor::NamedTransactionGroup'
    ),
    'transaction_group_obj matches deeply'
);

# FIXME replace fir WWW::BigDoor::CurrencyType
$response = $client->GET( 'currency_type' );
is( @{$response->[0]}, 9, 'there is 9 currency_types' );

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

use_ok( 'WWW::BigDoor::NamedTransaction' );
can_ok( 'WWW::BigDoor::NamedTransaction', 'new' );
can_ok( 'WWW::BigDoor::NamedTransaction', 'all' );
can_ok( 'WWW::BigDoor::NamedTransaction', 'load' );
can_ok( 'WWW::BigDoor::NamedTransaction', 'save' );
can_ok( 'WWW::BigDoor::NamedTransaction', 'remove' );

my $named_transactions = WWW::BigDoor::NamedTransaction->all( $client );
cmp_deeply( $named_transactions, [], 'should be no transactions at the moment' );

my $named_transaction_payload = {
    pub_title            => 'Test Transaction',
    pub_description      => 'test description',
    end_user_title       => 'end user title',
    end_user_description => 'end user description',
    currency_id          => $currency_obj->get_id,
    amount               => '50',
    default_amount       => '50',
};

my $named_transaction_obj = new WWW::BigDoor::NamedTransaction( $named_transaction_payload );

cmp_deeply(
    $named_transaction_obj,
    bless(
        {
            pub_title            => 'Test Transaction',
            pub_description      => 'test description',
            end_user_title       => 'end user title',
            end_user_description => 'end user description',
            currency_id          => $currency_obj->get_id,
            amount               => '50',
            default_amount       => '50',
        },
        'WWW::BigDoor::NamedTransaction'
    ),
    'named_transaction_obj matches deeply'
);

$named_transaction_obj->save( $client );
is( $client->get_response_code, 201, 'response for named_transaction_obj->save matches' );

cmp_deeply(
    $named_transaction_obj,
    bless(
        {
            pub_title               => 'Test Transaction',
            pub_description         => 'test description',
            end_user_title          => 'end user title',
            end_user_description    => 'end user description',
            currency_id             => $currency_obj->get_id,
            amount                  => '50',
            default_amount          => '50',
            is_source               => undef,
            resource_name           => "named_transaction",
            modified_timestamp      => re( '\d{10}' ),
            created_timestamp       => re( '\d{10}' ),
            read_only               => 0,
            id                      => re( '\d+' ),
            variable_amount_allowed => JSON::true,
            named_good              => undef,
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
        'WWW::BigDoor::NamedTransaction'
    ),
    'named_transaction_obj matches deeply'
);

# FIXME implement as method for named_transaction ?
$response = $client->POST(
    sprintf(
        'named_transaction_group/%s/named_transaction/%s',
        $transaction_group_obj->get_id(),
        $named_transaction_obj->get_id()
    ),
    {format                       => 'json'},
    {named_transaction_is_primary => 1}
);
is( $client->get_response_code, 201,
    'response code for POST named_transaction_group/{id}/named_transaction/{id} matches' );
cmp_deeply(
    $response,
    [
        {
            named_transaction_group_ratio => '-1.0',
            named_transaction_group_id    => $transaction_group_obj->get_id(),
            named_transaction_id          => $named_transaction_obj->get_id(),
            named_transaction_is_primary  => 1,
            id                            => re( '\d+' ),
            resource_name                 => 'transaction_group_to_transaction',
            modified_timestamp            => re( '\d{10}' ),
            created_timestamp             => re( '\d{10}' ),
            read_only                     => 0,
        },
        {}
    ],
    'response for POST named_transaction_group/{id}/named_transaction/{id} matches deeply'
);

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

$response = $client->POST(
    sprintf( 'named_transaction_group/%s/execute/%s', $transaction_group_obj->get_id(), $username ),
    {format    => 'json'},
    {verbosity => '6'}
);

is( $client->get_response_code, 201,
    'response code for POST named_transaction_group/{id}/execute/{id} matches' );

cmp_deeply(
    $response,
    [
        {
            transaction_group_id => ignore(),
            end_user             => {
                end_user_login         => $username,
                best_guess_name        => $username,
                guid                   => ignore(),
                read_only              => 0,
                resource_name          => 'end_user',
                best_guess_profile_img => undef,
                award_summaries        => [],
                level_summaries        => [],
                sent_good_summaries    => [],
                currency_balances      => [
                    {
                        modified_timestamp   => re( '\d{10}' ),
                        created_timestamp    => re( '\d{10}' ),
                        end_user_description => 'can only be purchased',
                        transaction_group_id => ignore(),
                        pub_title            => 'Coins',
                        urls                 => [],
                        current_balance      => '50.00',
                        adjustment_amount    => '50.00',
                        currency_id          => $currency_obj->get_id(),
                        previous_balance     => '0.00',
                        currency_adjusted    => JSON::true,
                        pub_description      => 'an example of the Purchase currency type',
                        end_user_title       => 'Coins',
                    }
                ],
                received_good_summaries => [],
                modified_timestamp      => re( '\d{10}' ),
                created_timestamp       => re( '\d{10}' ),
            },
        },
        {}
    ],
    'response for POST named_transaction_group/{id}/execute/{id} matches deeply'
);

can_ok( 'WWW::BigDoor::NamedTransactionGroup', 'execute_transaction' );
$response = $transaction_group_obj->execute_transaction( $username, {verbosity => '6'}, $client );

is( $client->get_response_code, 201,
    'response code for $transaction_group_obj->execute_transaction matches' );

cmp_deeply(
    $response,
    [
        {
            transaction_group_id => ignore(),
            end_user             => {
                end_user_login         => $username,
                best_guess_name        => $username,
                guid                   => ignore(),
                read_only              => 0,
                resource_name          => 'end_user',
                best_guess_profile_img => undef,
                award_summaries        => [],
                level_summaries        => [],
                sent_good_summaries    => [],
                currency_balances      => [
                    {
                        modified_timestamp   => re( '\d{10}' ),
                        created_timestamp    => re( '\d{10}' ),
                        end_user_description => 'can only be purchased',
                        transaction_group_id => ignore(),
                        pub_title            => 'Coins',
                        urls                 => [],
                        current_balance      => '100.00',
                        adjustment_amount    => '50.00',
                        currency_id          => $currency_obj->get_id(),
                        previous_balance     => '50.00',
                        currency_adjusted    => JSON::true,
                        pub_description      => 'an example of the Purchase currency type',
                        end_user_title       => 'Coins',
                    }
                ],
                received_good_summaries => [],
                modified_timestamp      => re( '\d{10}' ),
                created_timestamp       => re( '\d{10}' ),
            },
        },
        {}
    ],
    'response for POST $transaction_group_obj->execute_transaction matches deeply'
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
    'response code for WWW::BigDoor::CurrencyBalance->all matches' );

cmp_deeply(
    $currency_balances,
    [
        bless(
            {
                adjustment_amount => '50.00',
                curr_balance      => '100.00',
                currency          => {
                    modified_timestamp        => re( '\d{10}' ),
                    created_timestamp         => re( '\d{10}' ),
                    currency_type_description => '',
                    currency_type_id          => 1,
                    currency_type_title       => 'Redeemable Purchase Currency',
                    end_user_description      => 'can only be purchased',
                    end_user_title            => 'Coins',
                    exchange_rate             => '900.00',
                    id                        => re( '\d+' ),
                    pub_description           => 'an example of the Purchase currency type',
                    pub_title                 => 'Coins',
                    read_only                 => 0,
                    relative_weight           => 2,
                    resource_name             => 'currency',
                    urls                      => []
                },
                end_user_description => 'can only be purchased',
                end_user_login       => $username,
                end_user_title       => 'Coins',
                id                   => re( '\d+' ),
                modified_timestamp   => re( '\d{10}' ),
                created_timestamp    => re( '\d{10}' ),
                prev_balance         => '50.00',
                pub_description      => 'an example of the Purchase currency type',
                pub_title            => 'Coins',
                read_only            => 0,
                resource_name        => 'end_user_currency_balance',
                transaction_group_id => ignore(),
                end_user_obj         => bless(
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
        )
    ],
    'currency_balances matches deeply after all()'
);

can_ok( 'WWW::BigDoor::CurrencyBalance', 'load' );

use_ok( 'WWW::BigDoor::Leaderboard' );

my $params =
  {format => 'json', verbosity => 9, type => 'currency', filter_value => $currency_obj->get_id()};

$response = WWW::BigDoor::Leaderboard->execute( $params, $client );

is( $client->get_response_code, 200, 'response for GET leaderboard/execute matches' );

cmp_deeply(
    $response,
    [
        {
            modified_timestamp   => '',
            created_timestamp    => '',
            pub_title            => '',
            end_user_description => '',
            pub_description      => '',
            end_user_title       => '',
            max_rank             => 1,
            id                   => '',
            results              => [
                {
                    best_guess_profile_img => undef,
                    rank                   => 1,
                    curr_balance           => '100.00',
                    percentile             => 0,
                    end_user_login         => $username,
                    best_guess_name        => $username,
                }
            ],
        },
        {}
    ],
    'response for GET leaderboard/execute matches deeply'
);

$end_user_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for end_user_obj->remove matches' );

$named_transaction_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for named_transaction_obj->remove matches' );

$currency_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for currency_obj->remove matches' );

$currencies = WWW::BigDoor::Currency->all( $client );
cmp_deeply( $currencies, [], 'should be zero currencies at the end' );

$transaction_group_obj->remove( $client );
is( $client->get_response_code, 204, 'response code for transaction_group_obj->remove matches' );

$transaction_groups = WWW::BigDoor::NamedTransactionGroup->all( $client );
cmp_deeply( $transaction_groups, [], 'should be zero transaction groups at the end' );
