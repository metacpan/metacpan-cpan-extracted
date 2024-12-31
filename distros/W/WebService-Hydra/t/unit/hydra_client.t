use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use JSON::MaybeUTF8 qw(:v1);
use HTTP::Tiny;
use WebService::Hydra::Client;

subtest 'Hydra Client Creation' => sub {
    my $admin_url  = "http://dummyhydra.com/admin";
    my $public_url = "http://dummyhydra.com";
    my $client     = WebService::Hydra::Client->new(
        admin_endpoint  => $admin_url,
        public_endpoint => $public_url
    );
    is $client->admin_endpoint,  $admin_url,  'Client created successfully with admin endpoint';
    is $client->public_endpoint, $public_url, 'Client created successfully with public endpoint';
};

subtest 'api_call method' => sub {
    my $mock_http = Test::MockModule->new("HTTP::Tiny");
    my ($code, $mock_http_response, @params);

    $mock_http->redefine(
        'request',
        sub {
            (@params) = @_;
            return {
                status  => $code,
                content => ref $mock_http_response ? encode_json_utf8($mock_http_response) : $mock_http_response
            };
        });
    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    $code               = 200;
    $mock_http_response = {key => 'value'};
    my $expected = {
        code => $code,
        data => $mock_http_response
    };
    my $got = $client->api_call('GET', 'http://dummyhydra.com/oauth2/auth');
    is $params[1], 'GET',                               'Correct http method is used';
    is $params[2], 'http://dummyhydra.com/oauth2/auth', 'Request sent to correct endpoint';
    cmp_deeply($got, $expected, 'Data returned in expected structure');

    $mock_http_response = undef;
    my $payload = {key => 'value'};
    $got = $client->api_call('POST', 'http://dummyhydra.com/oauth2/auth', $payload);
    my $extra_request_params = $params[3];
    is $extra_request_params->{headers}->{'Content-Type'}, 'application/json',         'Content type: JSON used for payload';
    is $extra_request_params->{content},                   encode_json_utf8($payload), 'Payload is set correctly';
    is_deeply $got->{data}, {}, 'Returns an empty hash for Empty payload';

    $mock_http_response = undef;
    $payload            = {
        key  => 'value',
        key2 => 'value2'
    };
    $got                  = $client->api_call('POST', 'http://dummyhdra.com/oauth2/auth', $payload, 'FORM');
    $extra_request_params = $params[3];
    is $extra_request_params->{headers}->{'Content-Type'}, 'application/x-www-form-urlencoded', 'Content type: form-urlencode used for payload';
    is $extra_request_params->{headers}->{'Accept'},       'application/json',                  'Sets JSON as the accepted response content-type';
    is $extra_request_params->{content},                   HTTP::Tiny->new->www_form_urlencode($payload), 'Payload is set correctly';

    $mock_http->redefine(
        'request',
        sub {
            die 'Network issue';
        });

    dies_ok { $client->api_call('GET', 'http://dummyhydra.com/oauth2/auth') } 'Dies if the request fails';
    my $exception = $@;
    ok $exception->isa('WebService::Hydra::Exception::HydraRequestError'), 'Error response on die';

};

subtest 'get_login_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    $mock_api_response = {
        code => 200,
        data => {
            challenge   => 'VALID_CHALLENGE',
            client      => {},
            request_url => 'url',
            skip        => 'true',
            subject     => 'user_id'
        }};
    my $got = $client->get_login_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/login?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_login_request("INVALID_CHALLENGE") } 'Dies if non 200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLoginChallenge->new(
        message  => 'Failed to get login request',
        category => 'client',
        details  => $mock_api_response
    );

    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/login?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_login_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'get_consent_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {
            challenge   => 'VALID_CHALLENGE',
            client      => {},
            request_url => 'url',
            skip        => 'true',
            subject     => 'user_id'
        }};
    my $got = $client->get_consent_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/consent?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for 410 Gone status code
    $mock_api_response = {
        code => 410,
        data => {redirect_to => 'http://dummyhydra.com/redirect'}};
    dies_ok { $client->get_consent_request("HANDLED_CHALLENGE") } 'Dies if 410 status code is received from api_call';
    my $exception = $@;

    my $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message     => 'Consent request has already been handled',
        category    => 'client_redirecting_error',
        redirect_to => $mock_api_response->{data}->{redirect_to});
    is_deeply $exception , $expected_exception, 'Return api_call response for 410 status code';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_consent_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    $exception          = $@;
    $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message  => 'Failed to get consent request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_consent_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'accept_consent_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    my $params = {
        grant_scope                 => ['openid', 'offline'],
        grant_access_token_audience => ['client_id'],
        session                     => {id_token => {sub => 'user'}}};

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {redirect_to => 'http://dummyhydra.com/callback'}};
    my $got = $client->accept_consent_request("VALID_CHALLENGE", $params);
    is $params[1], 'PUT', 'PUT request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $params[3], $params,                    'Request parameters are correct';
    is_deeply $got ,      $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->accept_consent_request("INVALID_CHALLENGE", $params) } 'Dies if non-200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message  => 'Failed to accept consent request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->accept_consent_request("VALID_CHALLENGE", $params) } 'Dies if http request fails for some reason';
};

subtest 'get_logout_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {
            challenge    => "5511ea26-6334-4f5c-9fe1-d812f5ca4068",
            subject      => "1",
            sid          => "2505a9e4-5e48-4911-9af4-31124c7b2217",
            request_url  => "/oauth2/sessions/logout",
            rp_initiated => 0,
            client       => undef,
        }};
    my $got = $client->get_logout_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/logout?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for 410 Gone status code
    $mock_api_response = {
        code => 410,
        data => {redirect_to => 'http://dummyhydra.com/redirect'}};
    dies_ok { $client->get_logout_request("HANDLED_CHALLENGE") } 'Dies if 410 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message     => 'Logout challenge has already been handled',
        category    => 'client_redirecting_error',
        redirect_to => $mock_api_response->{data}->{redirect_to});
    is_deeply $exception , $expected_exception, 'Return api_call response for 410 status code';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_logout_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    $exception          = $@;
    $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message  => 'Failed to get logout request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/logout?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_logout_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'accept_logout_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {redirect_to => 'http://dummyhydra.com/callback'}};
    my $got = $client->accept_logout_request("VALID_CHALLENGE");
    is $params[1], 'PUT', 'PUT request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/logout/accept?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->accept_logout_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message  => 'Failed to accept logout request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->accept_logout_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'revoke_login_sessions' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 204,
        data => undef
    };
    my $got = $client->revoke_login_sessions(subject => '1234');

    is $params[1], 'DELETE',                                                                    'DELETE request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/sessions/login?subject=1234', 'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    @params = ();
    $got    = $client->revoke_login_sessions(sid => '1234');

    is $params[1], 'DELETE',                                                                'DELETE request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/sessions/login?sid=1234', 'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 401,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 401
        }};
    dies_ok { $client->revoke_login_sessions(subject => "invalid") } 'Dies if non-200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::RevokeLoginSessionsFailed->new(
        message  => 'Failed to revoke login sessions',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->accept_logout_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'fetch_openid_configuration' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {
            issuer                 => 'http://dummyhydra.com',
            authorization_endpoint => 'http://dummyhydra.com/oauth2/auth',
            token_endpoint         => 'http://dummyhydra.com/oauth2/token',
            jwks_uri               => 'http://dummyhydra.com/.well-known/jwks.json',
        }};
    my $got = $client->fetch_openid_configuration();
    is $params[1], 'GET',                                                    'GET request method';
    is $params[2], 'http://dummyhydra.com/.well-known/openid-configuration', 'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};

    dies_ok { $client->fetch_openid_configuration() } 'Dies if non-200 status code is received from api_call';
};

subtest 'oidc_config' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'fetch_openid_configuration',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        issuer                 => 'http://dummyhydra.com',
        authorization_endpoint => 'http://dummyhydra.com/oauth2/auth',
        token_endpoint         => 'http://dummyhydra.com/oauth2/token',
        jwks_uri               => 'http://dummyhydra.com/.well-known/jwks.json',
    };

    my $got = $client->oidc_config();
    is_deeply $got, $mock_api_response, 'oidc_config returned correctly';

    subtest 'test cahcing of oidc_config' => sub {
        my $call_count = 0;
        $mock_hydra->redefine(
            'fetch_openid_configuration',
            sub {
                $call_count++;
                return $mock_api_response;
            });

        my $client = WebService::Hydra::Client->new(
            admin_endpoint  => 'http://dummyhydra.com/admin',
            public_endpoint => 'http://dummyhydra.com'
        );
        $got = $client->oidc_config();
        is $call_count, 1, 'fetch_openid_configuration called only once';

        $got = $client->oidc_config();
        is $call_count, 1, 'fetch_openid_configuration not called again';
    };

};

subtest 'reject_login_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    my $reject_payload = {
        error             => 'access_denied',
        error_debug       => 'User authentication failed',
        error_description => 'Invalid credentials provided',
        error_hint        => 'Check your username and password',
        status_code       => 401
    };

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {redirect_to => 'http://dummyhydra.com/error'}};

    my $got = $client->reject_login_request("VALID_CHALLENGE", $reject_payload);
    is $params[1], 'PUT', 'PUT request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/login/reject?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $params[3], $reject_payload,            'Request payload is correct';
    is_deeply $got,       $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};

    dies_ok { $client->reject_login_request("INVALID_CHALLENGE", $reject_payload) }
    'Dies if non-200 status code is received from api_call';

    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLoginRequest->new(
        message  => 'Failed to reject login request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception, $expected_exception, 'Return api_call response for Non 200 status code';

    # Test network failure
    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/login/reject?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->reject_login_request("VALID_CHALLENGE", $reject_payload) }
    'Dies if http request fails for some reason';
};

subtest 'validate_token' => sub {
    my $mock_hydra       = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_token       = 'mock.jwt.token';
    my $mock_oidc_config = {issuer => 'https://example.com'};
    my $mock_jwks        = {keys   => [{kid => 'key1', kty => 'RSA', n => '...', e => '...'}]};
    my $mock_payload     = {
        sub   => '1234567890',
        name  => 'John Doe',
        admin => 'true'
    };

    $mock_hydra->redefine(
        'decode_jwt',
        sub {
            my %args = @_;
            if ($args{token} eq $mock_token) {
                return $mock_payload;
            } else {
                die "Invalid token";
            }
        });

    $mock_hydra->redefine(
        'fetch_openid_configuration',
        sub {
            return $mock_oidc_config;
        });

    $mock_hydra->redefine(
        'fetch_jwks',
        sub {
            return $mock_jwks;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    subtest 'validate_token' => sub {
        my $decoded_payload;

        lives_ok {
            $decoded_payload = $client->validate_token($mock_token);
        }
        'Token validation should succeed';

        is_deeply($decoded_payload, $mock_payload, 'Decoded payload should match expected payload');

        throws_ok {
            $client->validate_token('invalid.token');
        }
        qr/Invalid token/, 'Invalid token should throw an exception';
    };
};

done_testing();

1;
