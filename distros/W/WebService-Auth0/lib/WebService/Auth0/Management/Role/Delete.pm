package WebService::Auth0::Management::Role::Delete;

use Moo::Role;

requires 'DELETE', 'uri_for';

sub delete {
  my ($self, $id) = @_;
  return $self->DELETE($self->uri_for($id));
}

1;

=head1 NAME

WebService::Auth0::Management::Role::Delete - Role that provides a 'delte' API method

=head1 SYNOPSIS

    package WebService::Auth0::Management::Users;

    use Moo;
    extends 'WebService::Auth0::Management::Base';

    with 'WebService::Auth0::Management::Role::Delete';

    sub path_suffix { 'users' }

    # Other custom methods for the Endpoint

    1;

=head1 DESCRIPTION

Helper role

=head1 METHODS

This class defines the following methods:

=head2 delete ($id)

Delete a resource identified with $id

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.
L<WebService::Auth0::Management::Base>

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;




