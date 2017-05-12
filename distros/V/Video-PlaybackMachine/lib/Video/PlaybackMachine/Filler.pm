package Video::PlaybackMachine::Filler;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::Filler
####
#### $Revision$
####
#### POE session for the Filler.
####

use Moo;

use Carp;

use POE;
use POE::Session;

use Time::Duration;

use Video::PlaybackMachine::TimeManager;

with 'Video::PlaybackMachine::Logger';

############################# Parameters #############################

has 'segments' => ( is => 'ro', default => sub { [] } );

has 'time_manager' => ( is => 'rw' );

has 'scheduler' => ( is => 'rw' );

############################# Object Methods ##############################

sub spawn {
  my $self = shift;

  POE::Session->create(
		       inline_states => {
					 _start => sub {
					   $_[KERNEL]->alias_set('Filler');
					 }
					},
		       object_states => [ $self => [
					 qw(start_fill fill_done next_fill short_ready stop)
					] ],
		       );

}


############################# Session Methods #############################

##
## start_fill()
##
## POE state.
##
## Called to start the Filler filling.
##
sub start_fill {
	my ($self, $heap, $kernel, $scheduler) = @_[OBJECT, HEAP, KERNEL, ARG0];


  # Initialize a TimeManager with our FillSegments
  $self->reset_time_manager();

  # Store the current schedule
  $self->scheduler($scheduler);

  $self->debug("Filling, ttn=", duration($_[ARG0]->get_time_to_next()),"\n");

  # View the first segment
  $kernel->yield('next_fill');

}

sub stop {
  $_[KERNEL]->alarm_remove_all();
  foreach (keys %{$_[HEAP]}) {
    delete $_[HEAP]->{$_};
  }
}

sub reset_time_manager {
	my ($self) = @_;
	
	$self->time_manager( 
		Video::PlaybackMachine::TimeManager
  			->new( @{ $self->segments } ) 
  		);
  	
  	return;
}

##
## fill_done()
##
## Called when the Filler has nothing else to play.
## Posts a call over to the Scheduler telling it
## that we're idle.
##
sub fill_done {
  $_[KERNEL]->alarm('next_fill');
  $_[KERNEL]->post('Scheduler', 'wait_for_scheduled');
}

##
## next_fill()
##
## Starts the next fill segment. If there are no more segments to be
## played, we're done.
##
sub next_fill {
	my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];
	
  $self->scheduler() 
    or $self->logconfess("Somehow called next_fill on us without calling start_fill");
    
  my $time_to_next = $self->scheduler()->get_time_to_next();
  
  if (! defined $time_to_next ) {
  	$kernel->yield('fill_done');
  	return;
  }
  
  $self->debug("Time to next: $time_to_next");

  my ($segment, $time) = $self->time_manager()->get_segment( $time_to_next  )
    or do {
      $kernel->yield('fill_done');
      return;
    };

  $self->debug("Starting fill segment name: ", $segment->name());

  $segment->producer()->start($time);

}

##
## short_ready()
##
## Is called when one of the producers wants the Filler to display
## moving pictures.
##
sub short_ready {
  $_[KERNEL]->post('Player', 
		   'play',
		   $_[SESSION]->postback('next_fill'),
		   0,
		   @_[ARG0 .. $#_]);

}

no Moo;


1;
