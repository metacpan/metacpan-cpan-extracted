package WebService::Auth0::Management::Guardian;

use Moo;
extends 'WebService::Auth0::Management::Base';

sub path_suffix { 'guardian' }

sub factors {
  my ($self) = @_;
  return $self->GET($self->uri_for('factors'));
}

sub enrollments_by_id {
  my ($self, $id) = @_;
  return $self->GET($self->uri_for('enrollments',$id));
}

sub delete_enrollment {
  my ($self, $id) = @_;
  return $self->DELETE($self->uri_for('enrollments',$id));
}

sub templates {
  my ($self) = @_;
  return $self->GET($self->uri_for('factors','sms','templates'));
}

sub update_templates {
  my ($self, $body) = @_;
  return $self->PUT_JSON($self->uri_for('factors','sms','templates'), $body);
}

sub providers_by_name {
  my ($self, $factor_name, $provider_name) = @_;
  return $self->GET($self->uri_for('factor', $factor_name, 'providers', $provider_name));
}

sub create_ticket {
  my ($self, $data) = @_;
  return $self->POST_JSON($self->uri_for('enrollments','ticket'),$data);
}

sub update_factor {
  my ($self, $factor_name, $data) = @_;
  return $self->PUT_JSON($self->uri_for('factor', $factor_name), $data);
}

sub put_twilio {
  my ($self, $data) = @_;
  return $self->PUT_JSON($self->uri_for('factor', 'sms', 'providers', 'twilo'), $data);
}

=head1 NAME

WebService::Auth0::Management::Guardian - Users management API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

This class defines the following methods:

=head2 factors

L<https://auth0.com/docs/api/management/v2#!/Guardian/get_factors>

=head2 enrollments ($enrollment_id)

L<https://auth0.com/docs/api/management/v2#!/Guardian/get_enrollments_by_id>

=head2 delete_enrollent ($enrollment_id_

L<https://auth0.com/docs/api/management/v2#!/Guardian/delete_enrollments_by_id>

=head2 templates

L<https://auth0.com/docs/api/management/v2#!/Guardian/get_templates>

=head2 update_templates

L<https://auth0.com/docs/api/management/v2#!/Guardian/put_templates>

=head2 providers_by_name

L<https://auth0.com/docs/api/management/v2#!/Guardian/get_providers_by_name>

=head2 create_ticket

L<https://auth0.com/docs/api/management/v2#!/Guardian/post_ticket>

=head2 update_factor

L<https://auth0.com/docs/api/management/v2#!/Guardian/put_factors_by_name>

=head2 put_twilio

L<https://auth0.com/docs/api/management/v2#!/Guardian/put_twilio>

=head1 SEE ALSO
 
L<WebService::Auth0>, L<https://auth0.com>.

=head1 AUTHOR
 
    See L<WebService::Auth0>
  
=head1 COPYRIGHT & LICENSE
 
    See L<WebService::Auth0>

=cut

1;
