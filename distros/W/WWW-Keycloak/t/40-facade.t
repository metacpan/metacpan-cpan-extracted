#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;

subtest 'construction' => sub {
  my $kc = WWW::Keycloak->new( base_url => 'https://id.example.org//', realm => 'main' );
  is( $kc->base_url, 'https://id.example.org', 'trailing slashes go' );
  is( $kc->issuer, 'https://id.example.org/realms/main', 'issuer' );
  isa_ok( $kc->ua, 'LWP::UserAgent' );
  is( $kc->auth, undef, 'no admin login without credentials' );
  isa_ok( $kc->oidc, 'WWW::Keycloak::OIDC' );
  is( $kc->oidc->issuer, $kc->issuer, 'oidc knows the issuer' );
  isa_ok( $kc->admin, 'WWW::Keycloak::Admin' );
  ok( !eval { $kc->admin->get_realm; 1 }, 'the Admin API without credentials' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  like( "$@", qr/needs credentials/, 'says what is missing' );

  for my $bad ( [ realm => 'x' ], [ base_url => 'x' ], [ base_url => '', realm => 'x' ], [ base_url => 'x', realm => '' ] ) {
    ok( !eval { WWW::Keycloak->new(@$bad); 1 }, 'refused: '.join( ' ', map { $_ // 'undef' } @$bad ) );
  }
};

subtest 'admin login options' => sub {
  my $pw = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'admin', password => 'pw' );
  is( $pw->auth_realm, 'master', 'a password login goes to master' );
  is( $pw->auth->token_endpoint, 'http://kc/realms/master/protocol/openid-connect/token', 'its token endpoint' );
  my $svc = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', client_id => 'svc', client_secret => 's' );
  is( $svc->auth_realm, 'main', 'a service account logs in to its own realm' );
  my $other = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', username => 'a', password => 'b', auth_realm => 'admins' );
  like( $other->auth->token_endpoint, qr{/realms/admins/}, 'auth_realm can be set' );
  my $fixed = WWW::Keycloak->new( base_url => 'http://kc', realm => 'main', token => 't' );
  is( $fixed->auth->token, 't', 'a fixed token' );
};

subtest 'for_realm' => sub {
  my $kc  = WWW::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', ua => $fake );
  my $dev = $kc->for_realm('dev');
  is( $dev->realm, 'dev', 'other realm' );
  is( $dev->issuer, $fake->base.'/realms/dev', 'its issuer' );
  is( $dev->ua, $kc->ua, 'same user agent' );
  is( $dev->auth, $kc->auth, 'same admin login' );
  is( $dev->auth_realm, 'master', 'still logging in to master' );
  $dev->admin->create_realm( { displayName => 'Dev' } );
  is( $fake->realm('dev')->{rep}{displayName}, 'Dev', 'and it works on the other realm' );
  @{ $fake->logins } = ();
  $kc->admin->get_realm;
  $dev->admin->get_realm;
  is( scalar @{ $fake->logins }, 0, 'without logging in again' );
};

done_testing;
