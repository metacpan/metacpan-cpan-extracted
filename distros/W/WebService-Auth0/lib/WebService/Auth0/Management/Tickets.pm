package WebService::Auth0::Management::Tickets;

use Moo;
extends 'WebService::Auth0::Management::Base';

sub path_suffix { 'tickets' }

sub create_email_verification {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('email-verification'), $params);
}

sub create_password_change {
  my ($self, $params) = @_;
  return $self->POST_JSON($self->uri_for('password-change'), $params);
}

=head1 NAME

WebService::Auth0::Management::Tickets - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 create_email_verification 

L<https://auth0.com/docs/api/management/v2#!/Tickets/post_email_verification>

=head2 create_password_change

L<https://auth0.com/docs/api/management/v2#!/Tickets/post_password_change>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
