#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use WWW::Keycloak;

my $fake = FakeKeycloak->new;
my $kc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake );
my $admin = $kc->admin;

subtest 'realm' => sub {
  is( $admin->create_realm( { displayName => 'Main' } ), 'main', 'create_realm returns the realm name' );
  is( $admin->get_realm->{displayName}, 'Main', 'get_realm' );
  ok( $admin->update_realm( { accessTokenLifespan => 600 } ), 'update_realm' );
  is( $admin->get_realm->{accessTokenLifespan}, 600, 'updated' );
  is( $admin->get_realm->{displayName}, 'Main', 'the rest untouched' );
  is( $admin->server_info->{systemInfo}{version}, '26.8.0', 'server_info from the server root' );
  my $request = $fake->requests->[-1];
  is( $request->uri->path, '/admin/serverinfo', 'which is not under the realm' );
  is( $request->header('Authorization'), 'Bearer '.$kc->auth->token, 'with the admin token' );
  is( $admin->partial_import( { users => [ { username => 'Imported' } ] }, if_exists => 'SKIP' )->{added}, 1, 'partial_import' );
};

subtest 'clients' => sub {
  my $id = $admin->create_client( { clientId => 'cli', publicClient => \1 } );
  like( $id, qr/\Aid-\d+\z/, 'create_client returns the id from the Location header' );
  is( $admin->get_client($id)->{clientId}, 'cli', 'get_client' );
  is( $admin->find_client('cli')->{id}, $id, 'find_client by clientId' );
  is( $admin->find_client('nope'), undef, 'find_client without a match' );
  my $client = $admin->get_client($id);
  ok( $admin->update_client( $id, { %$client, description => 'd' } ), 'update_client' );
  is( $admin->get_client($id)->{description}, 'd', 'updated' );
  is( scalar @{ $admin->list_clients }, 1, 'list_clients' );
  is( $admin->get_client_secret($id)->{type}, 'secret', 'get_client_secret' );
  is( $admin->get_service_account_user($id)->{username}, 'service-account-cli', 'get_service_account_user' );
  ok( !eval { $admin->create_client( { clientId => 'cli' } ); 1 }, 'a second create croaks' );
  ok( $@->is_conflict, 'with a conflict' );
  ok( $admin->delete_client($id), 'delete_client' );
  ok( !eval { $admin->get_client($id); 1 } && $@->is_not_found, 'gone' );
};

subtest 'client scopes and protocol mappers' => sub {
  my $client = $admin->create_client( { clientId => 'mapped' } );
  my $scope  = $admin->create_client_scope( { name => 'amr', protocol => 'openid-connect' } );
  is( $admin->find_client_scope('amr')->{id}, $scope, 'find_client_scope by name' );
  my $mapper = $admin->create_protocol_mapper( client => $client, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => {} } );
  ok( $mapper, 'create_protocol_mapper on a client' );
  is( $admin->list_protocol_mappers( client => $client )->[0]{name}, 'amr', 'list_protocol_mappers' );
  ok( $admin->update_protocol_mapper( client => $client, $mapper, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { a => 'b' } } ), 'update_protocol_mapper' );
  is( $admin->list_protocol_mappers( client => $client )->[0]{config}{a}, 'b', 'updated' );
  ok( $admin->create_protocol_mapper( client_scope => $scope, { name => 'amr', protocolMapper => 'oidc-amr-mapper' } ), 'on a client scope' );
  like( $fake->requests->[-1]->uri->path, qr{/client-scopes/\Q$scope\E/protocol-mappers/models\z}, 'at the scope' );
  ok( $admin->delete_protocol_mapper( client => $client, $mapper ), 'delete_protocol_mapper' );
  ok( !eval { $admin->list_protocol_mappers( group => 'x' ); 1 }, 'an owner that is neither client nor scope' );
  isa_ok( $@, 'WWW::Keycloak::Error::Validation' );
  ok( $admin->add_default_client_scope( $client, $scope ), 'add_default_client_scope' );
  ok( $admin->add_realm_default_client_scope($scope), 'add_realm_default_client_scope' );
};

subtest 'users' => sub {
  my $id = $admin->create_user( { username => 'Alice', enabled => \1, credentials => [ { type => 'password', value => 'pw', temporary => \0 } ] } );
  is( $admin->find_user('alice')->{id}, $id, 'find_user' );
  is( $admin->find_user('ALICE')->{id}, $id, 'in any case' );
  is( $admin->find_user('alic'), undef, 'exactly' );
  is_deeply( [ map { $_->{type} } @{ $admin->list_credentials($id) } ], ['password'], 'list_credentials' );
  ok( $admin->set_password( $id, 'new', temporary => 1 ), 'set_password' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{$id}{credentials} };
  is_deeply( [ @$password{qw( value type )}, ${ $password->{temporary} } ], [ 'new', 'password', 1 ], 'with type and temporary flag' );
  ok( $admin->update_user( $id, { firstName => 'A' } ), 'update_user' );
  is( $admin->get_user($id)->{firstName}, 'A', 'updated' );
  is_deeply( $admin->list_sessions($id), [], 'list_sessions' );
  ok( $admin->logout_user($id), 'logout_user' );
  ok( $admin->delete_credential( $id, $admin->list_credentials($id)->[0]{id} ), 'delete_credential' );
  ok( $admin->delete_user($id), 'delete_user' );
};

subtest 'authentication' => sub {
  is_deeply( [ map { $_->{alias} } @{ $admin->list_flows } ], [ 'browser', 'direct grant' ], 'list_flows' );
  my ( $otp ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $admin->list_executions('browser') };
  ok( $otp, 'list_executions' );
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/browser/executions\z}, 'by alias' );
  $admin->list_executions('direct grant');
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/direct%20grant/executions\z}, 'an alias with a space is escaped' );
  my $config = $admin->create_execution_config( $otp->{id}, { alias => 'x', config => { 'default.reference.value' => 'otp' } } );
  ok( $config, 'create_execution_config' );
  is( $admin->get_execution_config($config)->{config}{'default.reference.value'}, '**********', 'get_execution_config: masked, as Keycloak does' );
  ok( $admin->update_execution_config( $config, { alias => 'x', config => { 'default.reference.value' => 'mfa' } } ), 'update_execution_config' );
  is( $fake->realm('main')->{configs}{$config}{config}{'default.reference.value'}, 'mfa', 'updated' );
  is( $fake->realm('main')->{configs}{$config}{id}, $config, 'with its id' );
  ok( $admin->copy_flow( 'browser', 'browser-copy' ), 'copy_flow' );
  is_deeply( $admin->describe_authenticator('auth-otp-form'), { properties => [] }, 'describe_authenticator' );
};

subtest 'call reaches what has no method' => sub {
  my $result = $admin->call( GET => '/clients?first=0&max=1' );
  is( $result->{status}, 200, 'status' );
  is( ref $result->{data}, 'ARRAY', 'data' );
};

subtest 'a refused token is renewed once' => sub {
  $admin->get_realm;
  @{ $fake->logins } = ();
  $fake->forget_tokens;
  ok( $admin->get_realm, 'the call after a Keycloak restart succeeds' );
  is( scalar @{ $fake->logins }, 1, 'after one new login' );

  my $fixed = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', token => 'stale', ua => $fake );
  ok( !eval { $fixed->admin->get_realm; 1 }, 'a fixed token that is refused croaks' );
  ok( $@->is_unauthorized, 'with 401' );

  my $always = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', ua => $fake );
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) };
  @{ $fake->logins } = ();
  ok( !eval { $always->admin->get_realm; 1 }, 'a token refused twice croaks' );
  is( scalar @{ $fake->logins }, 2, 'after exactly one retry' );
};

subtest 'a failed login is not retried as a refused token' => sub {
  my $bad = WWW::Keycloak->new( base_url => $fake->base, realm => 'main', client_id => 'svc', client_secret => 'wrong', ua => $fake );
  @{ $fake->logins } = ();
  ok( !eval { $bad->admin->get_realm; 1 }, 'a wrong client secret croaks' );
  like( "$@", qr/admin login failed: 401/, 'as a failed login' );
  is( scalar @{ $fake->logins }, 1, 'and the secret went to Keycloak once, not twice' );
};

subtest 'no Location header' => sub {
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply(201) };
  ok( !eval { $admin->create_client( { clientId => 'x' } ); 1 }, 'croaks instead of returning nothing' );
  like( "$@", qr/sent no Location header/, 'and says why' );
};

done_testing;
