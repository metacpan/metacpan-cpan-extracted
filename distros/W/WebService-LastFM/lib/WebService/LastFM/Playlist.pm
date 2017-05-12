package WebService::LastFM::Playlist;

use strict;
use warnings;

use base qw(Class::Accessor);
our $VERSION = '0.07';

__PACKAGE__->mk_accessors(
    qw( tracks )
);

sub new {
    my ( $class, $args ) = @_;
    bless $args, $class;
}

sub get_next_track {
  my $self = shift;
  return $self->tracks_left() ? pop @{ $self->{tracks} } : undef;
}

sub tracks_left {
  my $self = shift;
  return  defined $self->{tracks} ? scalar( @{ $self->{tracks} } ) : 0;
}

1;
__END__

=head1 NAME

WebService::LastFM::Playlist - Playlist class of WebService::LastFM

=head1 SYNOPSIS

  use WebService::LastFM;


  my $lastfm = WebService::LastFM->new(
        username => $config{username},
        password => $config{password},
  );
  my $stream_info = $lastfm->get_session  || die "Can't get Session\n";
  my $playlist = $lastfm->get_new_playlist();

  while ( my $track = $playlist->get_next_track() ) {
      print "Playing '".$track->title."' by ".$track->creator."\n";

      my @cmd = ( 'mpg123' , $track->location() );
      system( @cmd );
  }


=head1 DESCRIPTION

WebService::LastFM::Playlist provides you an interface to the LastFM playlists.

=head1 METHODS

=over 4

=item get_new_playlist()

  my $playlist = $lastfm->get_new_playlist();

Creates and returns a new WebService::LastFM::Playlist object after you have
established a session.

=item get_next_track()

  $track = $playlist->get_next_track();

Returns a WS::LFM::Track object and removes is from the queue. After the queue is
empty it returns undef.

=item tracks_left()

  $tracks_remaining_in_queue = $playlist->tracks_left;

Returns the count of tracks currently left in the playlist queue.


=item tracks()

  my @tracks = $playlist->tracks();

Returns a list of all WS::LFM::Track objects left in the queue.
This is NOT what you generally want, but who am I to say.
WS::LFM:Track objects contain a one-time-use url to play the song,
so unless you are going to control your own queue then it's best to
use the C<get_next_track> and the playlist's queue.



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
