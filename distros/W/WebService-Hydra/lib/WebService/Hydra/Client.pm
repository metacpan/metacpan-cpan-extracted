package WebService::Hydra::Client;

use strict;
use warnings;

use Object::Pad;

class WebService::Hydra::Client;

use HTTP::Tiny;
use Log::Any   qw( $log );
use Crypt::JWT qw(decode_jwt);
use JSON::MaybeUTF8;
use WebService::Hydra::Exception;
use Syntax::Keyword::Try;

use constant OK_STATUS_CODE          => 200;
use constant OK_NO_CONTENT_CODE      => 204;
use constant BAD_REQUEST_STATUS_CODE => 400;

our $VERSION = '0.003';

field $http;
field $jwks;
field $oidc_config;
field $admin_endpoint :param :reader;
field $public_endpoint :param :reader;

=head1 NAME

WebService::Hydra::Client - Hydra Client Object

=head2 Description

Object::Pad based class which is used to create a Hydra Client Object which interacts with the Hydra service API.

=head1 SYNOPSIS

    use WebService::Hydra::Client;
    my $obj = WebService::Hydra::Client->new(admin_endpoint => 'url' , public_endpoint => 'url');

=head1 METHODS

=head2 new

=over 1

=item C<admin_endpoint>

admin_endpoint is a string which contains admin URL for the hydra service. Eg: http://localhost:4445
This is a required parameter when creating Hydra Client Object using new.

=item C<public_endpoint>

public_endpoint is a string which contains the public URL for the hydra service. Eg: http://localhost:4444
This is a required parameter when creating Hydra Client Object using new.

=back

=head2 admin_endpoint

Returns the base URL for the hydra service.

=cut

=head2 public_endpoint

Returns the base URL for the hydra service.

=cut

=head2 http

Return HTTP object.

=cut

method http {
    return $http //= HTTP::Tiny->new();
}

=head2 jwks
return jwks object
=cut

method jwks {
    return $jwks //= $self->fetch_jwks();
}

=head2 oidc_config

returns an object with oidc configuration

=cut

method oidc_config {
    return $oidc_config //= $self->fetch_openid_configuration();
}

=head2 api_call

Takes request method, the endpoint, and the payload. It sends the request to the Hydra service, parses the response and returns:

1. JSON object of code and data returned from the service.
2. Error string in case an exception is thrown.

=cut

method api_call ($method, $endpoint, $payload = undef, $content_type = 'json') {

    try {

        my @args = ($method, $endpoint);
        if ($payload) {
            if ($content_type eq 'FORM') {
                my $headers = {
                    'Content-Type' => 'application/x-www-form-urlencoded',
                    'Accept'       => 'application/json'
                };
                push(
                    @args,
                    {
                        headers => $headers,
                        content => $self->http->www_form_urlencode($payload)});
            } else {
                my $headers = {'Content-Type' => 'application/json'};
                push(
                    @args,
                    {
                        headers => $headers,
                        content => JSON::MaybeUTF8::encode_json_utf8($payload)});
            }
        }

        my $response = $self->http->request(@args);
        my $data     = JSON::MaybeUTF8::decode_json_utf8($response->{content} || '{}');

        WebService::Hydra::Exception::HydraServiceUnreachable->new(
            details => ["An error happened during the execution of the $endpoint request: $response->{content}"])->throw
            if $response->{status} == 599;

        return {
            code => $response->{status},
            data => $data
        };
    } catch ($e) {
        WebService::Hydra::Exception::HydraRequestError->new(
            details => ["Request to $endpoint failed", $e],
        )->throw;
    }
}

=head2 get_login_request

Fetches the OAuth2 login request from hydra.

Arguments:

=over 1

=item C<$login_challenge>

Authentication challenge string that is used to identify and fetch information
about the OAuth2 request from hydra.

=back

=cut

method get_login_request ($login_challenge) {
    my $method = "GET";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/login?challenge=$login_challenge";

    my $result = $self->api_call($method, $path);

    # "410" means that the request was already handled. This can happen on form double-submit or other errors.
    # It's recommended to redirect the user to `request_url` to re-initiate the flow.
    if ($result->{code} == 410) {
        WebService::Hydra::Exception::InvalidLoginChallenge->new(
            message     => "Login challenge has already been handled",
            redirect_to => $result->{data}->{redirect_to},
            category    => 'client_redirecting_error'
        )->throw;
    } elsif ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidLoginChallenge->new(
            message  => "Failed to get login request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 accept_login_request

Accepts the login request and returns the response from hydra.

Arguments:

=over 1

=item C<$login_challenge>

Authentication challenge string that is used to identify the login request.

=item C<$accept_payload>

Payload to be sent to the Hydra service to confirm the login challenge.

=back

=cut

method accept_login_request ($login_challenge, $accept_payload) {
    my $method = "PUT";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/login/accept?challenge=$login_challenge";

    my $result = $self->api_call($method, $path, $accept_payload);
    if ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidLoginRequest->new(
            message  => "Failed to accept login request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 get_logout_request

Get the logout request and return the response from Hydra.

=cut

method get_logout_request ($logout_challenge) {
    my $method = "GET";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/logout?challenge=$logout_challenge";

    my $result = $self->api_call($method, $path);

    # "410" means that the request was already handled. This can happen on form double-submit or other errors.
    # It's recommended to redirect the user to `request_url` to re-initiate the flow.
    if ($result->{code} == 410) {
        WebService::Hydra::Exception::InvalidLogoutChallenge->new(
            message     => "Logout challenge has already been handled",
            redirect_to => $result->{data}->{redirect_to},
            category    => 'client_redirecting_error'
        )->throw;
    } elsif ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidLogoutChallenge->new(
            message  => "Failed to get logout request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 accept_logout_request

The response contains a redirect URL which the logout provider should redirect the user-agent to.

=cut

method accept_logout_request ($logout_challenge) {
    my $method = "PUT";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/logout/accept?challenge=$logout_challenge";
    my $result = $self->api_call($method, $path);
    if ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidLogoutChallenge->new(
            message  => "Failed to accept logout request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 exchange_token

Exchanges the authorization code with Hydra service for access and ID tokens.

=cut

method exchange_token ($exchange_payload) {
    my $method     = "POST";
    my $path       = "$public_endpoint/oauth2/token";
    my $payload    = {
        grant_type => 'authorization_code',
        $exchange_payload->%*
    };
    my $result = $self->api_call($method, $path, $payload, 'FORM');
    if ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::TokenExchangeFailed->new(
            message  => "Failed to exchange token",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 fetch_jwks

Fetches the JSON Web Key Set published by Hydra which is used to validate signatures.

=cut

method fetch_jwks () {
    my $method = "GET";
    my $path   = "$public_endpoint/.well-known/jwks.json";

    my $result = $self->api_call($method, $path);
    if ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::HydraRequestError->new(
            category => "hydra",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 fetch_openid_configuration

Fetches the openid-configuration from hydra

=cut

method fetch_openid_configuration () {
    my $method = "GET";
    my $path   = "$public_endpoint/.well-known/openid-configuration";

    my $result = $self->api_call($method, $path);
    if ($result->{code} != OK_STATUS_CODE) {
        BOM::OAuth::Exceptions::Type::HydraRequestError->new(
            category => "hydra",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 validate_id_token

Decodes the id_token and validates its signature against Hydra and returns the decoded payload.

=cut

method validate_id_token ($id_token) {
    try {
        my $payload = decode_jwt(
            token    => $id_token,
            kid_keys => $self->jwks
        );
        return $payload;
    } catch ($e) {
        WebService::Hydra::Exception::InvalidIdToken->new(
            message  => "Failed to validate id token",
            category => "client",
            details  => $e
        )->throw;
    }
}

=head2 validate_token

Decodes the token and validates its signature against hydra and returns the decoded payload.

=over 1

=item C<$token> jwt token to be validated

=back

Returns the decoded payload if the token is valid, otherwise throws an exception.

=cut

method validate_token ($token) {
    my $payload = decode_jwt(
        token      => $token,
        verify_iat => 1,
        verify_exp => 1,
        verify_iss => $self->oidc_config->{issuer},
        kid_keys   => $self->jwks
    );
    return $payload;
}

=head2 get_consent_request

Fetches the consent request from Hydra.

=cut

method get_consent_request ($consent_challenge) {
    my $method = "GET";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/consent?challenge=$consent_challenge";

    my $result = $self->api_call($method, $path);

    if ($result->{code} == 410) {
        WebService::Hydra::Exception::InvalidConsentChallenge->new(
            message     => "Consent request has already been handled",
            redirect_to => $result->{data}->{redirect_to},
            category    => 'client_redirecting_error'
        )->throw;
    } elsif ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidConsentChallenge->new(
            message  => "Failed to get consent request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 accept_consent_request

Accepts the consent request and returns the response from Hydra.

=cut

method accept_consent_request ($consent_challenge, $params) {
    my $method = "PUT";
    my $path   = "$admin_endpoint/admin/oauth2/auth/requests/consent/accept?challenge=$consent_challenge";

    my $result = $self->api_call($method, $path, $params);
    if ($result->{code} != OK_STATUS_CODE) {
        WebService::Hydra::Exception::InvalidConsentChallenge->new(
            message  => "Failed to accept consent request",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

=head2 revoke_login_sessions

This endpoint invalidates authentication sessions.
It expects a user ID (subject) and invalidates all sessions for this user. or session ID (sid) and invalidates the session.

=cut

method revoke_login_sessions (%args) {
    my $method = "DELETE";
    my $path   = "$admin_endpoint/admin/oauth2/auth/sessions/login";

    my $query = join('&', map { "$_=$args{$_}" } keys %args);
    $path .= "?$query" if $query;

    my $result = $self->api_call($method, $path);
    if ($result->{code} != OK_NO_CONTENT_CODE) {
        WebService::Hydra::Exception::RevokeLoginSessionsFailed->new(
            message  => "Failed to revoke login sessions",
            category => "client",
            details  => $result
        )->throw;
    }
    return $result->{data};
}

1;
