#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Crypt::PK::RSA;
use FakeAuthentik;
use WWW::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $now  = time;
my $fake = FakeAuthentik->new( now => sub { $now } );
my $provider = $fake->add( providers => {
  name => 'probe-provider', client_id => 'probe-client', client_secret => 'probe-secret',
  authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [],
  grant_types => [qw( authorization_code refresh_token client_credentials urn:ietf:params:oauth:grant-type:device_code )]
} );
$fake->add( applications => { name => 'Probe App', slug => 'probe-app', provider => $provider->{pk} } );

my $ak   = WWW::Authentik->new( base_url => $fake->base, application => 'probe-app', token => $fake->token, ua => $fake );
# the facade builds an OIDC client with the real clock; this one shares the
# fake's clock, so the jwks_min_age throttle can be tested without sleeping
my $oidc = WWW::Authentik::OIDC->new( application_url => $ak->application_url, ua => $fake, now => sub { $now } );
my %client = ( client_id => 'probe-client', client_secret => 'probe-secret' );

sub discovery_requests { scalar grep { $_->[1] =~ m{openid-configuration} } @{ $fake->requests } }
sub jwks_requests      { scalar grep { $_->[1] =~ m{/jwks/} } @{ $fake->requests } }

subtest 'discovery and endpoints' => sub {
  is( $oidc->issuer, $fake->base.'/application/o/probe-app/', 'the issuer comes out of the document' );
  is( discovery_requests(), 1, 'fetched once' );
  $oidc->token_endpoint for 1 .. 3;
  is( discovery_requests(), 1, 'and kept' );

  is( $oidc->authorization_endpoint, $fake->base.'/application/o/authorize/', 'authorization_endpoint' );
  is( $oidc->token_endpoint,         $fake->base.'/application/o/token/', 'token_endpoint' );
  is( $oidc->userinfo_endpoint,      $fake->base.'/application/o/userinfo/', 'userinfo_endpoint' );
  is( $oidc->introspection_endpoint, $fake->base.'/application/o/introspect/', 'introspection_endpoint' );
  is( $oidc->revocation_endpoint,    $fake->base.'/application/o/revoke/', 'revocation_endpoint' );
  is( $oidc->end_session_endpoint,   $fake->base.'/application/o/probe-app/end-session/', 'end_session_endpoint is per application' );
  is( $oidc->device_endpoint,        $fake->base.'/application/o/device/', 'device_endpoint' );
  is( $oidc->jwks_uri,               $fake->base.'/application/o/probe-app/jwks/', 'jwks_uri is per application' );

  my $missing = error_of { $oidc->endpoint('no_such_endpoint') };
  isa_ok( $missing, 'WWW::Authentik::Error::Validation' );
  like( "$missing", qr/no_such_endpoint/, 'and names it' );

  my $nowhere = WWW::Authentik->new( base_url => $fake->base, application => 'no-such-app', ua => $fake )->oidc;
  isa_ok( error_of { $nowhere->discovery }, 'WWW::Authentik::Error::API', 'an unknown application' );
};

subtest 'verify_token' => sub {
  my $good = $fake->sign( $fake->claims_for( slug => 'probe-app', aud => 'probe-client' ) );
  my $claims = $oidc->verify_token($good);
  is( $claims->{preferred_username}, 'probe-alice', 'a good token comes back as claims' );

  isa_ok( error_of { $oidc->verify_token(undef) }, 'WWW::Authentik::Error::Validation', 'no token' );
  isa_ok( error_of { $oidc->verify_token('') }, 'WWW::Authentik::Error::Validation', 'an empty token' );

  my %bad = (
    'a wrong issuer' => $fake->sign( { %{ $fake->claims_for }, iss => 'https://elsewhere.example.org/' } ),
    'an expired token' => $fake->sign( $fake->claims_for( exp => $now - 1 ) ),
    'alg none'       => $fake->sign( $fake->claims_for, alg => 'none' ),
    'an HMAC token'  => $fake->sign( $fake->claims_for, alg => 'HS256' ),
    'a foreign key'  => do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $fake->sign( $fake->claims_for, key => $k ) }
  );
  for my $why ( sort keys %bad ) {
    my $error = error_of { $oidc->verify_token( $bad{$why} ) };
    isa_ok( $error, 'WWW::Authentik::Error::Validation', $why );
    like( "$error", qr/token rejected: ./, $why.': says why' );
  }

  is( $oidc->verify_token( $good, audience => 'probe-client' )->{aud}, 'probe-client', 'the right audience' );
  isa_ok( error_of { $oidc->verify_token( $good, audience => 'someone-else' ) }, 'WWW::Authentik::Error::Validation', 'a wrong audience' );

  # authentik puts no typ into the header; scope is the only thing that tells
  # an access token from an ID token
  my $access = $fake->sign( $fake->claims_for( scope => 'openid email' ) );
  ok( $oidc->verify_token( $access, type => 'access' ), 'an access token as access' );
  ok( $oidc->verify_token( $good, type => 'id' ), 'an ID token as id' );
  like( error_of { $oidc->verify_token( $good, type => 'access' ) }, qr/no scope claim/, 'an ID token is not an access token' );
  like( error_of { $oidc->verify_token( $access, type => 'id' ) }, qr/carries a scope claim/, 'and the other way round' );
  isa_ok( error_of { $oidc->verify_token( $good, type => 'nonsense' ) }, 'WWW::Authentik::Error::Validation', 'an unknown type' );
};

subtest 'key rotation' => sub {
  $now += 120;                   # past jwks_min_age since the first fetch
  my $before = jwks_requests();
  $fake->rotate_key;
  my $fresh = $fake->sign( $fake->claims_for );
  ok( $oidc->verify_token($fresh), 'a token with a rotated key is accepted' );
  is( jwks_requests(), $before + 1, 'the keys were fetched once more' );

  my $forged = do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $fake->sign( $fake->claims_for, key => $k, kid => 'made-up' ) };
  my $after = jwks_requests();
  error_of { $oidc->verify_token($forged) } for 1 .. 5;
  is( jwks_requests(), $after, 'an unknown key does not fetch again within jwks_min_age' );

  $now += 120;
  error_of { $oidc->verify_token($forged) };
  is( jwks_requests(), $after + 1, 'but it does once the min age has passed' );
};

subtest 'the token endpoint' => sub {
  isa_ok( error_of { $oidc->client_credentials_token }, 'WWW::Authentik::Error::Validation', 'without a client_id' );

  my $tokens = $oidc->client_credentials_token( %client, scope => 'openid email' );
  ok( $tokens->{access_token}, 'client credentials' );
  is( $tokens->{token_type}, 'Bearer', 'a bearer token' );
  is( $tokens->{scope}, 'openid email', 'the scopes asked for' );

  my $wrong = error_of { $oidc->client_credentials_token( client_id => 'probe-client', client_secret => 'nope' ) };
  is( $wrong->oauth_error, 'invalid_grant', 'a wrong secret' );
  is( error_of { $oidc->client_credentials_token( client_id => 'nobody', client_secret => 'x' ) }->oauth_error,
      'invalid_client', 'an unknown client' );

  is( $oidc->userinfo( $tokens->{access_token} )->{preferred_username}, 'ak-probe-provider-client_credentials', 'userinfo' );
  my $bad_userinfo = error_of { $oidc->userinfo('garbage') };
  is( $bad_userinfo->http_status, 401, 'userinfo with a bad token is 401' );
  is( $bad_userinfo->oauth_error, 'invalid_token', 'with the code out of the WWW-Authenticate header' );

  my $state = $oidc->introspect( $tokens->{access_token}, %client );
  ok( $state->{active}, 'introspect says active' );
  is( $state->{client_id}, 'probe-client', 'and names the client' );
  ok( !$oidc->introspect( 'garbage', %client )->{active}, 'and not for something it does not know' );

  my $code   = $fake->issue_code( scope => 'openid email', amr => ['pwd'] );
  my $logged = $oidc->exchange_authorization_code( code => $code, redirect_uri => 'https://app.example.org/cb', %client );
  ok( $logged->{refresh_token}, 'a code becomes tokens' );
  is( error_of { $oidc->exchange_authorization_code( code => $code, redirect_uri => 'x', %client ) }->oauth_error,
      'invalid_grant', 'a code works once' );

  my $refreshed = $oidc->refresh_token( $logged->{refresh_token}, %client );
  ok( $refreshed->{access_token}, 'refresh' );
  isnt( $refreshed->{refresh_token}, $logged->{refresh_token}, 'the refresh token is rotated' );
  is( error_of { $oidc->refresh_token( $logged->{refresh_token}, %client ) }->oauth_error, 'invalid_grant', 'the old one is dead' );
  is( error_of { $oidc->refresh_token( $refreshed->{refresh_token}, %client, scope => 'openid' ) }->oauth_error,
      'invalid_scope', 'asking for fewer scopes' );
  is_deeply( $oidc->verify_token( $refreshed->{id_token} )->{amr}, ['pwd'], 'amr carries over a refresh' );

  ok( $oidc->revoke( $tokens->{access_token}, %client ), 'revoke' );
  ok( !$oidc->introspect( $tokens->{access_token}, %client )->{active}, 'and it is gone' );
  is( error_of { $oidc->userinfo( $tokens->{access_token} ) }->http_status, 401, 'userinfo refuses it' );
  ok( $oidc->revoke( 'garbage', %client ), 'revoking something unknown is no error' );
};

subtest 'the device flow' => sub {
  my $start = $oidc->device_authorization( %client, scope => 'openid' );
  ok( $start->{device_code}, 'device_authorization' );
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'the complete URI carries the user code' );
  is( $start->{interval}, 5, 'and an interval' );

  my $pending = error_of { $oidc->device_token( device_code => $start->{device_code}, %client ) };
  is( $pending->oauth_error, 'authorization_pending', 'pending before anybody approves' );
  ok( $pending->request_id, 'with a request_id' );

  $fake->approve_device( $start->{user_code} );
  my $tokens = $oidc->device_token( device_code => $start->{device_code}, %client );
  ok( $tokens->{access_token}, 'and tokens after' );
  is_deeply( $oidc->verify_token( $tokens->{id_token} )->{amr}, ['pwd'], 'amr from the login behind it' );
  is( error_of { $oidc->device_token( device_code => $start->{device_code}, %client ) }->oauth_error,
      'invalid_grant', 'the device code is used up' );
};

subtest 'two applications of one instance' => sub {
  # every provider of an authentik signs with the same key, so the issuer is
  # all that keeps one application's tokens out of another's verification
  my $second = $fake->add( providers => {
    name => 'other-provider', client_id => 'other-client', client_secret => 'other-secret',
    authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [],
    grant_types => ['client_credentials']
  } );
  $fake->add( applications => { name => 'Other App', slug => 'other-app', provider => $second->{pk} } );
  my $other = WWW::Authentik::OIDC->new(
    application_url => $fake->base.'/application/o/other-app', ua => $fake, now => sub { $now } );
  my $theirs = $other->client_credentials_token( client_id => 'other-client', client_secret => 'other-secret', scope => 'openid' );

  ok( $oidc->issuer_names_the_application, 'per_provider: the issuer names the application' );
  isa_ok( error_of { $oidc->verify_token( $theirs->{access_token} ) },
    'WWW::Authentik::Error::Validation', "another application's token" );

  # issuer_mode: global makes every provider issue under the bare instance URL
  $fake->collection('providers')->{ $provider->{pk} }{issuer_mode} = 'global';
  $fake->collection('providers')->{ $second->{pk} }{issuer_mode}   = 'global';
  my $global = WWW::Authentik::OIDC->new(
    application_url => $ak->application_url, ua => $fake, now => sub { $now } );
  my $global_other = WWW::Authentik::OIDC->new(
    application_url => $fake->base.'/application/o/other-app', ua => $fake, now => sub { $now } );
  is( $global->issuer, $fake->base.'/', 'global: the issuer is the bare instance' );
  ok( !$global->issuer_names_the_application, 'and does not name the application' );

  my $mine = $global->client_credentials_token( %client, scope => 'openid' );
  my $refused = error_of { $global->verify_token( $mine->{access_token} ) };
  isa_ok( $refused, 'WWW::Authentik::Error::Validation', 'verifying without an audience' );
  like( "$refused", qr/does not name the application/, 'and says why it will not' );

  ok( $global->verify_token( $mine->{access_token}, audience => 'probe-client' ), 'an audience makes it work' );
  isa_ok( error_of { $global->verify_token( $mine->{access_token}, audience => 'other-client' ) },
    'WWW::Authentik::Error::Validation', 'and a wrong one does not' );
  ok( $global->verify_token( $mine->{access_token}, any_audience => 1 ), 'any_audience says you meant it' );

  # the client_id on the client does it by itself
  my $pinned = WWW::Authentik::OIDC->new( application_url => $ak->application_url, ua => $fake,
    now => sub { $now }, client_id => 'probe-client' );
  ok( $pinned->verify_token( $mine->{access_token} ), 'with client_id set, our own token passes' );
  my $theirs_global = $global_other->client_credentials_token(
    client_id => 'other-client', client_secret => 'other-secret', scope => 'openid' );
  isa_ok( error_of { $pinned->verify_token( $theirs_global->{access_token} ) },
    'WWW::Authentik::Error::Validation', "and another application's does not" );
  is( WWW::Authentik->new( base_url => $fake->base, application => 'probe-app', client_id => 'x', ua => $fake )->oidc->client_id,
    'x', 'the facade passes client_id through' );

  $fake->collection('providers')->{ $provider->{pk} }{issuer_mode} = 'per_provider';
  $fake->collection('providers')->{ $second->{pk} }{issuer_mode}   = 'per_provider';
};

subtest 'authorization_url' => sub {
  my $url = $oidc->authorization_url( client_id => 'probe-client', redirect_uri => 'https://app.example.org/cb',
    scope => 'openid email', state => 'st', nonce => 'n' );
  like( $url, qr{\A\Q$fake->{base}\E/application/o/authorize/\?}, 'at the authorization endpoint' );
  like( $url, qr/response_type=code/, 'a code flow by default' );
  like( $url, qr/client_id=probe-client/, 'the client' );
  like( $url, qr{redirect_uri=https%3A%2F%2Fapp\.example\.org%2Fcb}, 'the encoded redirect URI' );
  like( $url, qr/scope=openid(\+|%20)email/, 'the scopes' );
  like( $url, qr/state=st/, 'the state' );
  like( $url, qr/nonce=n/, 'the nonce' );
  like( $oidc->authorization_url( client_id => 'c', redirect_uri => 'u', code_challenge => 'abc', code_challenge_method => 'S256' ),
    qr/code_challenge=abc/, 'PKCE goes through' );
  isa_ok( error_of { $oidc->authorization_url( client_id => 'c' ) }, 'WWW::Authentik::Error::Validation', 'without a redirect_uri' );
  isa_ok( error_of { $oidc->authorization_url( redirect_uri => 'u' ) }, 'WWW::Authentik::Error::Validation', 'without a client_id' );
};

done_testing;
