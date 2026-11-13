package Twilio::Jwt::Grants::VideoGrant;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::Grants::Grant';

our $VERSION = '2.001';

sub get_grant_key { return 'video' }

sub payload_fields { return qw(room) }

sub get_room { return $_[0]{room} }

sub set_room {
  my ($self, $room) = @_;
  $self->{room} = $room;
  return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::VideoGrant - Lets a client join a video room

=head1 SYNOPSIS

  my $grant = Twilio::Jwt::Grants::VideoGrant->new;
  $grant->set_room('daily-standup');

  $token->add_grant($grant);

=head1 DESCRIPTION

See L<Twilio::Jwt::AccessToken>.

=head1 METHODS

=head2 get_grant_key

Returns C<video>.

=head2 payload_fields

Returns the fields of the grant.

=head2 get_room

=head2 set_room

Read and change the room, by SID or name. C<set_room> returns the grant.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
