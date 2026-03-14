use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::MaybeXS qw(encode_json);

use WWW::Zitadel::OIDC;

{
    package Local::Response;

    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }

    sub is_success      { $_[0]->{is_success} }
    sub status_line     { $_[0]->{status_line} }
    sub decoded_content { $_[0]->{decoded_content} // '' }
}

{
    package Local::OIDCUA;

    sub new {
        my ($class, %args) = @_;
        bless {
            get_queue  => $args{get_queue}  || [],
            post_queue => $args{post_queue} || [],
            calls      => { get => [], post => [] },
        }, $class;
    }

    sub calls { $_[0]->{calls} }

    sub get {
        my ($self, @args) = @_;
        push @{ $self->{calls}{get} }, [@args];
        my $res = shift @{ $self->{get_queue} };
        die "No mocked GET response available\n" unless $res;
        return $res;
    }

    sub post {
        my ($self, @args) = @_;
        push @{ $self->{calls}{post} }, [@args];
        my $res = shift @{ $self->{post_queue} };
        die "No mocked POST response available\n" unless $res;
        return $res;
    }
}

{
    package Local::MockOIDC;

    use Moo;
    extends 'WWW::Zitadel::OIDC';

    has decoder => (
        is       => 'ro',
        required => 1,
    );

    sub _decode_jwt {
        my ($self, %args) = @_;
        return $self->decoder->($self, %args);
    }
}

sub _discovery_json {
    return {
        jwks_uri               => 'https://zitadel.example.com/oauth/v2/keys',
        token_endpoint         => 'https://zitadel.example.com/oauth/v2/token',
        userinfo_endpoint      => 'https://zitadel.example.com/oidc/v1/userinfo',
        authorization_endpoint => 'https://zitadel.example.com/oauth/v2/authorize',
        introspection_endpoint => 'https://zitadel.example.com/oauth/v2/introspect',
    };
}

sub _success_json {
    my ($data) = @_;
    return Local::Response->new(
        is_success      => 1,
        status_line     => '200 OK',
        decoded_content => encode_json($data),
    );
}

# Discovery endpoints are parsed and cached.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [ _success_json(_discovery_json()) ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    is $oidc->jwks_uri, 'https://zitadel.example.com/oauth/v2/keys', 'jwks_uri from discovery';
    is $oidc->token_endpoint, 'https://zitadel.example.com/oauth/v2/token', 'token_endpoint from discovery';
    is $oidc->userinfo_endpoint, 'https://zitadel.example.com/oidc/v1/userinfo', 'userinfo endpoint from discovery';

    my $discovery_again = $oidc->discovery;
    is $discovery_again->{authorization_endpoint}, 'https://zitadel.example.com/oauth/v2/authorize', 'discovery is cached';
    is scalar @{ $ua->calls->{get} }, 1, 'discovery fetched exactly once';
}

# JWKS is cached and force_refresh bypasses cache.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            _success_json({ keys => [ { kid => 'k1' } ] }),
            _success_json({ keys => [ { kid => 'k2' } ] }),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    my $first = $oidc->jwks;
    my $second = $oidc->jwks;
    my $third = $oidc->jwks(force_refresh => 1);

    is $first->{keys}[0]{kid}, 'k1', 'first JWKS fetch works';
    is $second->{keys}[0]{kid}, 'k1', 'second JWKS call uses cache';
    is $third->{keys}[0]{kid}, 'k2', 'force_refresh fetches a new JWKS';
    is scalar @{ $ua->calls->{get} }, 3, 'discovery + 2 JWKS GET calls';
}

# verify_token retries once after JWKS refresh when initial verification fails.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            _success_json({ keys => [ { kid => 'old' } ] }),
            _success_json({ keys => [ { kid => 'new' } ] }),
        ],
    );

    my $decode_calls = 0;
    my @seen_kids;

    my $oidc = Local::MockOIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
        decoder => sub {
            my ($self, %args) = @_;
            $decode_calls++;
            push @seen_kids, $args{kid_keys}{keys}[0]{kid};
            die "signature check failed" if $decode_calls == 1;
            return { sub => 'user-1' };
        },
    );

    my $claims = $oidc->verify_token('token-value');
    is_deeply $claims, { sub => 'user-1' }, 'verify_token returns claims after retry';
    is $decode_calls, 2, 'decode_jwt called twice due to retry';
    is_deeply \@seen_kids, [ 'old', 'new' ], 'retry uses refreshed JWKS';
}

# no_retry disables JWKS refresh retry.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            _success_json({ keys => [ { kid => 'old' } ] }),
            _success_json({ keys => [ { kid => 'new' } ] }),
        ],
    );

    my $oidc = Local::MockOIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
        decoder => sub { die "always bad" },
    );

    throws_ok { $oidc->verify_token('token-value', no_retry => 1) }
        qr/always bad/, 'no_retry keeps original decode error';

    is scalar @{ $ua->calls->{get} }, 2, 'no JWKS refresh when no_retry is set';
}

# userinfo and introspect use endpoint + expected auth/body.
{
    my $ua = Local::OIDCUA->new(
        get_queue  => [ _success_json(_discovery_json()), _success_json({ sub => 'abc' }) ],
        post_queue => [ _success_json({ active => JSON::MaybeXS::true }) ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    my $userinfo = $oidc->userinfo('access-token-1');
    is $userinfo->{sub}, 'abc', 'userinfo returns decoded JSON';

    my $get_call = $ua->calls->{get}[1];
    is $get_call->[0], 'https://zitadel.example.com/oidc/v1/userinfo', 'userinfo endpoint used';
    is $get_call->[2], 'Bearer access-token-1', 'userinfo sends bearer token';

    my $introspection = $oidc->introspect(
        'token-2',
        client_id     => 'client-1',
        client_secret => 'secret-1',
    );

    ok $introspection->{active}, 'introspection response decoded';

    my $post_call = $ua->calls->{post}[0];
    is $post_call->[0], 'https://zitadel.example.com/oauth/v2/introspect', 'introspection endpoint used';
    is $post_call->[2], 'application/x-www-form-urlencoded', 'introspection uses form content type';
    is $post_call->[4]{client_id}, 'client-1', 'introspection sends client_id';
    is $post_call->[4]{token_type_hint}, 'access_token', 'default token_type_hint is access_token';

    throws_ok { $oidc->introspect('x') }
        qr/client_id and client_secret/, 'introspect enforces client credentials';
}

# userinfo/introspect/token endpoint failure paths are surfaced as dies.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            Local::Response->new(
                is_success      => 0,
                status_line     => '401 Unauthorized',
                decoded_content => '{"error":"invalid_token"}',
            ),
        ],
        post_queue => [
            Local::Response->new(
                is_success      => 0,
                status_line     => '400 Bad Request',
                decoded_content => '{"error":"invalid_request"}',
            ),
            _success_json({ active => JSON::MaybeXS::true }),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    throws_ok { $oidc->userinfo('bad-token') }
        qr/UserInfo failed: 401 Unauthorized/, 'userinfo failure includes status line';

    throws_ok {
        $oidc->token(
            grant_type    => 'client_credentials',
            client_id     => 'client-1',
            client_secret => 'wrong',
        );
    } qr/Token endpoint failed: 400 Bad Request/, 'token failure includes status line';

    my $introspection = $oidc->introspect(
        'token-3',
        client_id       => 'client-1',
        client_secret   => 'secret-1',
        token_type_hint => 'refresh_token',
    );
    ok $introspection->{active}, 'introspection still succeeds with custom token_type_hint';
    is $ua->calls->{post}[1][4]{token_type_hint}, 'refresh_token', 'custom token_type_hint forwarded';
}

# token endpoint helpers use expected grant payloads.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [ _success_json(_discovery_json()) ],
        post_queue => [
            _success_json({ access_token => 'cc-token' }),
            _success_json({ access_token => 'refresh-token' }),
            _success_json({ access_token => 'code-token' }),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    my $cc = $oidc->client_credentials_token(
        client_id     => 'client-1',
        client_secret => 'secret-1',
        scope         => 'openid profile',
    );
    is $cc->{access_token}, 'cc-token', 'client_credentials_token returns payload';

    my $refresh = $oidc->refresh_token(
        'refresh-123',
        client_id     => 'client-1',
        client_secret => 'secret-1',
    );
    is $refresh->{access_token}, 'refresh-token', 'refresh_token returns payload';

    my $code = $oidc->exchange_authorization_code(
        code          => 'code-123',
        redirect_uri  => 'https://app.example.com/callback',
        client_id     => 'client-1',
        client_secret => 'secret-1',
        code_verifier => 'verifier-123',
    );
    is $code->{access_token}, 'code-token', 'authorization_code exchange returns payload';

    my $cc_call = $ua->calls->{post}[0];
    is $cc_call->[0], 'https://zitadel.example.com/oauth/v2/token', 'token endpoint used for client_credentials';
    is $cc_call->[4]{grant_type}, 'client_credentials', 'client_credentials grant_type set';
    is $cc_call->[4]{scope}, 'openid profile', 'client_credentials scope forwarded';

    my $refresh_call = $ua->calls->{post}[1];
    is $refresh_call->[4]{grant_type}, 'refresh_token', 'refresh_token grant_type set';
    is $refresh_call->[4]{refresh_token}, 'refresh-123', 'refresh token forwarded';

    my $code_call = $ua->calls->{post}[2];
    is $code_call->[4]{grant_type}, 'authorization_code', 'authorization_code grant_type set';
    is $code_call->[4]{redirect_uri}, 'https://app.example.com/callback', 'authorization code redirect_uri forwarded';
    is $code_call->[4]{code_verifier}, 'verifier-123', 'authorization code extra params forwarded';

    throws_ok { $oidc->token() } qr/grant_type required/, 'token requires grant_type';
    throws_ok { $oidc->client_credentials_token(client_secret => 'x') } qr/client_id required/, 'client_credentials_token requires client_id';
    throws_ok { $oidc->refresh_token('') } qr/refresh_token required/, 'refresh_token requires a token';
    throws_ok { $oidc->exchange_authorization_code(redirect_uri => 'https://app.example.com/cb') } qr/code required/, 'authorization code exchange requires code';
    throws_ok { $oidc->exchange_authorization_code(code => 'x') } qr/redirect_uri required/, 'authorization code exchange requires redirect_uri';
}

# Malformed / non-JSON body on a successful HTTP response dies cleanly.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            Local::Response->new(
                is_success      => 1,
                status_line     => '200 OK',
                decoded_content => '<html>not json</html>',
            ),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    # decode_json throws on invalid JSON; that exception propagates to the caller
    throws_ok { $oidc->jwks } qr/.+/, 'non-JSON JWKS body causes an exception';
}

# Truncated JSON body also causes a decode error.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            Local::Response->new(
                is_success      => 1,
                status_line     => '200 OK',
                decoded_content => '{"keys":[{"kid":"k1"',   # truncated
            ),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    throws_ok { $oidc->jwks } qr/.+/, 'truncated JSON JWKS body causes an exception';
}

# Empty JWKS keys array is valid JSON but verify_token should still fail
# (Crypt::JWT cannot find a matching key).
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            _success_json({ keys => [] }),          # valid but empty
            _success_json({ keys => [] }),          # for the retry fetch
        ],
    );

    my $oidc = Local::MockOIDC->new(
        issuer  => 'https://zitadel.example.com',
        ua      => $ua,
        decoder => sub { die "no matching key found" },
    );

    throws_ok { $oidc->verify_token('some.jwt.token') }
        qr/no matching key found/, 'empty JWKS keys array causes verify_token to die';
}

# Token with missing required claims: decoder receives the JWKS but dies on
# claim validation; the error propagates after the retry attempt.
{
    my $decode_calls = 0;

    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            _success_json({ keys => [ { kid => 'k1' } ] }),
            _success_json({ keys => [ { kid => 'k2' } ] }),
        ],
    );

    my $oidc = Local::MockOIDC->new(
        issuer  => 'https://zitadel.example.com',
        ua      => $ua,
        decoder => sub {
            $decode_calls++;
            die "missing required claim: sub";
        },
    );

    throws_ok { $oidc->verify_token('some.jwt.token') }
        qr/missing required claim: sub/, 'missing claim error propagates after retry';
    is $decode_calls, 2, 'decoder called twice (initial + retry) for missing-claim error';
}

# Discovery endpoint returning incomplete document: missing jwks_uri.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json({
                token_endpoint    => 'https://zitadel.example.com/oauth/v2/token',
                # jwks_uri intentionally absent
            }),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    throws_ok { $oidc->jwks_uri }
        qr/No jwks_uri in discovery document/, 'missing jwks_uri in discovery dies';
    throws_ok { $oidc->userinfo_endpoint }
        qr/No userinfo_endpoint/, 'missing userinfo_endpoint in discovery dies';
    throws_ok { $oidc->authorization_endpoint }
        qr/No authorization_endpoint/, 'missing authorization_endpoint in discovery dies';
    throws_ok { $oidc->introspection_endpoint }
        qr/No introspection_endpoint/, 'missing introspection_endpoint in discovery dies';

    is scalar @{ $ua->calls->{get} }, 1, 'incomplete discovery fetched only once (cached)';
}

# Network failure fetching discovery dies as WWW::Zitadel::Error::Network.
{
    use WWW::Zitadel::Error;

    my $ua = Local::OIDCUA->new(
        get_queue => [
            Local::Response->new(
                is_success  => 0,
                status_line => '503 Service Unavailable',
                decoded_content => '',
            ),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    eval { $oidc->discovery };
    my $err = $@;
    ok ref $err && $err->isa('WWW::Zitadel::Error::Network'), 'discovery failure throws Network exception';
    like "$err", qr/Discovery failed: 503/, 'discovery Network error stringifies with status';
}

# Network failure fetching JWKS dies as WWW::Zitadel::Error::Network.
{
    my $ua = Local::OIDCUA->new(
        get_queue => [
            _success_json(_discovery_json()),
            Local::Response->new(
                is_success  => 0,
                status_line => '500 Internal Server Error',
                decoded_content => '',
            ),
        ],
    );

    my $oidc = WWW::Zitadel::OIDC->new(
        issuer => 'https://zitadel.example.com',
        ua     => $ua,
    );

    eval { $oidc->jwks };
    my $err = $@;
    ok ref $err && $err->isa('WWW::Zitadel::Error::Network'), 'JWKS fetch failure throws Network exception';
    like "$err", qr/JWKS fetch failed: 500/, 'JWKS Network error stringifies with status';
}

done_testing;
