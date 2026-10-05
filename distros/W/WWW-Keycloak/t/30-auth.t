#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak::Auth;

my $clock = 1_000_000;
my $fake  = FakeKeycloak->new( expires_in => 60 );

sub auth {
  return WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', now => sub { $clock }, @_ );
}

subtest 'password login, kept, renewed' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token;
  like( $first, qr/\Aat-/, 'a token' );
  is( $fake->logins->[0]{grant_type}, 'password', 'by password grant' );
  is( $fake->logins->[0]{client_id}, 'admin-cli', 'through admin-cli' );
  $clock += 29;
  is( $auth->token, $first, 'kept while more than the margin is left' );
  is( scalar @{ $fake->logins }, 1, 'without asking again' );
  $clock += 1;
  my $second = $auth->token;
  isnt( $second, $first, 'renewed 30 seconds before expiry' );
  is( $fake->logins->[1]{grant_type}, 'refresh_token', 'with the refresh token' );
};

subtest 'refresh refused: log in again' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( username => 'admin', password => 'admin' );
  $auth->token;
  $fake->forget_tokens;
  $clock += 60;
  ok( $auth->token, 'still a token' );
  is_deeply( [ map { $_->{grant_type} } @{ $fake->logins } ], [qw( password refresh_token password )], 'refresh failed, password login followed' );
};

subtest 'invalidate' => sub {
  @{ $fake->logins } = ();
  my $auth  = auth( username => 'admin', password => 'admin' );
  my $first = $auth->token;
  $auth->invalidate;
  isnt( $auth->token, $first, 'a new token after invalidate' );
  is( $fake->logins->[1]{grant_type}, 'password', 'by logging in, not by refresh' );
};

subtest 'service account' => sub {
  @{ $fake->logins } = ();
  my $auth = auth( client_id => 'provisioner', client_secret => 'secret' );
  ok( $auth->token, 'token' );
  is_deeply( [ @{ $fake->logins->[0] }{qw( grant_type client_id client_secret )} ], [qw( client_credentials provisioner secret )], 'client credentials grant' );
};

subtest 'fixed token' => sub {
  my $auth = WWW::Keycloak::Auth->new( ua => $fake, token => 'fixed' );
  is( $auth->token, 'fixed', 'used as it is' );
  is( $auth->renewable, 0, 'and not renewable' );
};

subtest 'refusals' => sub {
  my $wrong = auth( username => 'admin', password => 'guess' );
  ok( !eval { $wrong->token; 1 }, 'wrong password croaks' );
  isa_ok( $@, 'WWW::Keycloak::Error::API' );
  like( "$@", qr/\Aadmin login failed: 400 - invalid_grant/, 'and says so (Keycloak answers a wrong password with 400)' );
  unlike( "$@", qr/guess/, 'without the password' );

  ok( !eval { auth( client_id => 'x', client_secret => 'leaked-secret' )->token; 1 }, 'wrong secret croaks' );
  unlike( "$@", qr/leaked-secret/, 'without the secret' );

  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => 'x' ); 1 }, 'no credentials' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, username => 'a', password => 'b' ); 1 }, 'no token endpoint' );
  ok( !eval { WWW::Keycloak::Auth->new( ua => $fake, token_endpoint => 'x', username => 'a' ); 1 }, 'username without password' );
};

done_testing;
