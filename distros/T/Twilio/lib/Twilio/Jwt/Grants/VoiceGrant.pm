package Twilio::Jwt::Grants::VoiceGrant;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::Grants::Grant';

our $VERSION = '2.001';

sub get_grant_key { return 'voice' }

sub get_incoming_allow              { return $_[0]{incoming_allow} }
sub get_outgoing_application_sid    { return $_[0]{outgoing_application_sid} }
sub get_outgoing_application_params { return $_[0]{outgoing_application_params} }
sub get_push_credential_sid         { return $_[0]{push_credential_sid} }
sub get_endpoint_id                 { return $_[0]{endpoint_id} }

sub set_incoming_allow {
  my ($self, $allow) = @_;
  $self->{incoming_allow} = $allow ? 1 : 0;
  return $self;
}

sub set_outgoing_application_sid {
  my ($self, $sid) = @_;
  $self->{outgoing_application_sid} = $sid;
  return $self;
}

sub set_outgoing_application {
  my ($self, $sid, $params) = @_;
  $self->{outgoing_application_sid}    = $sid;
  $self->{outgoing_application_params} = $params;
  return $self;
}

sub set_push_credential_sid {
  my ($self, $sid) = @_;
  $self->{push_credential_sid} = $sid;
  return $self;
}

sub set_endpoint_id {
  my ($self, $endpoint_id) = @_;
  $self->{endpoint_id} = $endpoint_id;
  return $self;
}

sub get_payload {
  my ($self) = @_;

  my %payload;
  $payload{incoming} = { allow => \1 } if $self->{incoming_allow};

  if (length($self->{outgoing_application_sid} // q{})) {
    my %outgoing = (application_sid => $self->{outgoing_application_sid});
    my $params   = $self->{outgoing_application_params};
    $outgoing{params}  = $params if $params && %{$params};
    $payload{outgoing} = \%outgoing;
  }

  for my $field (qw(push_credential_sid endpoint_id)) {
    $payload{$field} = $self->{$field} if length($self->{$field} // q{});
  }
  return \%payload;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::VoiceGrant - Lets a client make and receive calls

=head1 SYNOPSIS

  my $grant = Twilio::Jwt::Grants::VoiceGrant->new;
  $grant->set_outgoing_application($application_sid, { caller => 'alice' });
  $grant->set_incoming_allow(1);

  $token->add_grant($grant);

=head1 DESCRIPTION

See L<Twilio::Jwt::AccessToken>. Each C<set_> method returns the grant.

=head1 METHODS

=head2 get_grant_key

Returns C<voice>.

=head2 get_payload

Returns what the grant adds to the token.

=head2 set_outgoing_application

  $grant->set_outgoing_application($sid, \%params);

Sets the TwiML application for outgoing calls, and the parameters it receives.

=head2 get_outgoing_application_params

Returns those parameters.

=head2 get_incoming_allow

=head2 set_incoming_allow

=head2 get_outgoing_application_sid

=head2 set_outgoing_application_sid

=head2 get_push_credential_sid

=head2 set_push_credential_sid

=head2 get_endpoint_id

=head2 set_endpoint_id

Read and change each value.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
