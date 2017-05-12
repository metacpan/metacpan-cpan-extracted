use strict;
use warnings;

package WWW::XBoxLive::Gamercard;
{
  $WWW::XBoxLive::Gamercard::VERSION = '1.123160';
}

# ABSTRACT: Represents an XBox Live Gamercard

use Object::Tiny qw{
  account_status
  bio
  gamerscore
  gamertag
  gender
  is_valid
  location
  motto
  name
  profile_link
  recent_games
  reputation
};

sub avatar_small {
    my ($this) = @_;

    return unless $this->gamertag;

    return sprintf( 'http://avatar.xboxlive.com/avatar/%s/avatarpic-s.png',
        $this->gamertag );
}

sub avatar_large {
    my ($this) = @_;

    return unless $this->gamertag;

    return sprintf( 'http://avatar.xboxlive.com/avatar/%s/avatarpic-l.png',
        $this->gamertag );
}

sub avatar_body {
    my ($this) = @_;

    return unless $this->gamertag;

    return sprintf( 'http://avatar.xboxlive.com/avatar/%s/avatar-body.png',
        $this->gamertag );
}

1;


__END__
=pod

=head1 NAME

WWW::XBoxLive::Gamercard - Represents an XBox Live Gamercard

=head1 VERSION

version 1.123160

=head1 SYNOPSIS

  my $gamercard = WWW::XBoxLive::Gamercard->new(%data);

  say $gamercard->name;
  say $gamercard->location;

=head1 ATTRIBUTES

=head2 account_status

Either C<gold>, C<silver> or C<unknown>.

=head2 avatar_small

URL to the small avatar pic. For example, L<http://avatar.xboxlive.com/avatar/BrazenStraw3/avatarpic-s.png>.

=head2 avatar_large

URL to the large avatar pic. For example, L<http://avatar.xboxlive.com/avatar/BrazenStraw3/avatarpic-l.png>.

=head2 avatar_body

URL to the avatar body pic. For example, L<http://avatar.xboxlive.com/avatar/BrazenStraw3/avatar-body.png>.

=head2 bio

The players bio.

=head2 gamerscore

The players gamerscore.

=head2 gamertag

The players gamertag.

=head2 gender

Either C<male>, C<female> or C<unknown>.

=head2 is_valid

True if this is a valid profile (i.e. a real player).

=head2 location

The location of the player.

=head2 motto

The players motto.

=head2 name

The players name.

=head2 profile_link

A link to the profile.

=head2 recent_games

Returns an array ref of L<WWW::XBoxLive::Game> objects.

=head2 reputation

The number of reputation stars the player has. A number between 1 and 5.

=head1 SEE ALSO

=over 4

=item *

L<WWW::XBoxLive>

=item *

L<WWW::XBoxLive::Game>

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

