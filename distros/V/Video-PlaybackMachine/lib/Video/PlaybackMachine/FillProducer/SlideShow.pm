package Video::PlaybackMachine::FillProducer::SlideShow;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::FillProducer::SlideShow
####
#### $Revision$
####
#### Plays a bunch of random photos. Since we need to do things
#### at particular delay times, launches its own POE session.
####

use Moo;

use Carp;
use POE;
use Log::Log4perl;

use Video::PlaybackMachine::TimeLayout::GranularTimeLayout;
use Video::PlaybackMachine::Player qw(PLAYBACK_OK PLAYBACK_STOPPED);
use Video::PlaybackMachine::FillProducer::Chooser;

############################# Parameters #############################

has 'max_slides' => (
	'is' => 'ro',
	'default' => 5
);

has 'frame_chooser' => (
	is => 'lazy'
);

has 'time' => (
	is => 'ro',
	required => 1
);

has 'time_layout' => (
	is => 'lazy',
);

has 'directory' => (
	is => 'ro',
	required => 1
);

has 'music_directory' => (
	is => 'ro',
	required => 1
);

has 'music_chooser' => (
	is => 'lazy'
);

with 'Video::PlaybackMachine::FillProducer', 'Video::PlaybackMachine::Logger';


############################## Class Methods ##############################


############################# Object Methods ##############################

sub _build_time_layout {
	my $self = shift;

	return Video::PlaybackMachine::TimeLayout::GranularTimeLayout->new(
			$self->time(), $self->max_slides() 
	);
}

sub _build_frame_chooser {
	my $self = shift;
	
	return Video::PlaybackMachine::FillProducer::Chooser->new(
		DIRECTORY => $self->directory(),
	);

}

sub _build_music_chooser {
	my $self = shift;
	
	return Video::PlaybackMachine::FillProducer::Chooser->new(
			DIRECTORY => $self->music_directory(),
			FILTER    => qr/\.(mp3|wav|ogg)$/
		),

}

##
## has_audio()
##
## The slide show provides an audio track.
##
sub has_audio { return 1; }

##
## Slideshow is available if the directory exists
## and there are images in it.
##
sub is_available
{
	my $self = shift;

	return $self->frame_chooser()->is_available();

}

##
## show_slide()
##
## Displays a set of random still frames.
##
sub show_slide
{
	my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

	# If we have enough time to play another slide, call the player
	# to play it.
	my $time_played = ( time() - $heap->{'slide_start_time'} );
	if ( $heap->{planned_time} > $time_played )
	{
		my $frame = $self->{'frame_chooser'}->choose();
		$kernel->post( 'Player', 'play_still', $frame );
		$kernel->delay( 'show_slide', $self->{'time'} );
	}

	# Otherwise, cancel all slides and shut things down.
	# (The alarm cancel should be redundant.)
	else
	{
		$self->debug(
"Shutting down slideshow (time left=$time_played, $heap->{planned_time})"
		);
		$kernel->alarm_remove('show_slide');
		$kernel->state('show_slide');
		$kernel->state('next_song');
		$kernel->alarm_remove('next_song');
		$kernel->state('song_done');
		$kernel->alarm_remove('song_done');
		delete $heap->{'slide_start_time'};
		delete $heap->{'planned_time'};

		$kernel->yield('next_fill');
	}

}

##
## start()
##
## Starts the display of random still frames. Adds event handlers to
## the current session to show slides. Assumes that we're being called
## in a POE Filler session.
##
sub start
{
	my $self = shift;
	my ($planned_time) = @_;

	$self->debug("Starting slideshow");
	my $heap = $poe_kernel->get_active_session->get_heap();
	$heap->{'slide_start_time'} = time();
	$heap->{'planned_time'}     = $planned_time;
	$poe_kernel->state( 'show_slide', $self );
	$poe_kernel->state( 'next_song',  $self );
	$poe_kernel->state( 'song_done',  $self );
	$poe_kernel->yield('show_slide');
	$poe_kernel->yield('next_song');
}

sub next_song
{
	$_[OBJECT]->debug("Running next song");
	$_[KERNEL]->post(
		'Player', 'play_music',
		$_[SESSION]->postback('song_done'),
		$_[OBJECT]->music_chooser()->choose()
	);
}

sub song_done
{
	$_[OBJECT]->debug("Song done");
	my ( $stream, $status ) = @{ $_[ARG1] };
	if ( $status == PLAYBACK_OK() )
	{
		$_[OBJECT]->debug("Returned OK, playing next song");
		$_[KERNEL]->yield('next_song');
	}
	else
	{
		$_[OBJECT]->debug("'$status' Not OK, stopping");
		$_[KERNEL]->alarm('next_song');
	}
}

no Moo;

1;

