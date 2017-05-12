package Video::Xine::Event;
{
  $Video::Xine::Event::VERSION = '0.26';
}

use strict;
use warnings;

use Exporter;
our @ISA = 'Exporter';

our @EXPORT_OK = qw(
  XINE_EVENT_UI_PLAYBACK_FINISHED
  XINE_EVENT_UI_CHANNELS_CHANGED
  XINE_EVENT_UI_SET_TITLE
  XINE_EVENT_UI_MESSAGE
  XINE_EVENT_FRAME_FORMAT_CHANGE
  XINE_EVENT_AUDIO_LEVEL
  XINE_EVENT_QUIT
  XINE_EVENT_PROGRESS
  XINE_EVENT_MRL_REFERENCE
  XINE_EVENT_UI_NUM_BUTTONS
  XINE_EVENT_SPU_BUTTON
  XINE_EVENT_DROPPED_FRAMES
);

our %EXPORT_TAGS = 
  (
   type_constants => 
   [
    qw/
	    XINE_EVENT_UI_PLAYBACK_FINISHED
	    XINE_EVENT_UI_CHANNELS_CHANGED
	    XINE_EVENT_UI_SET_TITLE
	    XINE_EVENT_UI_MESSAGE
	    XINE_EVENT_FRAME_FORMAT_CHANGE
	    XINE_EVENT_AUDIO_LEVEL
	    XINE_EVENT_QUIT
	    XINE_EVENT_PROGRESS
	    XINE_EVENT_MRL_REFERENCE
	    XINE_EVENT_UI_NUM_BUTTONS
	    XINE_EVENT_SPU_BUTTON
	    XINE_EVENT_DROPPED_FRAMES
      /
   ]
  );

use constant {
  XINE_EVENT_UI_PLAYBACK_FINISHED   =>  1,
  XINE_EVENT_UI_CHANNELS_CHANGED    =>  2,
  XINE_EVENT_UI_SET_TITLE           =>  3,
  XINE_EVENT_UI_MESSAGE             =>  4,
  XINE_EVENT_FRAME_FORMAT_CHANGE    =>  5,
  XINE_EVENT_AUDIO_LEVEL            =>  6,
  XINE_EVENT_QUIT                   =>  7,
  XINE_EVENT_PROGRESS               =>  8,
  XINE_EVENT_MRL_REFERENCE          =>  9,
  XINE_EVENT_UI_NUM_BUTTONS         => 10,
  XINE_EVENT_SPU_BUTTON             => 11,
  XINE_EVENT_DROPPED_FRAMES         => 12
};

use Video::Xine;

sub get_type {
  xine_event_get_type($_[0]);
}

sub DESTROY {
  xine_event_free($_[0]);
}

1;

__END__

=head1 NAME

Video::Xine::Event -- An event emitted by Xine

=head1 SYNOPSIS

  use Video::Xine;
  use Video::Xine::Event qw/:type_constants/;
  use Video::Xine::Event::Queue;

  # $stream is a Video::Xine::Stream
  # We get events from an event queue
  my $queue = Video::Xine::Event::Queue->new($stream);

  my $event = $queue->get_event();

  # Announce if we dropped frames
  if ( $event->get_type() == XINE_EVENT_DROPPED_FRAMES ) {
    print "Dropped frames!";
  }


=head1 DESCRIPTION

Provides methods for accessing events that Xine generates.

=head1 EXPORTS

Exports all XINE_EVENT* constants in the tag ':type_constants'.

=head2 TYPE CONSTANTS

=over

=item *

XINE_EVENT_UI_PLAYBACK_FINISHED

=item *

XINE_EVENT_UI_CHANNELS_CHANGED

=item *

XINE_EVENT_UI_SET_TITLE

=item *

XINE_EVENT_UI_MESSAGE

=item *

XINE_EVENT_FRAME_FORMAT_CHANGE

=item *

XINE_EVENT_AUDIO_LEVEL

=item *

XINE_EVENT_QUIT

=item *

XINE_EVENT_PROGRESS

=item *

XINE_EVENT_MRL_REFERENCE

=item *

XINE_EVENT_UI_NUM_BUTTONS

=item *

XINE_EVENT_SPU_BUTTON

=item *

XINE_EVENT_DROPPED_FRAMES

=back

=head1 METHODS

=head3 get_type()

  $event->get_type()

Returns an integer indicating the event's type, which will be one of
the type constants.


=cut
