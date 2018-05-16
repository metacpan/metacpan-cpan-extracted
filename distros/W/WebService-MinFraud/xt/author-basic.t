use strict;
use warnings;

use lib 't/lib';

use Test::Fatal qw( exception );
use Test::More 0.88;
use Test::WebService::MinFraud qw( decode_json_file );
use WebService::MinFraud::Client;

BEGIN {
    # dzil test turns author testing on by default, so we use LIVE_TESTING
    unless ( $ENV{LIVE_TESTING} ) {
        Test::More::plan( skip_all =>
                'These tests are for live testing by the author as they require a minFraud service.'
        );
    }
}

unless ( $ENV{MM_LICENSE_KEY} ) {
    BAIL_OUT 'License key not found';
}

my $client = WebService::MinFraud::Client->new(
    host       => $ENV{MM_MINFRAUD_HOST} || 'ct100-test.maxmind.com',
    account_id => $ENV{MM_ACCOUNT_ID}    || 10,
    license_key => $ENV{MM_LICENSE_KEY},
);

my $request = decode_json_file('full-request.json');

subtest 'score' => sub {
    my $response_score = $client->score($request);
    ok( $response_score, 'score response' );
    ok(
        exists $response_score->raw->{risk_score},
        'raw risk_score exists (score)'
    );
    ok(
        defined $response_score->risk_score,
        'sugary risk_score is defined (score)'
    );
};

subtest 'insights' => sub {
    my $response = $client->insights($request);
    _insights_tests($response);
};

subtest 'factors' => sub {
    my $response = $client->factors($request);
    _insights_tests($response);

    # These are the subscores that should return a value on a CT for the
    # request.
    for my $subscore (
        qw(
        billing_address
        billing_address_distance_to_ip_location
        browser
        country
        country_mismatch
        email_address
        email_domain
        email_tenure
        ip_tenure
        issuer_id_number
        time_of_day
        )
    ) {
        ok(
            defined $response->subscores->$subscore,
            "$subscore subscore"
        );
    }
};

subtest 'chargeback' => sub {
    my $response = $client->chargeback( { ip_address => '1.2.3.4' } );
    isa_ok( $response, 'WebService::MinFraud::Model::Chargeback' );
};

like(
    exception {

        # Choose an account_id that is valid in type, but way too big to real,
        # unless we hit the jackpot of accounts :)
        my $big_account_id = 900_000_000;
        my $test_client    = WebService::MinFraud::Client->new(
            host        => $ENV{MM_MINFRAUD_HOST} || 'ct100-test.maxmind.com',
            account_id  => $big_account_id,
            license_key => $ENV{MM_LICENSE_KEY},
        );
        $test_client->score($request);
    },
    qr/Your user ID or license key could not be authenticated/,
    'bad account_id throws an exception'
);

sub _insights_tests {
    my $response = shift;

    ok( $response, 'response' );
    ok(
        exists $response->raw->{risk_score},
        'raw risk_score exists (insights)'
    );
    ok(
        defined $response->risk_score,
        'sugary risk_score is defined (insights)'
    );
    ok(
        defined $response->queries_remaining,
        'queries_remaining is defined'
    );
    ok(
        $response->billing_address,
        'billing address record exists'
    );
    ok(
        $response->billing_address->latitude,
        'billing latitude exists'
    );
    ok( $response->credit_card, 'credit card record exists' );
    ok(
        $response->credit_card->issuer,
        'credit card issuer record exists'
    );
    ok(
        $response->credit_card->issuer->name,
        'credit card issuer name exists'
    );
    ok(
        $response->shipping_address,
        'shipping address record exists'
    );
    ok(
        $response->shipping_address->latitude,
        'shipping latitude exists'
    );
    ok( $response->ip_address,       'ip_address record exists' );
    ok( $response->ip_address->city, 'city exists' );
    ok(
        $response->ip_address->city->geoname_id,
        'city geoname id exists'
    );
    ok(
        defined $response->ip_address->risk,
        'ip_address risk is defined'
    );
}

done_testing;
