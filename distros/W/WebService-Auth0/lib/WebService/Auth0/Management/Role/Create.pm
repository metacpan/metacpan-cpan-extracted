package WebService::Auth0::Management::Role::Create;

use Moo::Role;

requires 'POST_JSON', 'uri_for';

sub create {
  my ($self, $json) = @_;
  return $self->POST_JSON($self->uri_for, $json);
}

1;

=head1 NAME

WebService::Auth0::Management::Role::Create - Role that provides a 'create' API method

=head1 SYNOPSIS

    package WebService::Auth0::Management::Users;

    use Moo;
    extends 'WebService::Auth0::Management::Base';

    with 'WebService::Auth0::Management::Role::Create';

    sub path_suffix { 'users' }

    # Other custom methods for the Endpoint

    1;

=head1 DESCRIPTION

Helper role

=head1 METHODS

This class defines the following methods:

=head2 create (\%params)

Create a new item on the endpoint with the given parameters

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.
L<WebService::Auth0::Management::Base>

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;


