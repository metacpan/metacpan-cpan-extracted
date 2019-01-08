package WebService::Auth0::Management::Role::Update;

use Moo::Role;

requires 'POST_JSON', 'uri_for';

sub update {
  my ($self, $id, $json) = @_;
  return $self->PATCH_JSON($self->uri_for($id), $json);
}

1;

=head1 NAME

WebService::Auth0::Management::Role::Update - Role that provides an 'update' API method

=head1 SYNOPSIS

    package WebService::Auth0::Management::Users;

    use Moo;
    extends 'WebService::Auth0::Management::Base';

    with 'WebService::Auth0::Management::Role::Update';

    sub path_suffix { 'users' }

    # Other custom methods for the Endpoint

    1;

=head1 DESCRIPTION

Helper role

=head1 METHODS

This class defines the following methods:

=head2 update ($id,\%params)

Update a resource by the $id with %params.

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.
L<WebService::Auth0::Management::Base>

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;



