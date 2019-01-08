package WebService::Auth0::Management::Clients;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Update',
  'WebService::Auth0::Management::Role::Delete',
  'WebService::Auth0::Management::Role::Get';

sub path_suffix { 'clients' }

sub rotate_secret {
  my ($self, $user_id) = @_;
  return $self->POST($self->uri_for($user_id, 'rotate-secret'));
}

=head1 NAME

WebService::Auth0::Management::Clients - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Clients/get_clients>

Searches and returns all clients.  Right now the query parameters are limited
(see linked docs).

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Clients/post_clients>

=head2 get ($id)

L<https://auth0.com/docs/api/management/v2#!/Clients/get_clients_by_id>

=head2 delete ($client_id)

L<https://auth0.com/docs/api/management/v2#!/Clients/delete_clients_by_id>

=head2 update ($client_id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Clients/patch_clients_by_id>

=head2 rotate_secret ($client_id)

L<https://auth0.com/docs/api/management/v2#!/Clients/post_rotate_secret>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
