use strictures;

package WebService::GoogleAPI::Client::AuthStorage;
$WebService::GoogleAPI::Client::AuthStorage::VERSION = '0.16';

# ABSTRACT: JSON File Persistence for Google OAUTH Project and User Access Tokens

## is client->auth_storage
## or is Client->ua->auth_storage delegated as auth_storage to client

## or is UserAgent->credentials

use Moo;
use Carp;
use WebService::GoogleAPI::Client::AuthStorage::ConfigJSON;


has 'storage' => ( is => 'rw', default => sub { WebService::GoogleAPI::Client::AuthStorage::ConfigJSON->new } );    # by default
has 'is_set' => ( is => 'rw', default => 0 );



sub setup
{
  my ( $self, $params ) = @_;
  if ( $params->{ type } eq 'jsonfile' )
  {
    $self->storage->pathToTokensFile( $params->{ path } );
    $self->storage->setup;
    $self->is_set( 1 );
  }
  else
  {
    croak "Unknown storage type. Allowed types are jsonfile, dbi and mongo";
  }
  return $self;
}

### Below are list of methods that each Storage subclass must provide


sub get_credentials_for_refresh
{
  my ( $self, $user ) = @_;
  return $self->storage->get_credentials_for_refresh( $user );
}

sub get_access_token_from_storage
{
  my ( $self, $user ) = @_;
  return $self->storage->get_access_token_from_storage( $user );
}

sub set_access_token_to_storage
{
  my ( $self, $user, $access_token ) = @_;
  return $self->storage->set_access_token_to_storage( $user, $access_token );
}


sub get_scopes_from_storage_as_array
{
  my ( $self ) = @_;
  return $self->storage->get_scopes_from_storage_as_array();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::AuthStorage - JSON File Persistence for Google OAUTH Project and User Access Tokens

=head1 VERSION

version 0.16

=head1 METHODS

=head2 setup

Set appropriate storage

  my $auth_storage = WebService::GoogleAPI::Client::AuthStorage->new;
  $auth_storage->setup; # by default will be config.json
  $auth_storage->setup({type => 'jsonfile', path => '/abs_path' });

=head2 get_credentials_for_refresh

Return all parameters that is needed for Mojo::Google::AutoTokenRefresh::refresh_access_token() function: client_id, client_secret and refresh_token

$c->get_credentials_for_refresh('examplemail@gmail.com')

This method must have all subclasses of WebService::GoogleAPI::Client::AuthStorage

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
