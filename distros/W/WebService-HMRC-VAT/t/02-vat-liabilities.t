#!perl -T
use strict;
use warnings;
use Test::Exception;
use Test::More;
use WebService::HMRC::VAT;

plan tests => 14;

my($ws, $r, $auth);

# Can instantiate class with vrn
isa_ok(
    $ws = WebService::HMRC::VAT->new({
        vrn => '123456789',
        base_url => 'https://invalid/',
    }),
    'WebService::HMRC::VAT',
    'WebService::HMRC::VAT object created'
);

# liabilities should croak without access_token
dies_ok {
    $r = $ws->liabilities({
        from => '2018-01-01',
        to   => '2018-12-31'
    })
} 'liabilities method dies without auth';

# Using an invalid url, but proper parameters should yield an error response
ok( $ws->auth->access_token('FAKE_ACCESS_TOKEN'), 'set fake access token');
isa_ok(
    $r = $ws->liabilities({
        from => '2018-01-01',
        to   => '2018-12-31'
    }),
    'WebService::HMRC::Response',
    'response yielded with from and to parameters'
);
ok(!$r->is_success, 'liabilities does not return success with invalid base_url');

# Check error raised without from parameter
dies_ok {
    $r = $ws->liabilities({
        to => '2018-12-31'
    })
} 'liabilities method dies without from parameter';

# Check error raised with invalid from parameter
dies_ok {
    $r = $ws->liabilities({
        from => 'INVALID',
        to   => '2018-12-31'
    })
} 'liabilities method dies with invalid from parameter';

# Check error raised without to parameter
dies_ok {
    $r = $ws->liabilities({
        from => '2018-01-31'
    })
} 'liabilities method dies without to parameter';

# Check error raised with invalid to parameter
dies_ok {
    $r = $ws->liabilties({
        from => '2018-01-01',
        to   => 'INVALID'
    })
} 'liabilities method dies with invalid to parameter';


# Make test call to HMRC test api with valid access_token
SKIP: {

    my $skip_count = 5;

    $ENV{HMRC_ACCESS_TOKEN} or skip (
        'Skipping tests on HMRC test api as environment variable HMRC_ACCESS_TOKEN is not set',
        $skip_count
    );

    $ENV{HMRC_VRN} or skip (
        'Skipping tests on HMRC test api as environment variable HMRC_VRN is not set',
        $skip_count
    );

    isa_ok(
        $ws = WebService::HMRC::VAT->new({
            vrn => $ENV{HMRC_VRN},
        }),
        'WebService::HMRC::VAT',
        'created object using VRN from environment variable'
    );

    ok(
        $ws->auth->access_token($ENV{HMRC_ACCESS_TOKEN}),
        'set access token from envrionment variable'
    );

    # Request liabilties using HMRC test scenario
    isa_ok(
        $r = $ws->liabilities({
            from => '2017-01-02',
            to => '2017-02-02',
            test_mode => 'SINGLE_LIABILITY',
        }),
        'WebService::HMRC::Response',
        'queried liabilities from HMRC'
    );
    ok($r->is_success, 'successful response calling liabilities from HMRC');
    is(scalar @{$r->data->{liabilities}}, 1, '1 liabilities returned');
}

