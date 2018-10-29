#!perl -T
use strict;
use warnings;
use Test::Exception;
use Test::More;
use WebService::HMRC::VAT;

plan tests => 19;

my($ws, $r, $auth);

# Cannot instatiate the class without specifying vrm
dies_ok {
    WebService::HMRC::VAT->new();
} 'instantiation fails without vrn';

# Can instantiate class with vrn
isa_ok(
    $ws = WebService::HMRC::VAT->new({
        vrn => '123456789',
        base_url => 'https://invalid/',
    }),
    'WebService::HMRC::VAT',
    'WebService::HMRC::VAT object created'
);

# obligations should croak without access_token
dies_ok {
    $r = $ws->obligations({
        from => '2018-01-01',
        to   => '2018-12-31'
    })
} 'obligations method dies without auth';

# Using an invalid url, but proper parameters should yield an error response
# use only required parameters
ok( $ws->auth->access_token('FAKE_ACCESS_TOKEN'), 'set fake access token');
isa_ok(
    $r = $ws->obligations({
        from => '2018-01-01',
        to   => '2018-12-31'
    }),
    'WebService::HMRC::Response',
    'response yielded with from and to parameters'
);
ok(!$r->is_success, 'obligations does not return success with invalid base_url');

# Using an invalid url, but proper parameters should yield an error response
# use all possible parameters
ok( $ws->auth->access_token('FAKE_ACCESS_TOKEN'), 'set fake access token');
isa_ok(
    $r = $ws->obligations({
        from   => '2018-01-01',
        to     => '2018-12-31',
        status => 'F',
    }),
    'WebService::HMRC::Response',
    'response yielded with from, to and state parameters'
);
ok(!$r->is_success, 'obligations does not return success with invalid base_url');

# Check error raised without from parameter
dies_ok {
    $r = $ws->obligations({
        to => '2018-12-31'
    })
} 'obligations method dies without from parameter';

# Check error raised with invalid from parameter
dies_ok {
    $r = $ws->obligations({
        from => 'INVALID',
        to   => '2018-12-31'
    })
} 'obligations method dies with invalid from parameter';

# Check error raised without to parameter
dies_ok {
    $r = $ws->obligations({
        from => '2018-01-31'
    })
} 'obligations method dies without to parameter';

# Check error raised with invalid to parameter
dies_ok {
    $r = $ws->obligations({
        from => '2018-01-01',
        to   => 'INVALID'
    })
} 'obligations method dies with invalid to parameter';

# Check error raised with invalid status parameter
dies_ok {
    $r = $ws->obligations({
        from   => '2018-01-01',
        to     => '2018-12-31',
        status => 'Z'
    })
} 'obligations method dies with invalid status parameter';


# Make real call to HMRC test api with valid access_token
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

    # Request VAT returns over a period of the current year.
    # The sandbox api takes no notice of the specified date values
    # except that valid dates must be provided. Neither does it
    # respect the open/fulfilled filter parameter.
    my $from = "2017-01-01";
    my $to   = "2017-12-31";

    isa_ok(
        $r = $ws->obligations({
            from => $from,
            to => $to,
        }),
        'WebService::HMRC::Response',
        'called obligations from HMRC without status filter'
    );

    ok($r->is_success, 'successful response calling obligations from HMRC without status filter');
    ok(scalar @{$r->data->{obligations}} > 0, 'At lease one  VAT return obligations returned without filter');
}
