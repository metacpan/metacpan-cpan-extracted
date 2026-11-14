package Twilio::Jwt::Grants::PlaybackGrant;

use 5.016;
use warnings;

use parent 'Twilio::Jwt::Grants::Grant';

our $VERSION = '2.002';

sub get_grant_key { return 'player' }

sub get_grant { return $_[0]{grant} }

sub set_grant {
  my ($self, $grant) = @_;
  $self->{grant} = $grant;
  return $self;
}

sub get_payload {
  my ($self) = @_;
  return $self->{grant} // {};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::Grants::PlaybackGrant - Lets a client play a live stream

=head1 SYNOPSIS

  my $grant = Twilio::Jwt::Grants::PlaybackGrant->new;
  $grant->set_grant(\%playback_grant);

  $token->add_grant($grant);

=head1 DESCRIPTION

See L<Twilio::Jwt::AccessToken>. The hash reference comes from Twilio, and goes
into the token as it is.

=head1 METHODS

=head2 get_grant_key

Returns C<player>.

=head2 get_payload

Returns what the grant adds to the token.

=head2 get_grant

=head2 set_grant

Read and change the value. C<set_grant> returns the grant.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
