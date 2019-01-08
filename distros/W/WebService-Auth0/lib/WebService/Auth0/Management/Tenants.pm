package WebService::Auth0::Management::Tenants;

use Moo;
extends 'WebService::Auth0::Management::Base';

sub path_suffix { 'tenants/settings' }

sub get {
  my ($self, $params) = @_;
  $params = +{} unless $params;
  return $self->GET($self->uri_for($params));
}

sub update {
  my ($self, $params) = @_;
  return $self->PATCH_JSON($self->uri_for(), $params);
}

=head1 NAME

WebService::Auth0::Management::Tenants - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 get (\%params)

L<https://auth0.com/docs/api/management/v2#!/Tenants/get_settings>

=head2 update (\%fields)

L<https://auth0.com/docs/api/management/v2#!/Tenants/patch_settings>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
