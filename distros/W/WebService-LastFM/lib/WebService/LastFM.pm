package WebService::LastFM;

use strict;
use warnings;

use Carp        ();
use Digest::MD5 ();
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);
use XML::Simple;

use WebService::LastFM::Session;
use WebService::LastFM::NowPlaying;
use WebService::LastFM::Track;
use WebService::LastFM::Playlist;

our $VERSION = '0.07';

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->_die('Username and password are required')
        unless $args{username} || $args{password};

    $self->{username} = $args{username};
    $self->{password} = $args{password};
    $self->{ua}       = LWP::UserAgent->new( agent => "WebService::LastFM/$VERSION", );

    return $self;
}

sub ua { $_[0]->{ua} }

sub get_session {
    my $self = shift;

    my $url
        = 'http://ws.audioscrobbler.com/radio/handshake.php'
        . '?username='
        . $self->{username}
        . '&version= ' . "1.1.1"
        . '&platform= ' . "linux"
        . '&passwordmd5='
        . Digest::MD5::md5_hex( $self->{password} );

    my $response = $self->_get_response( GET $url);

    $self->_die('Wrong params passed')
        if !( keys %$response ) || $response->{session} eq 'FAILED';

    %$self = ( %$self, %$response );
    return WebService::LastFM::Session->new($response);
}

sub get_new_playlist {
  my $self     = shift;
  my $xspf_xml = $self->_get_new_xspf();
  my $xml      = XML::Simple->new();
  my $xspf     = $xml->XMLin($xspf_xml);

  my @playlist;
  foreach my $track_id ( keys %{ $xspf->{trackList}{track} }  ) {
    push @playlist, WebService::LastFM::Track->new( $xspf->{trackList}{track}{$track_id} )
  }
  my $playlist = WebService::LastFM::Playlist->new({ tracks => \@playlist });
  return $playlist;

}

sub _get_new_xspf {
  my $self = shift;
  my $session_key = $self->{session} or $self->_die('Must have a session to get xspf');
  my $url  = 'http://ws.audioscrobbler.com/radio/xspf.php' .
    '?sk=' . $self->{session} . '&discovery=0&desktop=0';

  my $content =  $self->_do_request( GET $url );
  return $content;
}


sub get_nowplaying {
    my $self = shift;
    my $url  = 'http://ws.audioscrobbler.com/radio/np.php' . '?session=' . $self->{session};

    my $response = $self->_get_response( GET $url);
    return WebService::LastFM::NowPlaying->new($response);
}

sub send_command {
    my ( $self, $command ) = @_;
    $self->_die('Command not passed') unless $command;

    my $url = 'http://ws.audioscrobbler.com/radio/control.php' . '?session=' . $self->{session} . '&command=' . $command;

    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub change_station {
    my ( $self, $user ) = @_;
    $self->_die('URL not passed') unless $user;

    my $url = 'http://ws.audioscrobbler.com/radio/adjust.php' . '?session=' . $self->{session} . '&url=' . "user/$user/personal";

    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub change_tag {
    my ( $self, $tag ) = @_;
    $self->_die('tag not passed') unless $tag;
    $tag =~ s/ /\%20/;

    my $url = 'http://ws.audioscrobbler.com/radio/adjust.php' . '?session=' . $self->{session} . '&url=' . "globaltags/$tag";

    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub _get_response {
    my ( $self, $request ) = @_;
    my $content  = $self->_do_request($request);
    my $response = $self->_parse_response($content);
    return $response;
}

sub _parse_response {
    my ( $self, $content ) = @_;
    my $response = {};

    $response->{$1} = $2 while ( $content =~ s/^(.+?) *= *(.*)$//m );

    return $response;
}

sub _do_request {
    my ( $self, $request ) = @_;
    my $response = $self->ua->simple_request($request);

    $self->_die( 'Request failed: ' . $response->message )
        unless $response->is_success;

    return $response->content;
}

sub _die {
    my ( $self, $message ) = @_;
    Carp::croak($message);
}

1;

__END__

=head1 NAME

WebService::LastFM - Simple interface to Last.FM Web service API

=head1 SYNOPSIS

  use WebService::LastFM;


  my $lastfm = WebService::LastFM->new(
      username => $config{username},
      password => $config{password},
  );
  my $stream_info = $lastfm->get_session  || die "Can't get Session\n";
  my $session_key = $stream_info->session;

  $lastfm->change_tag( 'ska+punk' );

  while (1) {

       my $playlist = $lastfm->get_new_playlist();

       while ( my $track = $playlist->get_next_track() ) {

           print "Playing '".$track->title."' by ".$track->creator."\n";

           my @cmd = ( 'mpg123' , $track->location() );
           system( @cmd );

       }
   }


=head1 DESCRIPTION

WebService::LastFM provides you a simple interface to Last.FM Web
service API. It currently supports Last.FM Stream API 1.2.

=head1 CAVEAT

This is NOT A BACKWARDS COMPATIBLE update. LastFM has changed their
API enough to warrant an interface change.

=head1 METHODS

=over 4

=item new(I<%args>)

  $lastfm = WebService::LastFM->new(
      username => $username,
      password => $password,
  );

Creates and returns a new WebService::LastFM object.

=item get_session()

  $stream_info = $lastfm->get_session;

Returns a session key and stream URL as a WebService::LastFM::Session
object.

=item get_new_playlist()

  $stream_info = $lastfm->get_new_playlist();

Returns a WebService::LastFM::Playlist that contains a list of tracks
based on the current station. You can/should use the get_next_track
method to retrieve the WS:LFM:Track object. Once the playlist is
depleted (right now 5 tracks) just grab a new playlist.

       my $playlist = $lastfm->get_new_playlist();

       while ( my $track = $playlist->get_next_track() ) {

           print "Playing '".$track->title."' by ".$track->creator."\n";

           my @cmd = ( 'mpg123' , $track->location() );
           system( @cmd );

       }


=item get_nowplaying()

  $current_song = $lastfm->get_nowplaying;

Returns a WebService::LastFM::NowPlaying object to retrieve the
information of the song you're now listening.

=item send_command(I<$command>)

  $response = $lastfm->send_command($command);

Sends a command to Last.FM Stream API to control the
streaming. C<$command> can be one of the follows: I<skip>, I<love>,
I<ban>, I<rtp>, or I<nortp>.

I<$response> which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item change_station(I<$friend>)

  $response = $lastfm->change_station($friend);

Changes the station of your stream to C<$friend>'s one.

I<$response> which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item change_tag(I<$tag>)

  $response = $lastfm->change_tag($tag);

Change the station of your stream to play music tagged with C<$tag>.

$response which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item ua

  $lastfm->ua->timeout(10);

Returns the LWP::UserAgent object which is internally used by
C<$lastfm> object. You can set some values to customize its
behavior. See the documentation of L<LWP::UserAgent> for more details.

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
