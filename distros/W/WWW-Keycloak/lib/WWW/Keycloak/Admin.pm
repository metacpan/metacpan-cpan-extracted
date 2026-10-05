package WWW::Keycloak::Admin;

# ABSTRACT: Keycloak Admin REST API for one realm, with idempotent ensure methods

use Moo;
with 'WWW::Keycloak::Role::HTTP';
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Keycloak::Diff;
use WWW::Keycloak::Error;
use WWW::Keycloak::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has realm => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);


has auth => (
  is        => 'ro',
  isa       => InstanceOf['WWW::Keycloak::Auth'],
  predicate => 'has_auth'
);


sub diff_class { 'WWW::Keycloak::Diff' }

####  transport

sub realm_url { $_[0]->base_url.'/admin/realms/'.uri_escape_utf8( $_[0]->realm ) }

sub call {
  my ( $self, $method, $path, $body ) = @_;
  my $url = $path =~ m{\A/admin/} ? $self->base_url.$path : $self->realm_url.$path;
  WWW::Keycloak::Error::Validation->throw( message => 'the Admin API needs credentials: give username and password, client_id and client_secret, or token' )
    unless $self->has_auth;
  my %arg    = defined $body ? ( json => $body ) : ();
  my $bearer = $self->auth->token;   # outside the eval: a failed login is not a refused token
  my $result = eval { $self->send_request( $method, $url, %arg, bearer => $bearer ) };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_unauthorized && $self->auth->renewable;
    $self->auth->invalidate;
    $result = $self->send_request( $method, $url, %arg, bearer => $self->auth->token );
  }
  return $result;
}


sub _data   { $_[0]->call( @_[ 1 .. $#_ ] )->{data} }
sub _done   { $_[0]->call( @_[ 1 .. $#_ ] ); 1 }
sub _create {
  my ( $self, $path, $body ) = @_;
  my $location = $self->call( POST => $path, $body )->{location} // '';
  my ( $id ) = $location =~ m{/([^/]+)\z};
  WWW::Keycloak::Error->throw( message => 'POST '.$path.' created something but sent no Location header' ) unless defined $id;
  return $id;
}
sub _esc { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) } sort keys %query;
}

sub _missing {
  my ( $self, $error ) = @_;
  return 1 if blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_not_found;
  die $error;
}

####  server and realm

sub server_info { $_[0]->_data( GET => '/admin/serverinfo' ) }

sub get_realm    { $_[0]->_data( GET => '' ) }
sub update_realm { $_[0]->_done( PUT => '', $_[1] ) }
sub delete_realm { $_[0]->_done( DELETE => '' ) }

sub create_realm {
  my ( $self, $rep ) = @_;
  $self->call( POST => '/admin/realms', { realm => $self->realm, %{ $rep || {} } } );
  return $self->realm;
}

sub export_realm {
  my ( $self, %opt ) = @_;
  return $self->_data( POST => '/partial-export'.$self->_query(
    exportClients        => $opt{clients} ? 'true' : 'false',
    exportGroupsAndRoles => $opt{groups_and_roles} ? 'true' : 'false'
  ) );
}

sub partial_import {
  my ( $self, $rep, %opt ) = @_;
  return $self->_data( POST => '/partialImport', { ifResourceExists => $opt{if_exists} // 'FAIL', %$rep } );
}


####  clients

sub list_clients  { my ( $self, %q ) = @_; $self->_data( GET => '/clients'.$self->_query(%q) ) }
sub get_client    { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ) ) }
sub create_client { $_[0]->_create( '/clients', $_[1] ) }
sub update_client { $_[0]->_done( PUT => '/clients/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client { $_[0]->_done( DELETE => '/clients/'.$_[0]->_esc( $_[1] ) ) }

sub find_client {
  my ( $self, $client_id ) = @_;
  my ( $client ) = grep { $_->{clientId} eq $client_id } @{ $self->list_clients( clientId => $client_id ) };
  return $client;
}

sub get_client_secret        { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub regenerate_client_secret { $_[0]->_data( POST => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub get_service_account_user { $_[0]->_data( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/service-account-user' ) }


####  client scopes

sub list_client_scopes  { $_[0]->_data( GET => '/client-scopes' ) }
sub get_client_scope    { $_[0]->_data( GET => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_scope { $_[0]->_create( '/client-scopes', $_[1] ) }
sub update_client_scope { $_[0]->_done( PUT => '/client-scopes/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_scope { $_[0]->_done( DELETE => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }

sub find_client_scope {
  my ( $self, $name ) = @_;
  my ( $scope ) = grep { $_->{name} eq $name } @{ $self->list_client_scopes };
  return $scope;
}

sub add_default_client_scope {
  my ( $self, $client, $scope ) = @_;
  return $self->_done( PUT => '/clients/'.$self->_esc($client).'/default-client-scopes/'.$self->_esc($scope) );
}

sub add_realm_default_client_scope { $_[0]->_done( PUT => '/default-default-client-scopes/'.$_[0]->_esc( $_[1] ) ) }


####  protocol mappers

sub _mapper_path {
  my ( $self, $kind, $owner ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'protocol mappers belong to a client or a client_scope, not to '.( $kind // 'nothing' ) )
    unless defined $kind && ( $kind eq 'client' || $kind eq 'client_scope' );
  return ( $kind eq 'client' ? '/clients/' : '/client-scopes/' ).$self->_esc($owner).'/protocol-mappers/models';
}

sub list_protocol_mappers  { my ( $self, $kind, $owner ) = @_; $self->_data( GET => $self->_mapper_path( $kind, $owner ) ) }
sub create_protocol_mapper { my ( $self, $kind, $owner, $rep ) = @_; $self->_create( $self->_mapper_path( $kind, $owner ), $rep ) }

sub update_protocol_mapper {
  my ( $self, $kind, $owner, $id, $rep ) = @_;
  return $self->_done( PUT => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id), $rep );
}

sub delete_protocol_mapper {
  my ( $self, $kind, $owner, $id ) = @_;
  return $self->_done( DELETE => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id) );
}


####  users

sub list_users  { my ( $self, %q ) = @_; $self->_data( GET => '/users'.$self->_query(%q) ) }
sub get_user    { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ) ) }
sub create_user { $_[0]->_create( '/users', $_[1] ) }
sub update_user { $_[0]->_done( PUT => '/users/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_user { $_[0]->_done( DELETE => '/users/'.$_[0]->_esc( $_[1] ) ) }

sub find_user {
  my ( $self, $username ) = @_;
  my ( $user ) = grep { lc $_->{username} eq lc $username } @{ $self->list_users( username => $username, exact => 'true' ) };
  return $user;
}

sub set_password {
  my ( $self, $id, $password, %opt ) = @_;
  return $self->_done( PUT => '/users/'.$self->_esc($id).'/reset-password',
    { type => 'password', value => $password, temporary => $opt{temporary} ? \1 : \0 } );
}

sub list_credentials  { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ).'/credentials' ) }
sub delete_credential { $_[0]->_done( DELETE => '/users/'.$_[0]->_esc( $_[1] ).'/credentials/'.$_[0]->_esc( $_[2] ) ) }
sub list_sessions     { $_[0]->_data( GET => '/users/'.$_[0]->_esc( $_[1] ).'/sessions' ) }
sub logout_user       { $_[0]->_done( POST => '/users/'.$_[0]->_esc( $_[1] ).'/logout' ) }


####  authentication

sub list_flows       { $_[0]->_data( GET => '/authentication/flows' ) }
sub list_executions  { $_[0]->_data( GET => '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/executions' ) }
sub copy_flow        { $_[0]->_create( '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/copy', { newName => $_[2] } ) }
sub get_execution_config    { $_[0]->_data( GET => '/authentication/config/'.$_[0]->_esc( $_[1] ) ) }
sub create_execution_config { $_[0]->_create( '/authentication/executions/'.$_[0]->_esc( $_[1] ).'/config', $_[2] ) }
sub update_execution_config { $_[0]->_done( PUT => '/authentication/config/'.$_[0]->_esc( $_[1] ), { %{ $_[2] }, id => $_[1] } ) }
sub describe_authenticator  { $_[0]->_data( GET => '/authentication/config-description/'.$_[0]->_esc( $_[1] ) ) }


####  ensure

sub _ensure {
  my ( $self, %arg ) = @_;
  my $current = $arg{find}->();
  return { id => $arg{create}->(), changed => 'created' } unless $current;
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { id => $arg{id}->($current), changed => '' } unless %$changes;
  $arg{update}->( $current, $changes );
  return { id => $arg{id}->($current), changed => 'updated' };
}

sub ensure_realm {
  my ( $self, %rep ) = @_;
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { my $realm = eval { $self->get_realm }; $self->_missing($@) unless $realm; $realm },
    create => sub { $self->create_realm( \%rep ) },
    update => sub { $self->update_realm( $_[1] ) },
    id     => sub { $_[0]->{realm} }
  );
}


sub ensure_client {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_client needs a clientId' ) unless defined $rep{clientId};
  for my $ignored (qw( defaultClientScopes optionalClientScopes protocolMappers )) {
    WWW::Keycloak::Error::Validation->throw( message => 'ensure_client cannot set '.$ignored
      .': Keycloak ignores it when a client is updated; use add_default_client_scope or ensure_protocol_mapper' )
      if exists $rep{$ignored};
  }
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { $self->find_client( $rep{clientId} ) },
    create => sub { $self->create_client( \%rep ) },
    update => sub { $self->update_client( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}


sub ensure_client_scope {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_client_scope needs a name' ) unless defined $rep{name};
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { $self->find_client_scope( $rep{name} ) },
    create => sub { $self->create_client_scope( { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_client_scope( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}


sub ensure_protocol_mapper {
  my ( $self, $kind, $owner_key, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_protocol_mapper needs a name' ) unless defined $rep{name};
  my $owner = $kind && $kind eq 'client' ? $self->find_client($owner_key)
    : $kind && $kind eq 'client_scope' ? $self->find_client_scope($owner_key)
    : $self->_mapper_path($kind);
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_protocol_mapper: no '.$kind.' '.$owner_key ) unless $owner;
  return $self->_ensure(
    wanted => \%rep,
    find   => sub { ( grep { $_->{name} eq $rep{name} } @{ $self->list_protocol_mappers( $kind, $owner->{id} ) } )[0] },
    create => sub { $self->create_protocol_mapper( $kind, $owner->{id}, { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_protocol_mapper( $kind, $owner->{id}, $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}


sub ensure_user {
  my ( $self, %rep ) = @_;
  WWW::Keycloak::Error::Validation->throw( message => 'ensure_user needs a username' ) unless defined $rep{username};
  # Keycloak keeps user names and e-mail addresses in lower case
  my %compare = %rep;
  delete $compare{credentials};
  $compare{$_} = lc $compare{$_} for grep { defined $compare{$_} } qw( username email );
  # Keycloak keeps every user attribute as a list of strings
  $compare{attributes} = { map { $_ => ref $rep{attributes}{$_} eq 'ARRAY' ? $rep{attributes}{$_} : [ $rep{attributes}{$_} ] } keys %{ $rep{attributes} } }
    if ref $rep{attributes} eq 'HASH';
  return $self->_ensure(
    wanted => \%compare,
    find   => sub { $self->find_user( $rep{username} ) },
    create => sub { $self->create_user( \%rep ) },
    # the whole user: Keycloak's user profile drops fields a PUT with attributes does not name
    update => sub { $self->update_user( $_[0]{id}, $self->diff_class->merge( $_[0], $_[1] ) ) },
    id     => sub { $_[0]->{id} }
  );
}


sub ensure_execution_config {
  my ( $self, %arg ) = @_;
  for (qw( flow authenticator config )) {
    WWW::Keycloak::Error::Validation->throw( message => 'ensure_execution_config needs '.$_ ) unless defined $arg{$_};
  }
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq $arg{authenticator} } @{ $self->list_executions( $arg{flow} ) };
  WWW::Keycloak::Error::Validation->throw( message => 'flow "'.$arg{flow}.'" has no step '.$arg{authenticator} ) unless $execution;
  my $alias = $arg{alias} // $arg{flow}.' '.$arg{authenticator};
  return $self->_ensure(
    wanted => { config => $arg{config} },
    find   => sub { $execution->{authenticationConfig} ? $self->get_execution_config( $execution->{authenticationConfig} ) : undef },
    create => sub { $self->create_execution_config( $execution->{id}, { alias => $alias, config => $arg{config} } ) },
    update => sub { $self->update_execution_config( $_[0]{id}, { alias => $_[0]{alias}, config => $arg{config} } ) },
    id     => sub { $_[0]->{id} }
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Keycloak::Admin - Keycloak Admin REST API for one realm, with idempotent ensure methods

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $admin = WWW::Keycloak->new( base_url => $url, realm => 'main', username => 'admin', password => $pw )->admin;

    # one call, one endpoint
    my $client = $admin->find_client('my-cli');
    my $id     = $admin->create_user( { username => 'alice', enabled => \1 } );

    # wanted state, as often as you like
    my $r = $admin->ensure_client( clientId => 'my-cli', publicClient => \1 );
    print $r->{changed};   # 'created', 'updated' or ''

=head1 DESCRIPTION

The Admin REST API of the realm the L<WWW::Keycloak> facade was made for.

The basic methods are one endpoint each. C<get_*> and C<find_*> return the
representation as a hash (C<find_*> returns nothing when there is no match),
C<list_*> an array reference, C<create_*> the id of the new object, which
Keycloak sends in the C<Location> header, and C<update_*> and C<delete_*> true.
Every failure is a L<WWW::Keycloak::Error::API>; C<is_not_found> and
C<is_conflict> tell the common cases apart.

The C<ensure_*> methods are what makes a setup repeatable. Each looks the
object up by its readable key, creates it when it is missing, otherwise writes
only what differs, and returns C<< { id => ..., changed => 'created' | 'updated' | '' } >>.
Only the keys given are compared; nothing is ever deleted.

When Keycloak refuses the token (HTTP 401), the request is repeated once with
a fresh one.

=head2 base_url

Required. The Keycloak URL without C</realms/...>.

=head2 realm

Required. The realm every method works on.

=head2 ua

Required. The L<LWP::UserAgent> to use.

=head2 auth

The L<WWW::Keycloak::Auth> that supplies the admin token. Without it every
call throws a validation error.

=head2 call

    my $result = $admin->call( GET => '/clients?clientId=x' );
    my $result = $admin->call( POST => '/admin/realms', { realm => 'new' } );

One request against the Admin API. A path starting with C</admin/> is taken
from the server root, anything else from the realm. Returns what
L<WWW::Keycloak::Role::HTTP/send_request> returns. The way to reach an
endpoint this class has no method for.

=head2 server_info

=head2 get_realm

=head2 create_realm

    $admin->create_realm( { enabled => \1 } );   # the realm of this object

=head2 update_realm

    $admin->update_realm( { accessTokenLifespan => 600 } );

Keycloak takes a partial representation here and leaves the rest alone.

=head2 delete_realm

=head2 export_realm

    my $rep = $admin->export_realm( clients => 1, groups_and_roles => 0 );

Keycloak masks secrets and authenticator settings in the export.

=head2 partial_import

    my $summary = $admin->partial_import( { users => [ ... ] }, if_exists => 'SKIP' );

C<if_exists> is C<FAIL> (default), C<SKIP> or C<OVERWRITE>.

=head2 list_clients

    my $clients = $admin->list_clients( first => 0, max => 50 );

=head2 find_client

    my $client = $admin->find_client('my-cli') or die 'no such client';

By C<clientId>, the readable key. Everything else takes the internal C<id>.

=head2 get_client

=head2 create_client

=head2 update_client

    $admin->update_client( $id, { %$client, description => 'new' } );

Send the whole representation; L</ensure_client> does that for you.

=head2 delete_client

=head2 get_client_secret

=head2 regenerate_client_secret

=head2 get_service_account_user

=head2 list_client_scopes

=head2 find_client_scope

    my $scope = $admin->find_client_scope('amr');

By C<name>.

=head2 get_client_scope

=head2 create_client_scope

=head2 update_client_scope

=head2 delete_client_scope

=head2 add_default_client_scope

    $admin->add_default_client_scope( $client_id, $scope_id );   # both internal ids

=head2 add_realm_default_client_scope

    $admin->add_realm_default_client_scope($scope_id);

New clients of the realm get this scope.

=head2 list_protocol_mappers

    my $mappers = $admin->list_protocol_mappers( client => $client_id );
    my $mappers = $admin->list_protocol_mappers( client_scope => $scope_id );

=head2 create_protocol_mapper

    my $id = $admin->create_protocol_mapper( client => $client_id, { name => 'amr', protocol => 'openid-connect', protocolMapper => 'oidc-amr-mapper', config => {...} } );

=head2 update_protocol_mapper

    $admin->update_protocol_mapper( client => $client_id, $mapper_id, \%rep );

=head2 delete_protocol_mapper

    $admin->delete_protocol_mapper( client_scope => $scope_id, $mapper_id );

=head2 list_users

    my $users = $admin->list_users( search => 'ali', max => 20 );

=head2 find_user

    my $user = $admin->find_user('alice');

By C<username>, exactly; Keycloak stores user names in lower case.

=head2 get_user

=head2 create_user

    my $id = $admin->create_user( { username => 'alice', enabled => \1, credentials => [ { type => 'password', value => $pw, temporary => \0 } ] } );

=head2 update_user

=head2 delete_user

=head2 set_password

    $admin->set_password( $id, $password, temporary => 0 );

=head2 list_credentials

=head2 delete_credential

=head2 list_sessions

=head2 logout_user

=head2 list_flows

=head2 list_executions

    my $steps = $admin->list_executions('browser');

All steps of a flow and its sub-flows, flat, each with C<level>,
C<providerId> and C<authenticationConfig>.

=head2 copy_flow

=head2 get_execution_config

=head2 create_execution_config

    my $config_id = $admin->create_execution_config( $execution_id, { alias => 'x', config => {...} } );

Works on the built-in flows too.

=head2 update_execution_config

    $admin->update_execution_config( $config_id, { alias => 'x', config => {...} } );

=head2 describe_authenticator

=head2 ensure_realm

    $admin->ensure_realm( enabled => \1, accessTokenLifespan => 600 );

=head2 ensure_client

    my $r = $admin->ensure_client( clientId => 'my-cli', publicClient => \1, attributes => { ... } );

C<defaultClientScopes>, C<optionalClientScopes> and C<protocolMappers> are
refused: Keycloak takes them when a client is created but ignores them when
it is updated, so they could not be kept in the wanted state. Use
L</add_default_client_scope> and L</ensure_protocol_mapper>.

=head2 ensure_client_scope

    my $r = $admin->ensure_client_scope( name => 'amr', attributes => { 'include.in.token.scope' => 'false' } );

The protocol defaults to C<openid-connect>.

=head2 ensure_protocol_mapper

    my $r = $admin->ensure_protocol_mapper( client => 'my-cli', name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { 'id.token.claim' => 'true' } );
    my $r = $admin->ensure_protocol_mapper( client_scope => 'amr', name => 'amr', ... );

The owner is named by C<clientId> or by scope name. The protocol defaults to
C<openid-connect>.

=head2 ensure_user

    my $r = $admin->ensure_user( username => 'alice', enabled => \1, email => 'alice@example.org',
      credentials => [ { type => 'password', value => $pw, temporary => \0 } ] );

C<credentials> are used when the user is created and ignored afterwards: a
password is not reset on every run. Call L</set_password> for that.
C<username> and C<email> are compared in lower case, the way Keycloak keeps
them, and attribute values as lists of strings (a single value may be given
as a string). Attributes the realm's user profile does not declare are dropped
by Keycloak unless the profile allows unmanaged attributes; such an attribute
never arrives and is reported as C<updated> on every run.

=head2 ensure_execution_config

    my $r = $admin->ensure_execution_config(
      flow          => 'browser',
      authenticator => 'auth-otp-form',
      config        => { 'default.reference.value' => 'otp', 'default.reference.maxAge' => 3600 },
    );

Settings of one step of an authentication flow, found by its authenticator.
C<alias> names a new configuration; default C<< "<flow> <authenticator>" >>.

Give the complete configuration. Keycloak hides the values of these settings
when they are read (they come back as C<**********>), so they can neither be
compared nor merged: an existing configuration is replaced by C<config> and
reported as C<updated> on every run.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-keycloak/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
