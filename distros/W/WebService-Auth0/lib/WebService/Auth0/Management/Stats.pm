package WebService::Auth0::Management::Stats;

use Moo;
extends 'WebService::Auth0::Management::Base';

sub path_suffix { 'stats' }

sub daily {
  my ($self, $query) = @_;
  return $self->GET($self->uri_for('daily', $query));
}

sub active_users {
  my ($self) = @_;
  return $self->GET($self->uri_for('active-users'));
}

=head1 NAME

WebService::Auth0::Management::Stats - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 daily (\%query)

L<https://auth0.com/docs/api/management/v2#!/Stats/get_daily>

=head2 active_users

L<https://auth0.com/docs/api/management/v2#!/Stats/get_active_users>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
