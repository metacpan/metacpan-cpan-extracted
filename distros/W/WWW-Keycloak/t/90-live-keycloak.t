#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Live test against a real Keycloak. Off unless KEYCLOAK_LIVE_TEST=1 and
# KEYCLOAK_URL point at one; KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD are
# the bootstrap admin (default admin/admin). The test creates a realm with a
# random name, works only inside it, and deletes it at the end.

BEGIN {
  plan skip_all => 'set KEYCLOAK_LIVE_TEST=1 and KEYCLOAK_URL to run the Keycloak live test'
    unless $ENV{KEYCLOAK_LIVE_TEST} && $ENV{KEYCLOAK_URL};
}

use Crypt::JWT qw( decode_jwt );
use Digest::SHA qw( hmac_sha1 );
use WWW::Keycloak;

my $realm = 'wwwkc-live-'.join '', map { ( 'a' .. 'z' )[ rand 26 ] } 1 .. 8;
my $kc    = WWW::Keycloak->new(
  base_url => $ENV{KEYCLOAK_URL},
  realm    => $realm,
  username => $ENV{KEYCLOAK_ADMIN} // 'admin',
  password => $ENV{KEYCLOAK_ADMIN_PASSWORD} // 'admin'
);
my $admin = $kc->admin;
my $secret = '12345678901234567890';

# RFC 6238 with HMAC-SHA1, six digits
sub totp {
  my $step = int( time / 30 );
  my $mac  = hmac_sha1( pack( 'NN', int( $step / 4294967296 ), $step % 4294967296 ), $secret );
  my $off  = ord( substr $mac, -1 ) & 0x0f;
  return sprintf '%06d', ( unpack( 'N', substr $mac, $off, 4 ) & 0x7fffffff ) % 1_000_000;
}

sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': second run changes nothing' );
  is( $second->{id}, $first->{id}, $name.': same id' );
  return $first;
}

END { eval { $admin->delete_realm } if $admin }

subtest 'server' => sub {
  my $info = $admin->server_info;
  diag 'Keycloak '.$info->{systemInfo}{version};
  ok( grep( { $_->{id} eq 'oidc-amr-mapper' } @{ $info->{protocolMapperTypes}{'openid-connect'} } ), 'offers the AMR mapper' );
};

subtest 'a realm from nothing, twice' => sub {
  twice( realm => sub { $admin->ensure_realm( enabled => \1, displayName => 'WWW::Keycloak live test' ) } );
  is( $admin->ensure_realm( accessTokenLifespan => 600 )->{changed}, 'updated', 'a realm setting changed' );
  is( $admin->get_realm->{displayName}, 'WWW::Keycloak live test', 'the others kept' );

  twice( client => sub {
    $admin->ensure_client(
      clientId                  => 'live-cli',
      publicClient              => \1,
      standardFlowEnabled       => \0,
      directAccessGrantsEnabled => \1,
      attributes                => { 'oauth2.device.authorization.grant.enabled' => 'true' }
    );
  } );
  is( $admin->ensure_client( clientId => 'live-cli', description => 'changed' )->{changed}, 'updated', 'client changed' );
  is( $admin->find_client('live-cli')->{attributes}{'oauth2.device.authorization.grant.enabled'}, 'true', 'the attribute kept' );

  twice( mapper => sub {
    $admin->ensure_protocol_mapper( client => 'live-cli', name => 'amr', protocolMapper => 'oidc-amr-mapper',
      config => { 'id.token.claim' => 'true', 'access.token.claim' => 'true' } );
  } );
  twice( scope => sub { $admin->ensure_client_scope( name => 'live-scope', description => 'x' ) } );
  twice( user => sub {
    $admin->ensure_user(
      username      => 'Live-User',
      email         => 'Live@Example.org',
      firstName     => 'Live',
      lastName      => 'User',
      enabled       => \1,
      emailVerified => \1,
      credentials   => [
        { type => 'password', value => 'live-password', temporary => \0 },
        { type => 'otp', secretData => '{"value":"'.$secret.'"}',
          credentialData => '{"subType":"totp","digits":6,"counter":0,"period":30,"algorithm":"HmacSHA1"}' }
      ]
    );
  } );
  is_deeply( [ sort map { $_->{type} } @{ $admin->list_credentials( $admin->find_user('live-user')->{id} ) } ], [qw( otp password )], 'password and OTP set at creation' );

  $admin->ensure_user( username => 'live-user', attributes => { dept => 'x' } );
  my $user = $admin->find_user('live-user');
  is_deeply( [ @$user{qw( email firstName lastName )} ], [ 'live@example.org', 'Live', 'User' ], 'a write with attributes keeps the profile fields' );

  twice( 'unsorted redirect URIs' => sub {
    $admin->ensure_client( clientId => 'live-web', redirectUris => [ 'https://b.example/*', 'https://a.example/*', 'https://c.example/*' ] );
  } );

  for my $step ( [ 'direct grant', 'direct-grant-validate-password', 'pwd' ], [ 'direct grant', 'direct-grant-validate-otp', 'otp' ] ) {
    my %arg = ( flow => $step->[0], authenticator => $step->[1], config => { 'default.reference.value' => $step->[2], 'default.reference.maxAge' => 3600 } );
    is( $admin->ensure_execution_config(%arg)->{changed}, 'created', $step->[1].': created' );
    is( $admin->ensure_execution_config(%arg)->{changed}, 'updated', $step->[1].': written again, Keycloak hides the values' );
  }
};

subtest 'OIDC against the new realm' => sub {
  my $oidc   = $kc->oidc;
  my $tokens = $oidc->password_token( client_id => 'live-cli', username => 'live-user', password => 'live-password', totp => totp(), scope => 'openid' );
  ok( $tokens->{access_token}, 'a login with password and TOTP' );
  my $claims = $oidc->verify_token( $tokens->{id_token}, audience => 'live-cli' );
  is( $claims->{preferred_username}, 'live-user', 'verify_token' );
  is_deeply( $claims->{amr}, [qw( pwd otp )], 'amr reports both steps' );
  is( $oidc->userinfo( $tokens->{access_token} )->{preferred_username}, 'live-user', 'userinfo' );
  ok( $oidc->refresh_token( $tokens->{refresh_token}, client_id => 'live-cli' )->{access_token}, 'refresh_token' );

  my $wrong = eval { $oidc->password_token( client_id => 'live-cli', username => 'live-user', password => 'live-password' ); 1 } ? undef : $@;
  is( $wrong && $wrong->oauth_error, 'invalid_grant', 'without the TOTP code: invalid_grant' );

  my $start = $oidc->device_authorization( client_id => 'live-cli', scope => 'openid' );
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'device_authorization' );
  my $pending = eval { $oidc->device_token( device_code => $start->{device_code}, client_id => 'live-cli' ); 1 } ? undef : $@;
  is( $pending && $pending->oauth_error, 'authorization_pending', 'device_token before approval' );

  ok( $oidc->logout( refresh_token => $tokens->{refresh_token}, client_id => 'live-cli' ), 'logout' );
  my $after = eval { $oidc->refresh_token( $tokens->{refresh_token}, client_id => 'live-cli' ); 1 } ? undef : $@;
  is( $after && $after->oauth_error, 'invalid_grant', 'the refresh token is dead after logout' );
};

subtest 'clean up' => sub {
  ok( $admin->delete_realm, 'realm deleted' );
  my $gone = eval { $admin->get_realm; 1 } ? undef : $@;
  ok( $gone && $gone->is_not_found, 'and gone' );
  undef $admin;
};

done_testing;
