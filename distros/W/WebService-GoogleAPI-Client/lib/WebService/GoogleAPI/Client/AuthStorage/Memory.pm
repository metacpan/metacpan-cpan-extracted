use strictures;

package WebService::GoogleAPI::Client::AuthStorage::Memory;
$WebService::GoogleAPI::Client::AuthStorage::Memory::VERSION = '0.21';

# ABSTRACT: Specific methods to fetch tokens from JSON data sources

use Mojo::Base 'WebService::GoogleAPI::Client::AuthStorage';

use Config::JSON;
use Carp;

#has 'pathToTokensFile' => ( is => 'rw', default => 'gapi.json' );    # default is gapi.json

# has 'tokensfile';  # Config::JSON object pointer
#my $tokensfile;
has 'debug'  => ( is => 'rw', default => 0 );
has 'scopes' => ( is => 'rw', default => [] );
has 'client_secret' => sub {''};
has 'client_id'     => sub {''};
has 'access_token'  => sub {''};
has 'refresh_token' => sub {''};

## cringe .. getters and setters, tokenfile?, global $tokensfile? .. *sigh*

sub setup
{
  my ( $self ) = @_;
  return $self;
}

sub get_credentials_for_refresh
{
  my ( $self, $user ) = @_;
  return { client_id => $self->client_id(), client_secret => $self->client_secret(), refresh_token => $self->refresh_token() };
}

sub get_token_emails_from_storage
{
  #my $tokens = $tokensfile->get( 'gapi/tokens' );
  return [];
}


sub get_client_id_from_storage
{
  my ( $self, ) = @_ : return $self->client_id();
}

sub get_client_secret_from_storage
{
  my ( $self, ) = @_ : return $self->get_client_secret_from_storage();
}

sub get_refresh_token_from_storage
{
  my ( $self, $user ) = @_;

  return $self->refresh_token();
}

sub get_access_token_from_storage
{
  my ( $self, $user ) = @_;
  return $self->access_token();
}

sub set_access_token_to_storage
{
  my ( $self, $user, $token ) = @_;
  $self->access_token( $token );
}

sub get_scopes_from_storage
{
  my ( $self ) = @_;
  return $self->scopes();    ## NB -  is stored as space sep list
}

sub get_scopes_from_storage_as_array
{
  my ( $self ) = @_;
  return [split( ' ', $self->scopes() )];    ## NB - returns an array - is stored as space sep list
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::AuthStorage::Memory - Specific methods to fetch tokens from JSON data sources

=head1 VERSION

version 0.21

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
