package Video::PlaybackMachine::Player;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::Player
####
#### A POE::Session which displays movies and still frames onscreen
#### based on events.
####

use Moo;

use Exporter 'import';
our @EXPORT_OK = qw(PLAYER_STATUS_STOP PLAYER_STATUS_PLAY PLAYER_STATUS_STILL
  PLAYBACK_OK PLAYBACK_ERROR PLAYBACK_STOPPED);

use POE;
use X11::FullScreen;
use Video::Xine;
use Video::Xine::Stream qw/:status_constants/;
use Video::PlaybackMachine::EventWheel::FullScreen;
use Video::PlaybackMachine::Player::EventWheel;
use Video::PlaybackMachine::Config;
use Video::Xine::Util 'make_x11_fs_visual';
use Carp;

with 'Video::PlaybackMachine::Logger';

############################# Class Constants ################################

## Status codes Xine will report
use constant PLAYER_STATUS_STOP => 0;
use constant PLAYER_STATUS_PLAY => 1;

## How-the-movie-played status codes

# OK == played through and stopped at the end
use constant PLAYBACK_OK => 1;

# ERROR == problem in trying to play
use constant PLAYBACK_ERROR => 2;

## Types of playback
use constant PLAYBACK_TYPE_MUSIC => 0;
use constant PLAYBACK_TYPE_MOVIE => 1;

############################## Class Methods #################################

##
## new()
##
## Returns a new instance of Player. Note that the session is not created
## until you call spawn().
##

has 'xine' => ( is => 'lazy' );

has 'fullscreen' => ( 
	is => 'lazy',
	isa => sub { $_[0]->isa('X11::FullScreen') or die; },
	handles => [ 'window' ]
);

has 'x_display' => (
    is      => 'ro',
    default => Video::PlaybackMachine::Config->config()->x_display()
);

has 'xine_vo' => ( is => 'lazy' );

has 'stream' => ( is => 'lazy' );

has 'playback_type' => ( is => 'rw' );

############################## Session Methods ###############################

sub _build_xine {
    my $self = shift;

    return Video::Xine->new();
}

sub _build_fullscreen {
    my $self = shift;

    my $fullscreen = X11::FullScreen->new( $self->x_display() );
    $fullscreen->show();
    return $fullscreen;

}

sub _build_xine_vo {
    my $self = shift;
    
    my $x11_visual =
      Video::Xine::Util::make_x11_fs_visual($self->fullscreen);

    my $driver =
      Video::Xine::Driver::Video->new( $self->xine, "auto", 1, $x11_visual,
        $self->fullscreen() );

    return $driver;
}

sub _build_stream {
    my $self = shift;

    my $stream = $self->xine()->stream_new( undef, $self->xine_vo() )
      or croak "Unable to open video stream";

    return $stream;
}

##
## On session start, initializes Xine and prepares it to start playing.
##
sub _start {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    $kernel->alias_set('Player');

    $self->fullscreen()->sync();

    $heap->{'stream_queue'} = Video::PlaybackMachine::Player::EventWheel->new(
        {
            'stream' => $self->stream()
        }
    );

    my $fq = Video::PlaybackMachine::EventWheel::FullScreen->new(
        'source' => $self->fullscreen()
    );

    $fq->set_expose_handler(
        sub {
            $self->stream()->get_video_port()
              ->send_gui_data( XINE_GUI_SEND_EXPOSE_EVENT, $_[1] );
        }
    );
    $fq->spawn();

    $heap->{'fullscreen_queue'} = $fq;

    return;

}

##
## Responds to a 'play' request by playing a movie on Xine.
##
## Arguments:
##
##   ARG0: $postback -- what to call after the play is completed
##   ARG1: $offset -- number of seconds after the movie's start to begin
##   ARG2: @filenames -- ARG1 onward contains the files to play, in order.
##
## After Xine is started, we'll check on it every $XINE_CHECK_INTERVAL
## seconds to see if it has stopped.
##
sub play {
    my ( $kernel, $self, $heap, $postback, $offset, @files ) =
      @_[ KERNEL, OBJECT, HEAP, ARG0, ARG1, ARG2 .. $#_ ];

    defined $offset or $offset = 0;

    my $log = $self->logger();

    # TODO Remove fatal
    @files or die "No files specified! stopped";

    # Stop if we're playing
    if ( $self->stream()->get_status() == XINE_STATUS_PLAY ) {
        $self->stream()->stop();
        $self->stream()->close();
    }

    # Clear out any previous events
    $heap->{'stream_queue'}->clear_events();

    # Clear the screen
    $self->clear_window();

    $log->info("Playing $files[0]");

    my $s = $self->stream();

    $s->open( $files[0] )
      or do {
        $log->error( "Unable to open '$files[0]': Error " . $s->get_error() );
        $postback->(PLAYBACK_ERROR);
        return;
      };

    $s->play( 0, $offset * 1000 )
      or do {
        $log->error( "Unable to play '$files[0]': Error " . $s->get_error() );
        $postback->(PLAYBACK_ERROR);
        return;
      };

    # Tell the system to refresh the window
    # Drawable changed
    $s->get_video_port()
      ->send_gui_data( XINE_GUI_SEND_DRAWABLE_CHANGED, $self->window() );
    $s->get_video_port()->send_gui_data( XINE_GUI_SEND_VIDEOWIN_VISIBLE, 1 );

    # Spawn a watcher to call the postback after the fact
    $heap->{'stream_queue'}->set_stop_handler($postback);
    $heap->{'stream_queue'}->spawn();

    $self->playback_type(PLAYBACK_TYPE_MOVIE);

}

##
## stop()
##
## Stops the currently-playing movie.
##
sub stop {
    my ($self) = $_[OBJECT];

    # Stop if we're playing
    if ( $self->stream()->get_status() == XINE_STATUS_PLAY ) {
        $self->stream()->stop();
    }

    $self->clear_window();

}

sub clear_window {
    my $self = shift;

    $self->fullscreen()->clear();

    return;
}

##
## play_still()
##
## Arguments:
##   STILL_FILE: Filename of our stillstore.
##
## Responds to a 'play_still' request by playing a still frame. The
## stillframe will remain there until something replaces it.
##
sub play_still {
    my ( $self, $kernel, $heap, $still, $callback, $time ) =
      @_[ OBJECT, KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    my $log = $self->logger();
    if (   $self->stream()->get_status() == XINE_STATUS_PLAY
        && $self->playback_type() == PLAYBACK_TYPE_MOVIE )
    {
        $log->error("Attempted to show still '$still' while playing a movie");
        return;
    }
    $log->debug("Showing still '$still'");
    eval {
        # Clear the screen
        $self->clear_window();

        $self->fullscreen()->display_still( $still );
    };
    if ($@) {
        $log->error("Error displaying still '$still': $@");
        $callback->(PLAYBACK_ERROR) if $callback;
        return;
    }

    if ( defined $time ) {
        POE::Session->create(
            inline_states => {
                _start => sub {
                    $_[KERNEL]->delay( 'end_delay', $time );
                },
                end_delay => sub {
                    $log->debug("Still playback finished for '$still'");
                    $callback->( $still, PLAYBACK_OK );
                  }
            }
        );
    }

}

##
## play_music()
##
## Arguments:
##  ARG0 -- callback. What to call when the music's over.
##  ARG1 -- song file. Filename of the song to play.
##
## Responds to a 'play_music' request by playing a particular song.
## Logs a warning and does nothing if we tried to play music during a
## movie. If a song was already playing, lets it play, but substitutes
## the current callback.
##
sub play_music {
    my ( $self, $heap, $kernel, $callback, $song_file ) =
      @_[ OBJECT, HEAP, KERNEL, ARG0, ARG1 ];

    defined $callback or die "Must define callback!\n";

    defined $song_file or die "Must define song file!\n";

    # If there's a movie running, let it play
    if ( $self->get_status() == PLAYER_STATUS_PLAY ) {
        if ( $self->playback_type() == PLAYBACK_TYPE_MOVIE ) {
            $self->warn(
                "Attempted to play '$song_file' while a movie is playing");
            $callback->( $self->stream(), PLAYBACK_ERROR );
            return;
        }
        else {
            $heap->{'stream_queue'}->set_stop_handler($callback);
        }
    }
    else {
        $self->debug("Playing music file '$song_file'");
        $heap->{'stream_queue'}->clear_events();
        $self->stream()->open($song_file)
          or do {
            $self->warn("Unable to play '$song_file'");
            $callback->( $self->stream(), PLAYBACK_ERROR );
            return;
          };
        $self->stream()->play( 0, 0 );
        $heap->{'stream_queue'}->set_stop_handler($callback);
        $heap->{'stream_queue'}->spawn();
        $self->playback_type(PLAYBACK_TYPE_MUSIC);
    }
}

############################## Object Methods ################################

##
## spawn()
##
## Creates the appropriate Player session.
##
sub spawn {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => [
                qw(_start
                  play
                  play_still
                  play_music
                  stop
                  )
            ],
        ],
    );

}

##
## get_status()
##
## Returns one of:
##   PLAYER_STATUS_PLAY if a movie (or music) is playing
##   PLAYER_STATUS_STOP if nothing is playing.
##
sub get_status {
    my $self = shift;

    my $session = $poe_kernel->get_active_session();
    my $heap    = $session->get_heap();

    $self->stream()->get_status() == XINE_STATUS_PLAY
      and return PLAYER_STATUS_PLAY;

    return PLAYER_STATUS_STOP;
}

no Moo;

1;

__END__

=head1 NAME

Video::PlaybackMachine::Player - POE component to play movies

=head1 SYNOPSIS

  use Video::PlaybackMachine::Player;

  my $player = Video::PlaybackMachine::Player->new();

  # Start the Player session
  $player->spawn();

  # Then, in another session...
  $kernel->post('Player', 'play', sub { "Finished"; }, 0, 'mymovie.mp4');

  # Is the movie still running?
  print "Playing\n" if $player->get_status() == PLAYER_STATUS_PLAY;


=cut
