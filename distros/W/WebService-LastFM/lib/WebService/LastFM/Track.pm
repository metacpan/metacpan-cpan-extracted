package WebService::LastFM::Track;

use strict;
use warnings;

use base qw(Class::Accessor);
our $VERSION = '0.07';

__PACKAGE__->mk_accessors(
    qw( link
        location
        creator
        lastfm:trackauth
        lastfm:albumId
        duration
        image
        lastfm:artistId
        album
        title
        )
);

sub new {
    my ( $class, $args ) = @_;
    bless $args, $class;
}

1;

__END__

=head1 NAME

WebService::LastFM::Track - The Track class of WebService::LastFM

=head1 SYNOPSIS

  use WebService::LastFM;


  my $lastfm = WebService::LastFM->new(
        username => $config{username},
        password => $config{password},
  );
  my $session_key = $stream_info->session;
  my $playlist = $lastfm->get_new_playlist();
  while ( my $track = $playlist->get_next_track() ) {
      foreach ( qw/ location  creator  duration image
                    album     title    lastfm:artistId
                    lastfm:trackauth lastfm:albumId /)
      {
        print "$_: ".$track->$_."\n" if defined $track->$_;
        system( 'mpg123', $track->location() );
      }
  }

=head1 DESCRIPTION

WebService::LastFM::Track provides the Track class to WebService::LastFM

=head1 METHODS

=over 4

=item location()

  $url = $track->location();

Returns a url ready for passing to you streaming media player. This is a one-time-use url.
Repeated attempts will fail.

=item creator()

  $artists = $track->creator();

Returns the artist of the track.

=item duration()

  $duration = $track->duration();

Returns the duration of the track.

=item image()

  $image_url = $track->image();

Returns a url to the album image, if available.

=item album()

  $album_name = $track->album();

Returns the album name, if available.

=item title()

  $track_title = $track->title();

Returns the track's title.

=back

=head1 SEE ALSO

=over 4

=item * Last.FM

L<http://www.last.fm/>

=item * Last.FM Stream API documentation

L<http://www.audioscrobbler.com/development/lastfm-ws.php>

=item * L<LWP::UserAgent>

=back

=head1 AUTHOR

Christian Brink, E<lt>grep_pdx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 - 2009 by Christian Brink

Copyright (C) 2005 - 2008 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
