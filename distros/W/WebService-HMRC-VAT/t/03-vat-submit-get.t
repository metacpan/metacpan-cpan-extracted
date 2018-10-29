#!perl -T
use strict;
use warnings;
use JSON::MaybeXS qw(decode_json);
use Test::Exception;
use Test::More;
use WebService::HMRC::VAT;

plan tests => 28;

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
ok( $ws->auth->access_token('FAKE_ACCESS_TOKEN'), 'set fake access token');


# submit_return fails without data
dies_ok {
    $ws->submit_return()
} 'submit_return fails without data';


# submit using invalid url returns error response
# also test that missing finalised flag is interpreted as false
isa_ok(
    $r = $ws->submit_return({
        periodKey => '#001',
        vatDueSales => "100.00",
        vatDueAcquisitions => 0.00,
        totalVatDue => 100.00,
        vatReclaimedCurrPeriod => 50.00,
        netVatDue => 50,
        totalValueSalesExVAT => 500,
        totalValuePurchasesExVAT => 250,
        totalValueGoodsSuppliedExVAT => 0,
        totalAcquisitionsExVAT => 0,
    }),
    'WebService::HMRC::Response',
    'response yielded with data'
);
ok(!$r->is_success, 'liabilities does not return success with invalid base_url');
is($r->http->request->url, 'https://invalid/organisations/vat/123456789/returns', 'correct url constructed');
is($r->http->request->header('Authorization'), 'Bearer FAKE_ACCESS_TOKEN', 'Authorization header set correctly');
is($r->http->request->header('Content-Type'), 'application/json', 'Correct content-type header set');
is(decode_json($r->http->request->content)->{periodKey}, '#001', 'body content encoded periodKey correctly');
like($r->http->request->content, qr/"finalised"\s*:\s*false/, 'finalised set to false for undef input');
like($r->http->request->content, qr/"vatDueSales"\s*:\s*100/, 'vatDueSales has been coerced into a number');

# submit using invalid url returns error response
# test that true finalised flag is encoded as such
isa_ok(
    $r = $ws->submit_return({
        periodKey => '#001',
        vatDueSales => 100.00,
        vatDueAcquisitions => 0.00,
        totalVatDue => 100.00,
        vatReclaimedCurrPeriod => 50.00,
        netVatDue => 50,
        totalValueSalesExVAT => 500,
        totalValuePurchasesExVAT => 250,
        totalValueGoodsSuppliedExVAT => 0,
        totalAcquisitionsExVAT => 0,
        finalised => 1,
    }),
    'WebService::HMRC::Response',
    'response yielded with data'
);
like($r->http->request->content, qr/"finalised"\s*:\s*true/, 'finalised set to true for true input');

# Test get_return
isa_ok(
    $r = $ws->get_return({period_key => '#001'}),
   'WebService::HMRC::Response',
   'response object returned retrieving VAT return'
);
ok(!$r->is_success, 'retrieving VAT return from invalid endpoint does not yield success');
is($r->http->request->url, 'https://invalid/organisations/vat/123456789/returns/%23001', 'url correctly escapes `#` character');


# Make real call to HMRC test api with valid access_token
SKIP: {

    my $skip_count = 12;

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


    my $period_key = sprintf('#%03u', rand(1000));
    my $data = {
        periodKey => $period_key,
        vatDueSales => "100.00",
        vatDueAcquisitions => 0.00,
        totalVatDue => 100.00,
        vatReclaimedCurrPeriod => 50.00,
        netVatDue => 50,
        totalValueSalesExVAT => 500,
        totalValuePurchasesExVAT => 250,
        totalValueGoodsSuppliedExVAT => 0,
        totalAcquisitionsExVAT => 0,
        finalised => 1,
    };

    isa_ok(
        $r = $ws->submit_return($data),
        'WebService::HMRC::Response',
        'response object returned after submitting return to hmrc'
    );

    ok($r->is_success, 'submission to HMRC successful');
    ok($r->header('Receipt-ID'), 'Receipt-ID header received');
    ok($r->header('X-CorrelationId'), 'X-CorrelationId header received');
    like($r->header('Receipt-Timestamp'), qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/, 'valid Receipt-Timestamp header received');
    ok($r->data->{formBundleNumber}, 'formBundleNumber data received');
    like($r->data->{processingDate}, qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/, 'valid processingDate data received');


    # Retrieve submitted return
    isa_ok(
        $r = $ws->get_return({period_key => $period_key}),
        'WebService::HMRC::Response',
        'response object returned retrieving VAT return from HMRC'
    );
    ok($r->is_success, 'successful response retrieving VAT return from HMRC');
    delete $data->{finalised};
    is_deeply($r->data, $data, 'Extracted VAT return matches that submitted');
}
