use strictures;

package WebService::GoogleAPI::Client::Credentials;
$WebService::GoogleAPI::Client::Credentials::VERSION = '0.18';

# ABSTRACT: Credentials for particular Client instance. You can use this module as singleton also if you need to share
#           credentials between two or more modules


use Carp;
use Moo;
with 'MooX::Singleton';


has 'access_token' => ( is => 'rw' );
has 'user'         => ( is => 'rw', trigger => \&get_access_token_for_user );                                # full gmail, like peter@shotgundriver.com
has 'auth_storage' => ( is => 'rw', default => sub { WebService::GoogleAPI::Client::AuthStorage->new } );    # dont delete to able to configure


sub get_access_token_for_user
{
  my ( $self ) = @_;
  if ( $self->auth_storage->is_set )
  {                                                                                                          # chech that auth_storage initialized fine
    $self->access_token( $self->auth_storage->get_access_token_from_storage( $self->user ) );
  }
  else
  {
    croak q/Can get access token for specified user because storage isn't set/;
  }
  return $self;                                                                                              ## ?? is self the access token for user?
}

sub get_scopes_as_array
{
  my ( $self ) = @_;
  if ( $self->auth_storage->is_set )
  {                                                                                                          # chech that auth_storage initialized fine
    return $self->access_token( $self->auth_storage->get_scopes_from_storage_as_array() );
  }
  else
  {
    croak q/Can get access token for specified user because storage isn't set/;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::Credentials - Credentials for particular Client instance. You can use this module as singleton also if you need to share

=head1 VERSION

version 0.18

=head1 METHODS

=head2 get_access_token_for_user

Automatically get access_token for current user if auth_storage is set

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
