package WebService::Auth0::Management::Connections;

use Moo;
extends 'WebService::Auth0::Management::Base';
with 'WebService::Auth0::Management::Role::Search',
  'WebService::Auth0::Management::Role::Create',
  'WebService::Auth0::Management::Role::Update',
  'WebService::Auth0::Management::Role::Delete',
  'WebService::Auth0::Management::Role::Get';

sub path_suffix { 'connections' }

sub delete_users_by_email {
  my ($self, $conn_id, $email) = @_;
  return $self->DELETE($self->uri_for($conn_id, 'users', +{email=>$email}));
}

=head1 NAME

WebService::Auth0::Management::Connections - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 search (\%params)

L<https://auth0.com/docs/api/management/v2#!/Connections/get_connections>

=head2 create (\%params)

L<https://auth0.com/docs/api/management/v2#!/Clients/post_clients>

=head2 get ($id)

L<https://auth0.com/docs/api/management/v2#!/Connections/get_connections_by_id>

=head2 delete ($conn_id)

L<https://auth0.com/docs/api/management/v2#!/Connections/delete_connections_by_id>

=head2 update ($conn_id, \%params)

L<https://auth0.com/docs/api/management/v2#!/Connections/delete_connections_by_id>

=head2 delete_users_by_email ($conn_id, $email)

L<https://auth0.com/docs/api/management/v2#!/Connections/delete_users_by_email>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
