#!perl
use Test::More tests => 66;

use WWW::Vonage::API;
use strict;
use Data::Dumper;

my $api = WWW::Vonage::API->new(
    API_Key    => 'dummy_key_123',
    API_Secret => 'dummy_secret_456',
    _test      => 1
);

my %tests = (
    '01' => {
        method      => "GET",
        path        => 'account/get-balance',
        payload_out => undef,
        params      => { API_Region => 'rest', API_Version => 'none' },
        url         => "https://rest.nexmo.com/account/get-balance",
    },
    '02' => {
        method      => "GET",
        path        => "applications",
        payload_out => undef,
        params      => { API_Version => 'v2', API_Region => 'api' },
        url         => 'https://api.nexmo.com/v2/applications'
    },
    '03' => {
        method      => "GET",
        path        => "applications/BS1001",
        payload_out => undef,
        params      => { },
        url         => 'https://api.nexmo.com/v2/applications/BS1001'
    },
    '04' => {
        method      => "DELETE",
        path        => "applications/BS1001",
        payload_out => undef,
        params      => {  },
        url         => 'https://api.nexmo.com/v2/applications/BS1001'
    },
    '05' => {
        method      => "GET",
        path        => "ni/basic/json",
        payload_in  => { number => '1-001-555-5551' },
        payload_out => undef,
        params      => { API_Version => 'none' },
        url => 'https://api.nexmo.com/ni/basic/json?number=1-001-555-5551'
    },
    '06' => {
        method      => "GET",
        path        => "account/numbers",
        payload_in  => { country => 'GB' },
        payload_out => undef,
        params      => { API_Version => 'none', API_Region => 'rest', },
        url         => 'https://rest.nexmo.com/account/numbers?country=GB'
    },
    '07' => {
        method      => "POST",
        path        => "account/number/buy",
        payload_in  => { country => 'GB', msisdn => '44770090000' },
        payload_out => '{"country":"GB","msisdn":"44770090000"}',
        params      => { API_Version => 'none', API_Region => 'rest', },
        url         => 'https://rest.nexmo.com/account/number/buy'
    },
    '08' => {
        method      => "GET",
        path        => "account/pricing/sms-outbound",
        payload_in  => { country => 'GB', page => '2' },
        payload_out => undef,
        params => { API_Version => 'v2',API_Region => 'api' },
        url =>
'https://api.nexmo.com/v2/account/pricing/sms-outbound?country=GB&page=2'
    },
    '09' => {
        method      => "POST",
        path        => 'redact/transaction',
        params      => { API_Version => 'v1'},
        payload_out => undef,
        url         => 'https://api.nexmo.com/v1/redact/transaction',
    },
    10 => {
        method     => "GET",
        path       => "reports/records",
        payload_in => { country => 'GB', page => '2' },
        params      => { API_Version => 'v2', },
        payload_out => undef,
        url => 'https://api.nexmo.com/v2/reports/records?country=GB&page=2'
    },
    11 => {
        method      => "DELETE",
        path        => "reports/BB12033",
        payload_out => undef,
        params      => { API_Version => 'v2', },
        url         => 'https://api.nexmo.com/v2/reports/BB12033'
    },
    12 => {
        method      => "GET",
        path        => "media/bbB12033",
        payload_out => undef,
        params      => { API_Version => 'v3', },
        url         => 'https://api.nexmo.com/v3/media/bbB12033'
    },
    13 => {
        method      => "POST",
        path        => 'sms/json',
        payload_in  => { country => 'GB', page => '2' },
        payload_out => '{"country":"GB","page":"2"}',
        params      => { API_Version => 'none', API_Region => 'rest', },
        url         => 'https://rest.nexmo.com/sms/json',
    },
    14 => {
        method      => "POST",
        path        => 'verify/BS4321',
        payload_in  => { country => 'GB', page => '2' },
        payload_out => '{"country":"GB","page":"2"}',
        params => { API_Version => 'v2',API_Region => 'api'  },
        url    => 'https://api.nexmo.com/v2/verify/BS4321',
    },
    15 => {
        method      => "POST",
        path        => 'verify/BS4321/next_workflow',
        payload_out => undef,
        params      => { API_Version => 'v2', },
        url         => 'https://api.nexmo.com/v2/verify/BS4321/next_workflow',
    },
    16 => {
        method      => "GET",
        path        => 'verify/BS4321/silent-auth/redirect',
        payload_out => undef,
        params      => { API_Version => 'v2', },
        url => 'https://api.nexmo.com/v2/verify/BS4321/silent-auth/redirect',
    },
    17 => {
        method      => "GET",
        path        => 'project/BS999902/archive',
        payload_in  => { count => 10, offset => 15, sessionId => '10101' },
        payload_out => undef,
        params      => {
            API_Region  => 'video.api',
            API_Version => 'none',
            API_Domain  => 'vonage.com',
            API_Version => 'v2'
        },
        url =>
'https://video.api.vonage.com/v2/project/BS999902/archive?count=10&offset=15&sessionId=10101',
    },
    18 => {
        method      => "PATCH",
        path        => 'project/BS999902/archive/BS19900/streams',
        payload_in  => { removeStream => '65587' },
        payload_out => '{"removeStream":"65587"}',
        params      => {},
        url =>
'https://video.api.vonage.com/v2/project/BS999902/archive/BS19900/streams',
    },
    19 => {
        method      => "POST",
        path        => 'project/bs999902/archive/BS19900/stop',
        payload_in  => { removeStream => 'BS65587' },
        payload_out => '{"removeStream":"BS65587"}',
        params      => { },
        url =>
          'https://video.api.vonage.com/v2/project/bs999902/archive/BS19900/stop',
    },
    20 => {
        method      => "PUT",
        path        => 'project/bs999902/archive/BS19900/layout',
        payload_in  => { type => 'something', stylesheet => 'something else' },
        payload_out => '{"stylesheet":"something else","type":"something"}',
        params      => { },
        url =>
          'https://video.api.vonage.com/v2/project/bs999902/archive/BS19900/layout',
    },
);

foreach my $key ( sort( keys(%tests) ) ) {    #

    my $test = $tests{$key};

    # warn ("my $key =".Dumper($test));

    my %params;
    foreach my $param ( sort( keys( %{ $test->{params} } ) ) ) {
        $params{$param} = $test->{params}->{$param};
    }
    my $method      = $test->{method};
    my $path        = $test->{path};
    my $payload     = $test->{payload_in};
    my $payload_out = $test->{payload_out};
    my $url         = $test->{url};
    my $response;

    # warn("JSP hee params=".Dumper(\%params));

    eval { $response = $api->$method( $path, $payload, %params ); };

    if ($@) {
        fail( "Test ID:$key failed with this error: " . $@ );
        fail("Test ID:$key Did not get correct URL");
        fail("Test ID:$key Did not get correct Payload");

    }
    else {
        ok( ref($response) eq 'HASH',
            "Test ID:$key returned a hash in test mode" );
        ok(
            $response->{url} eq $url,
            "Test ID:$key Have the correnct URL, Expected:" 
              . $url 
              . ", Got:"
              . $response->{url}
        );
        ok(
            $response->{payload} eq $payload_out,
            "Test ID:$key Have the correnct payload, Expected:"
              . $response->{payload}
              . ", Got:$payload_out"
        );
    }

}

#make sure things stick about after a call

$api = WWW::Vonage::API->new(
    API_Key    => 'dummy_key_123',
    API_Secret => 'dummy_secret_456',
    _test      => 1,
    API_Region => 'rest',
);

my $response;

eval {
    $response =
      $api->GET( 'account/get-balance', undef, API_Version => 'none' );
};

if ($@) {
    fail( "Stick Test GET failed with this error: " . $@ );
    fail("Did not get correct URL");
    fail("Did not get correct Payload");

}
else {
    ok( ref($response) eq 'HASH',
        "Stick Test GET returned a hash in test mode" );
    ok(
        $response->{url} eq 'https://rest.nexmo.com/account/get-balance',
"Have the correnct URL, Expected: https://rest.nexmo.com/account/get-balance, Got:"
          . $response->{url}
    );
    ok(
        $response->{payload} eq undef,
        "Have the correnct payload, Expected: undef"
          . ", Got:$response->{payload}"
    );
}

eval {
    $response =
      $api->POST( 'account/top-up', { trx => '8ef2447e69604f642ae59363a' } );
};

if ($@) {
    fail( "Stick Test GET failed with this error: " . $@ );
    fail("Did not get correct URL");
    fail("Did not get correct Payload");

}
else {
    ok( ref($response) eq 'HASH',
        "Stick Test GET returned a hash in test mode" );
    ok(
        $response->{url} eq 'https://rest.nexmo.com/account/top-up',
"Have the correnct URL, Expected:https://rest.nexmo.com/account/top-up, Got:"
          . $response->{url}
    );
    ok(
        $response->{payload} eq '{"trx":"8ef2447e69604f642ae59363a"}',
'Have the correnct payload, Expected: {"trx":"8ef2447e69604f642ae59363a"}'
          . ", Got:$response->{payload}"
    );
}
