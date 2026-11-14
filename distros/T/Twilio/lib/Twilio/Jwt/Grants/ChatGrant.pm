package Twilio::Jwt::Grants::ChatGrant;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::Grants::Grant';

our $VERSION = '2.002';

sub get_grant_key { return 'chat' }

sub payload_fields { return qw(service_sid endpoint_id deployment_role_sid push_credential_sid) }

sub get_service_sid         { return $_[0]{service_sid} }
sub get_endpoint_id         { return $_[0]{endpoint_id} }
sub get_deployment_role_sid { return $_[0]{deployment_role_sid} }
sub get_push_credential_sid { return $_[0]{push_credential_sid} }

sub set_service_sid {
  my ($self, $sid) = @_;
  $self->{service_sid} = $sid;
  return $self;
}

sub set_endpoint_id {
  my ($self, $endpoint_id) = @_;
  $self->{endpoint_id} = $endpoint_id;
  return $self;
}

sub set_deployment_role_sid {
  my ($self, $sid) = @_;
  $self->{deployment_role_sid} = $sid;
  return $self;
}

sub set_push_credential_sid {
  my ($self, $sid) = @_;
  $self->{push_credential_sid} = $sid;
  return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::ChatGrant - Lets a client use Twilio Conversations

=head1 SYNOPSIS

  my $grant = Twilio::Jwt::Grants::ChatGrant->new;
  $grant->set_service_sid($service_sid);

  $token->add_grant($grant);

=head1 DESCRIPTION

See L<Twilio::Jwt::AccessToken>. Each C<set_> method returns the grant.

=head1 METHODS

=head2 get_grant_key

Returns C<chat>.

=head2 payload_fields

Returns the fields of the grant.

=head2 get_service_sid

=head2 set_service_sid

=head2 get_endpoint_id

=head2 set_endpoint_id

=head2 get_deployment_role_sid

=head2 set_deployment_role_sid

=head2 get_push_credential_sid

=head2 set_push_credential_sid

Read and change each value.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
