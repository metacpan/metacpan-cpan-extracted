#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Test::Exception;
use WebService::HMRC::Authenticate;
use LWP::UserAgent;

plan tests => 54;

my ($ws, $uri, $token);


# Instatiate the basic object with no specified parameters
$ws = WebService::HMRC::Authenticate->new();
isa_ok($ws, 'WebService::HMRC::Authenticate', 'WebService::HMRC::Authenticate object created without parameters');


# Authorisation_url method should fail without a client_id being specified
dies_ok {
    $ws->authorisation_url({
        scopes => ['hello'],
        redirect_uri => 'http://localhost/',
    })
} 'authorisation_uri method dies without client_id';

# Instantiate object with specified parameters
$ws = WebService::HMRC::Authenticate->new({
    client_id => 'FAKE_CLIENT_ID',
    client_secret => 'FAKE_CLIENT_SECRET',
});
isa_ok($ws, 'WebService::HMRC::Authenticate', 'WebService::HMRC::Authenticate object created with parameters');


# Must specify an authorisation scope to generate an authorisation_url
dies_ok {
    $ws->authorisation_url({
        redirect_uri => 'http://localhost/'
    })
} 'authorisation_uri method dies without scopes parameter';


# Must specify a redirect_uri
dies_ok {
    $ws->authorisation_uri({
        scopes => ['hello']
    })
} 'authorisation_url method dies without redirect_uri parameter';


# Generates a URI with scopes and redirect
$uri = $ws->authorisation_url({
    scopes => ['hello'],
    redirect_uri => 'http://localhost/',
});
isa_ok($uri, 'URI', 'authorisation_url method returns URI given scope and redirect parameters');

# Generates a URI with scopes and redirect
$uri = $ws->authorisation_url({
    scopes => ['hello', 'scope2'],
    redirect_uri => 'http://localhost/',
    state => '%&;?' # characters which need encoding
});
isa_ok($uri, 'URI', 'authorisation_url method returns URI given scope, redirect and state parameters');
like($uri, qr|^https://test-api.service.hmrc.gov.uk/oauth/authorize\?|, 'authorisation_url method generates correct scheme/path');
like($uri, qr|[&?]client_id=FAKE_CLIENT_ID|, 'authorisation_url generates correct client_id query');
like($uri, qr|[&?]redirect_uri=http%3A%2F%2Flocalhost%2F|, 'authorisation_url generates correct redirect_uri query');
like($uri, qr|[&?]response_type=code|, 'authorisation_url generates correct response_type query');
like($uri, qr|[&?]scope=hello\+scope2|, 'authorisation_url generates correct scope query');
like($uri, qr|[&?]state=%25%26%3B%3F|, 'authorisation_url generates correct state query');


# Test extract_tokens method with valid data
ok($ws->extract_tokens({
    scope => 'TEST_SCOPE ANOTHER_SCOPE',
    access_token => 'ACCESS_TOKEN',
    refresh_token => 'REFRESH_TOKEN',
    token_type => 'bearer',
    expires_in => 1000,
}), 'extract_tokens method returns true with valid data');
ok($ws->has_scope('TEST_SCOPE'), 'extract_tokens yields TEST_SCOPE scope');
ok($ws->has_scope('ANOTHER_SCOPE'), 'extract_tokens yields ANOTHER_SCOPE scope');
is(scalar @{$ws->scopes}, 2, 'scopes property contains 2 scopes');
is($ws->access_token, 'ACCESS_TOKEN', 'extract_tokens updates access_token property');
is($ws->refresh_token, 'REFRESH_TOKEN', 'extract_tokens updates refresh_token property');
is(int(($ws->expires_epoch - time - 1000) / 10), 0, 'extract_tokens updates expires_epoch property within 10 seconds');


# Test extract tokens method with invalid data
ok(!$ws->extract_tokens({
    scope => 'TEST_SCOPE',
    access_token => 'ACCESS_TOKEN',
    refresh_token => 'REFRESH_TOKEN',
    token_type => '!!--INVALID--!!',
    expires_in => 1000,
}), 'extract_tokens method returns false with invalid data');
is($ws->scopes, undef, 'extract_tokens clears scopes property on invalid data');
is($ws->access_token, undef, 'extract_tokens clears access_token property on invalid data');
is($ws->refresh_token, undef, 'extract_tokens clears refresh_token property on invalid data');
is($ws->expires_epoch, undef, 'extract_tokens clears expires_epoch property on invalid data');



SKIP: {

    # These tests construct an authorisation url and check
    # that it returns a successful http response.
    #
    # To run these tests:
    #   * HMRC_CLIENT_ID environment variable must be set
    #   * an application must be registered with HMRC
    #   * urn:ietf:wg:oauth:2.0:oob must be set as a valid redirect_uri for the application
    #   * the application must be enabled for the 'Hello World' test api
    #   * the HMRC sandbox test api endpoints must be functioning

    my $client_id = $ENV{HMRC_CLIENT_ID} or skip (
        'Skipping tests which call /oauth/authorize endpoint as environment variable HMRC_CLIENT_ID is not set',
        3,
    );

    $ws = WebService::HMRC::Authenticate->new({
        client_id => $client_id,
    });

    $uri = $ws->authorisation_url({
        scopes => ['hello'],
        redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
        state => 'taLRXDsK2aWY' # fixed value for deterministic testing
    });
    isa_ok($uri, 'URI', 'authorisation_url method returns URI for test of /oauth/authorize endpoint');

    # Output url - tester may wish to open this manually to generate
    # an authorisation code.
    diag("Generated authorisation url:\n$uri\n");

    # Create user agent to test url validity
    my $ua = LWP::UserAgent->new();
    isa_ok($ua, 'LWP::UserAgent', 'created LWP::UserAgent');

    my $result = $ua->get($uri);
    ok($result->is_success, 'url generated by authorization_url method responds OK');
}


SKIP: {
    # To run these tests:
    #   * an application must be registered with HMRC
    #   * HMRC_CLIENT_ID environment variable must be set
    #   * HMRC_CLIENT_SECRET environment variable must be set
    #   * HMRC_AUTH_CODE environment variable must be set
    #       (code received from authorisation_url page after approval)
    #   * the HMRC sandbox test api endpoints must be functioning

    my $skip_count = 26;
    my $client_id = $ENV{HMRC_CLIENT_ID} or skip (
        'Skipping tests which call /oauth/token endpoint as environment variable HMRC_CLIENT_ID is not set',
        $skip_count,
    );
    my $client_secret = $ENV{HMRC_CLIENT_SECRET} or skip (
        'Skipping tests which call /oauth/token endpoint as environment variable HMRC_CLIENT_SECRET is not set',
        $skip_count,
    );
    my $authorisation_code = $ENV{HMRC_AUTH_CODE} or skip (
        'Skipping tests which call /oauth/token endpoint as environment variable HMRC_AUTH_CODE is not set',
        $skip_count,
    );

    isa_ok(
        $ws = WebService::HMRC::Authenticate->new({
            client_id => $client_id,
            client_secret => $client_secret,
        }),
        'WebService::HMRC::Authenticate',
        'created object to test get_access_token method'
    );

    # Get Access Token
    isa_ok(
        $token = $ws->get_access_token({
            redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
            authorisation_code => $authorisation_code,
        }),
        'WebService::HMRC::Response',
        'get_access_token method returned WebService::HMRC::Response object'
    );

    isa_ok($token, 'WebService::HMRC::Response', 'authorisation_url method returns WebService::HMRC::Response for test of /oauth/token endpoint');
    ok($token->is_success, 'successful response from /oauth/token endpoint');
    ok($token->data->{access_token}, 'response from /oauth/token endpoint contains access_token');
    is($token->data->{token_type}, 'bearer', 'response from /oauth/token endpoint contains correct token_type');
    like($token->data->{expires_in}, qr/^\d+$/, 'response from /oauth/token endpoint contains numeric expires_in field');
    ok($token->data->{refresh_token}, 'response from /oauth/token endpoint contains refresh_token');
    is($token->data->{scope}, 'hello', 'response from /oauth/token endpoint contains correct scope');

    # Have properties been updated?
    is($ws->access_token, $token->data->{access_token}, 'access_token property updated');
    is($ws->refresh_token, $token->data->{refresh_token}, 'refresh_token property updated');
    is(join(" ", @{$ws->scopes}), $token->data->{scope}, 'scope property updated');
    is(int((time + $token->data->{expires_in} - $ws->{expires_epoch}) / 10), 0, 'expires epoch updated correctly (within 10 seconds)');


    # Refresh Access Token
    my $refreshed_tokens = $ws->refresh_tokens;

    isa_ok($refreshed_tokens, 'WebService::HMRC::Response', 'refresh method returns WebService::HMRC::Response');
    ok($refreshed_tokens->is_success, 'refresh method yields successful response');
    ok($refreshed_tokens->data->{access_token}, 'refresh method yields access_token');
    is($refreshed_tokens->data->{token_type}, 'bearer', 'refresh method yields correct token_type');
    like($refreshed_tokens->data->{expires_in}, qr/^\d+$/, 'refresh method yields numeric expires_in field');
    ok($refreshed_tokens->data->{refresh_token}, 'refresh method yields refresh_token');
    is($refreshed_tokens->data->{scope}, 'hello', 'refresh method yields correct scope');

    # Have properties been updated?
    is($ws->access_token, $refreshed_tokens->data->{access_token}, 'refreshed access_token property updated');
    is($ws->refresh_token, $refreshed_tokens->data->{refresh_token}, 'refreshed refresh_token property updated');
    is(join(" ", @{$ws->scopes}), $refreshed_tokens->data->{scope}, 'refreshed scope property updated');
    is(int((time + $refreshed_tokens->data->{expires_in} - $ws->{expires_epoch}) / 10), 0, 'expires epoch updated correctly (within 10 seconds)');

    # Are tokens different?
    isnt($token->data->{access_token}, $ws->{access_token}, 'refreshed access_token has changed');
    isnt($token->data->{refresh_token}, $ws->{refresh_token}, 'refreshed refresh_token has changed');

    # Output tokens - tester may wish to use them for further testing
    diag("refeshed tokens:\n");
    diag(Dumper $refreshed_tokens->data);
}
