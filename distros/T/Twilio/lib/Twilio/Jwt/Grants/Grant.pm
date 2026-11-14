package Twilio::Jwt::Grants::Grant;

use 5.016;
use warnings;

use Carp qw(croak);

our $VERSION = '2.002';

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

sub get_grant_key {
  my ($self) = @_;
  croak ref($self) . ' must implement get_grant_key';
}

sub get_payload {
  my ($self) = @_;

  my %payload;
  for my $field ($self->payload_fields) {
    $payload{$field} = $self->{$field} if length($self->{$field} // q{});
  }
  return \%payload;
}

sub payload_fields { return }

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::Grant - Base class of the grants of an access token

=head1 DESCRIPTION

A grant says what an L<Twilio::Jwt::AccessToken> allows. Each subclass names its
place in the token, and the fields it writes there. A field with no value is left
out.

=head1 METHODS

=head2 new

  my $grant = Twilio::Jwt::Grants::VideoGrant->new;

=head2 get_grant_key

Returns the name of the grant inside the token.

=head2 get_payload

Returns a hash reference with what the grant adds to the token.

=head2 payload_fields

Returns the fields that a subclass writes.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
