package Video::PlaybackMachine::Scheduler;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::Scheduler
####
#### $Revision$
####
#### Plays movies in the ScheduleTable at the appropriate times.
####

use Moo;

use POE;
use POE::Session;
use Log::Log4perl;
use POSIX 'INT_MAX';

use Video::PlaybackMachine::Player qw(PLAYER_STATUS_PLAY);
use Video::PlaybackMachine::Config;

use Time::Duration;

use Carp;

############################# Class Constants #############################

use constant DEFAULT_SKIP_TOLERANCE => 30;

use constant DEFAULT_IDLE_TOLERANCE => 15;

our $Minimum_Fill = 7;

## Modes of operation

# Starting up, haven't played anything yet
use constant START_MODE => 0;

# Idle mode -- dead air
use constant IDLE_MODE => 1;

# Between scheduled content
use constant FILL_MODE => 2;

# Playing scheduled content
use constant PLAY_MODE => 3;

############################## Attributes ##############################

has 'schedule_table' => ( 'is' => 'ro' );

has 'player' => ( is => 'ro', builder => 1 );

has 'filler' => ( is => 'ro', required => 1 ) ;

has 'terminate_on_finish' => ( is => 'ro', 'default' => 1 );

has 'run_forever' => ( is => 'ro', 'default' => 0 );

has 'mode' => ( is => 'rw', default => START_MODE );

has 'offset' => ( is => 'ro', default => 0 );

has 'minimum_fill' => ( is => 'ro', default => 7 );

has 'logger' => ( is => 'ro', default => 
	sub {
		Log::Log4perl->get_logger('Video::Playback::Scheduler');
	}
);

############################# Object Methods ##############################

sub _build_player {
	my $self = shift;
	
	return Video::PlaybackMachine::Player->new();
}

sub spawn {
    my $self = shift;

    POE::Session->create(

        object_states => [
            $self => [
                qw(_start finished update play_scheduled warning_scheduled schedule_next shutdown wait_for_scheduled query_next_scheduled)
            ]
        ],
    );
}

# The schedule time.
sub time {
    my $self = shift;
    
    return CORE::time() + $self->offset();
}

##
## should_be_playing()
##
## Returns:
##
##   Video::PlaybackMachine::ScheduleEntry
##
## Returns the movie, if any, which should be playing right
## now.
##
sub should_be_playing {
    my $self = shift;

    my $current =
      scalar $self->schedule_table()->get_entry_during( $self->time() );

    return $current;
}

sub get_next_entry {
    my $self = shift;

    return
      scalar $self->schedule_table()->get_entries_after( $self->time(), 1 );

}

sub get_time_to_next {
    my $self = shift;
    
    my $next = $self->get_next_entry();

	# TODO The 'run_forever' business should probably be in the 
	# calling function, not down here
	if ( defined($next) ) {
        return $next->start_time() - $self->time();	
	}
	elsif ( $self->run_forever() ) {
        return INT_MAX;	
	}
    else {
    	return;
    }
}

############################# Session Methods #############################

##
## _start()
##
## POE startup state.
##
## Called when the session begins. Spawns off a player and filler session
## so that they can do whatever prep work they need to do, identifies
## this session as a scheduler, and checks the database for things
## that should be played.
##
sub _start {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    # Hang out a shingle
    $kernel->alias_set('Scheduler');

    # Set up our Player and our Filler
    $heap->{player_session} = $self->player->spawn();
    $heap->{filler_session} = $self->filler->spawn();
    
    $self->logger->info('Scheduler started');

    # Check the database for things that need playing
    $kernel->yield('update');

}

##
## query_next_scheduled()
##
## Designed to be called and return the next item on the schedule.
## Although this is a POE event handler, it's useful only when called
## with the call() command.
##
sub query_next_scheduled {
	my ($self, $num) = @_;
	
	$num //= 1;

    return
      $self->schedule_table()->get_entries_after( $self->time(), $num );

}

##
## update()
##
## POE state.
##
## Called whenever there's a change to the schedule
## and we need to make sure that the Scheduler's state
## matches what's in the database. Does NOT interrupt
## a running movie.
##
sub update {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    # Clear all schedule alarms
    $kernel->alarm('play_scheduled');
    $kernel->alarm('warning_scheduled');

    # If we're not playing
    if ( $self->mode() != PLAY_MODE ) {

        # If there's something supposed to be playing
        if ( my $entry = $self->should_be_playing() ) {

            $self->logger->debug("Time to play $entry");

            # Play it
            $kernel->yield( 'play_scheduled', $entry, $self->get_seek($entry) );
            return;

        }    # End if supposed to be playing

        # Otherwise, fill gap until next scheduled item
        else {
            $kernel->yield('wait_for_scheduled');
        }

    }    # End if we're not playing

    # Set alarm to play next scheduled item
    $kernel->delay( 'schedule_next', 5 );
}

##
## finished()
##
## POE state.
##
## Called whenever playback is finished. It checks to see if there is anything
## waiting for immediate play (i.e. was double-scheduled earlier) and plays it.
## Otherwise, sends us to fill mode.
##
## Until we enter fill or play mode, this method puts us into idle mode.
##
sub finished {
    my ( $self, $kernel, $request, $response ) =
      @_[ OBJECT, KERNEL, ARG0, ARG1 ];
      
    my $now = CORE::time();

    # If we've been running longer than the restart interval, restart the system
    my $config = Video::PlaybackMachine::Config->config();
    if ( $config->restart_interval() > 0 ) {
        if ( ( $now - $^T ) > $config->restart_interval() ) {
            $self->{'logger'}->info("Shutting down for restart");
            exit(0);
        }
    }

    # We're in idle mode now
    $self->{mode} = IDLE_MODE;

    # Log the item that finished playing
    $self->logger()->info("Movie played: ", $response->[0]);

	# If there's something else scheduled
	if ( defined $self->get_next_entry($now) ) {

		# If there's enough time to start filling
		if ( $self->get_time_to_next($now) > $self->{minimum_fill} ) {

			# Fill until next scheduled entry
			$kernel->yield('wait_for_scheduled');

		}    # End if enough time

		# Otherwise, go into idle mode till next
		else {

			$self->logger()->debug( "Not filling: "
				  . $self->get_time_to_next($now)
				  . " too short for fill (minimum $self->{'minimum_fill'})\n"
			);

			$self->mode(IDLE_MODE);

		}

	}    # End if something else scheduled

	# Otherwise, nothing scheduled; shut down.
	else {

		$kernel->yield('shutdown');

	}


}

sub warning_scheduled {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    # If we're in fill mode
    if ( $self->mode() == FILL_MODE ) {

        # Send a warning message to the Filler
        $kernel->post( 'Filler', 'warning', $self->get_time_to_next() );

    }    # End if we're in fill mode

    # Otherwise, do nothing; we do not interrupt scheduled content.

}

sub play_scheduled {
    my ( $self, $kernel, $session, $entry, $seek ) = @_[ OBJECT, KERNEL, SESSION, ARG0, ARG1 ];

    # If we're playing something scheduled
    if (   ( $self->mode() == PLAY_MODE )
        && ( $self->player()->get_status() == PLAYER_STATUS_PLAY ) )
    {
		$self->logger()->warn("Skipped playing " . $entry->mrl() . " since already playing");
		
        return;

    }    # End if we're playing something scheduled

    # Otherwise, we're ready to play
    else {

        # Tell the Filler to stop filling
        $kernel->post( 'Filler', 'stop' );

        # Mark that we're in play mode now
        $self->mode(PLAY_MODE);

        # Start playing the movie
        $kernel->post( 'Player', 'play',
            $session->postback( 'finished', $self, CORE::time() ),
            0, $entry->mrl );

        # Schedule the next item from the schedule table
        $kernel->delay( 'schedule_next', 3 );

    }    # End otherwise

}

sub wait_for_scheduled {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    defined $self->get_time_to_next()
      or $self->{'logger'}->logdie(
        "Called wait_for_scheduled with nothing to wait for; schedule time is "
          . scalar localtime( $self->time() ) );

    # If there's enough time before the next item to bother with fill
    if ( $self->get_time_to_next() > $self->{minimum_fill} ) {

        # Mark that we're in Fill mode
        $self->mode( FILL_MODE );

        # Tell our Filler to get to work
        $kernel->post( 'Filler', 'start_fill', $self );

    }    # End if enough time

    # Else not enough time
    else {

        # Go to Idle mode
        $self->mode( IDLE_MODE );

    }

}

sub schedule_next {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    # If there's something left in the schedule
    if ( my $entry = $self->get_next_entry() ) {

        # Set an alarm to play it
        my $alarm_offset = $entry->start_time() - $self->offset();
        my $in_time = $alarm_offset - CORE::time();

        ( $in_time >= 0 )
          or $self->logger()->logdie(
            "Attempt to schedule '",
            $entry->mrl(),
            "' in the past ($in_time) at ",
            scalar localtime $alarm_offset
          );

        $self->logger()->info( "scheduling: ", $entry->mrl(), " at ",
            scalar localtime($alarm_offset),
            " in ", duration($in_time) );
        $kernel->alarm( 'play_scheduled', $alarm_offset, $entry,
            0 );

    }    # End if there's something left

}

sub shutdown {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    # If we're supposed to quit
    if ( $self->terminate_on_finish() ) {

        # Pull in the shingle
        $kernel->alias_remove('Scheduler');

        # Terminate Player and Filler
        $kernel->post( $heap->{player_session}, 'shutdown' );
        $kernel->post( $heap->{filler_session}, 'shutdown' );

        # Stop watching for 'finished' events
        $kernel->state('finished');

        delete $heap->{$_} foreach keys %$heap;

        $kernel->alarm_remove_all();

        return;

    }    # End if we're supposed to quit

    # Otherwise we're supposed to put up a standby screen
    else {

        # Put up the standby screen
        warn "Putting up standby screen unimplemented...";

    }    # End otherwise

}

1;

=head1 NAME

Video::PlaybackMachine::Scheduler - Plays movies at the appropriate times
