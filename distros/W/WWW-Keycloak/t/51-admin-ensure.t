#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake  = FakeKeycloak->new;
my $admin = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake )->admin;

sub writes {
  my ( $code ) = @_;
  my $before = @{ $fake->requests };
  my $result = $code->();
  return ( $result, scalar grep { $_->method ne 'GET' && $_->uri->path !~ m{/token\z} } @{ $fake->requests }[ $before .. $#{ $fake->requests } ] );
}

subtest 'ensure_realm' => sub {
  my ( $r, $w ) = writes( sub { $admin->ensure_realm( enabled => \1, displayName => 'Main' ) } );
  is_deeply( $r, { id => 'main', changed => 'created' }, 'created' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm( enabled => \1, displayName => 'Main' ) } );
  is( $r->{changed}, '', 'second run: nothing to do' );
  is( $w, 0, 'and nothing written' );
  ( $r, $w ) = writes( sub { $admin->ensure_realm( displayName => 'Main realm' ) } );
  is( $r->{changed}, 'updated', 'a change' );
  is( $w, 1, 'one write' );
  is( $fake->realm('main')->{rep}{enabled}, JSON::MaybeXS::true, 'other keys untouched' );
};

subtest 'ensure_client' => sub {
  my %want = ( clientId => 'cli', publicClient => \1, attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } );
  my $r = $admin->ensure_client(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_client(%want) } );
  is_deeply( $again, { id => $r->{id}, changed => '' }, 'second run: same id, nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $changed ) = writes( sub { $admin->ensure_client( clientId => 'cli', attributes => { 'pkce.code.challenge.method' => 'S256' } ) } );
  is( $changed->{changed}, 'updated', 'an attribute added' );
  is_deeply(
    $fake->realm('main')->{clients}{ $r->{id} }{attributes},
    { 'oauth2.device.authorization.grant.enabled' => 'true', 'pkce.code.challenge.method' => 'S256' },
    'the other attribute kept'
  );
  ok( ${ $fake->realm('main')->{clients}{ $r->{id} }{publicClient} }, 'and the other keys too: the whole client was sent' );
  ok( !eval { $admin->ensure_client( publicClient => \1 ); 1 }, 'without clientId' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
};

subtest 'ensure_client_scope and ensure_protocol_mapper' => sub {
  is( $admin->ensure_client_scope( name => 'amr' )->{changed}, 'created', 'scope created' );
  is( $fake->realm('main')->{scopes}{ $admin->find_client_scope('amr')->{id} }{protocol}, 'openid-connect', 'protocol defaults to openid-connect' );
  is( $admin->ensure_client_scope( name => 'amr' )->{changed}, '', 'scope: nothing to do' );
  is( $admin->ensure_client_scope( name => 'amr', description => 'd' )->{changed}, 'updated', 'scope updated' );

  my %mapper = ( name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { 'id.token.claim' => 'true' } );
  is( $admin->ensure_protocol_mapper( client => 'cli', %mapper )->{changed}, 'created', 'mapper on a client, named by clientId' );
  is( $admin->ensure_protocol_mapper( client => 'cli', %mapper )->{changed}, '', 'nothing to do' );
  is( $admin->ensure_protocol_mapper( client => 'cli', name => 'amr', config => { 'access.token.claim' => 'true' } )->{changed}, 'updated', 'a config key added' );
  my ( $stored ) = values %{ $fake->realm('main')->{mappers}{ 'clients/'.$admin->find_client('cli')->{id} } };
  is_deeply( $stored->{config}, { 'id.token.claim' => 'true', 'access.token.claim' => 'true' }, 'merged' );
  is( $admin->ensure_protocol_mapper( client_scope => 'amr', %mapper )->{changed}, 'created', 'mapper on a scope, named by name' );
  ok( !eval { $admin->ensure_protocol_mapper( client => 'nope', %mapper ); 1 }, 'an unknown owner' );
  like( "$@", qr/no client nope/, 'is named' );
  ok( !eval { $admin->ensure_protocol_mapper( client => 'cli', protocolMapper => 'x' ); 1 }, 'without name' );
};

subtest 'ensure_user' => sub {
  my %want = ( username => 'Alice', email => 'Alice@Example.org', enabled => \1, credentials => [ { type => 'password', value => 'first', temporary => \0 } ] );
  my $r = $admin->ensure_user(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $again, $w ) = writes( sub { $admin->ensure_user( %want, credentials => [ { type => 'password', value => 'second' } ] ) } );
  is( $again->{changed}, '', 'second run, with other credentials and mixed case: nothing to do' );
  is( $w, 0, 'nothing written' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{ $r->{id} }{credentials} };
  is( $password->{value}, 'first', 'the password was not reset' );
  is( $admin->ensure_user( username => 'alice', firstName => 'Alice' )->{changed}, 'updated', 'a change' );
  is( $fake->realm('main')->{users}{ $r->{id} }{email}, 'alice@example.org', 'the rest kept' );
};

subtest 'ensure_execution_config' => sub {
  my %want = ( flow => 'browser', authenticator => 'auth-otp-form', config => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 } );
  my $r = $admin->ensure_execution_config(%want);
  is( $r->{changed}, 'created', 'created' );
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $fake->realm('main')->{flows}{browser} };
  is( $execution->{authenticationConfig}, $r->{id}, 'attached to the step' );
  is( $fake->realm('main')->{configs}{ $r->{id} }{alias}, 'browser auth-otp-form', 'default alias' );
  my $again = $admin->ensure_execution_config(%want);
  is_deeply( $again, { id => $r->{id}, changed => 'updated' }, 'Keycloak hides the values, so a second run writes again' );
  $admin->ensure_execution_config( %want, config => { 'default.reference.value' => 'otp' } );
  is_deeply( $fake->realm('main')->{configs}{ $r->{id} }{config}, { 'default.reference.value' => 'otp' }, 'replaced as given, never merged with masked values' );
  ok( !grep( { /\*{10}/ } values %{ $fake->realm('main')->{configs}{ $r->{id} }{config} } ), 'no masked value was written back' );
  is( $admin->ensure_execution_config( %want, flow => 'direct grant', authenticator => 'direct-grant-validate-otp', alias => 'mine' )->{changed}, 'created', 'in a flow with a space' );
  ok( !eval { $admin->ensure_execution_config( %want, authenticator => 'nope' ); 1 }, 'an unknown step' );
  like( "$@", qr/flow "browser" has no step nope/, 'is named' );
  ok( !eval { $admin->ensure_execution_config( flow => 'browser', authenticator => 'auth-otp-form' ); 1 }, 'without config' );
};

subtest 'what the review found against the real Keycloak' => sub {
  my $user = $admin->ensure_user( username => 'bob', email => 'bob@example.org', firstName => 'Bob', lastName => 'B', enabled => \1 );
  is( $admin->ensure_user( username => 'bob', attributes => { dept => 'x' } )->{changed}, 'updated', 'an attribute added' );
  my $stored = $fake->realm('main')->{users}{ $user->{id} };
  is_deeply( [ @$stored{qw( email firstName lastName )} ], [ 'bob@example.org', 'Bob', 'B' ], 'the profile fields survive a PUT with attributes' );
  is_deeply( $stored->{attributes}, { dept => ['x'] }, 'stored as a list' );
  is( $admin->ensure_user( username => 'bob', attributes => { dept => 'x' } )->{changed}, '', 'a single value given as a string converges' );
  is( $admin->ensure_user( username => 'bob', attributes => { dept => ['x'] } )->{changed}, '', 'and as a list' );

  my %uris = ( clientId => 'web', redirectUris => [ 'https://b/*', 'https://a/*', 'https://c/*' ], webOrigins => [ 'https://b', 'https://a' ] );
  is( $admin->ensure_client(%uris)->{changed}, 'created', 'a client with unsorted URI lists' );
  is( $admin->ensure_client(%uris)->{changed}, '', 'converges although Keycloak sorts them' );

  for my $ignored (qw( defaultClientScopes optionalClientScopes protocolMappers )) {
    ok( !eval { $admin->ensure_client( clientId => 'web', $ignored => [] ); 1 }, $ignored.' is refused' );
    like( "$@", qr/Keycloak ignores it when a client is updated/, 'with the reason' );
  }
};

done_testing;
