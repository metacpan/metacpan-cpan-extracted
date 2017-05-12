package Video::PlaybackMachine::EventWheel;

our $VERSION = '0.09'; # VERSION

use Moo::Role;
use POE;

has 'source' => (
	'is' => 'ro',
	'required' => 1
);

has 'handlers' => (
	'is' => 'ro',
	'default' => sub { return {} }
);

has 'logger' => (
	'is' => 'ro',
	'default' => sub { Log::Log4perl->get_logger('Video.PlaybackMachine.EventWheel') }
);

has 'check_interval_secs' => (
	'is' => 'ro',
	'default' => 3
);

requires 'get_event';

############################ Object Methods ############################


sub spawn {
  my $self = shift;
  my ($callback) = @_;

  POE::Session->create(
		       object_states => [$self=>[qw(_start get_events)]]
		      );
}

sub session_init {
  my $self = shift;
  my ($heap) = @_;

  # Initialize object and heap here for new session

}

sub session_cleanup {
  my $self = shift;
  my ($heap) = @_;

  # Do any required heap cleanup here
}

sub set_handler {
  my $self = shift;
  my ($event_id, $callback) = @_;
  
  $self->handlers->{$event_id} = $callback;
}

sub get_handler {
	my $self = shift;
	my ($event_type) = @_;
	
	return $self->handlers->{$event_type};
}

sub is_running {
  my $self = shift;

  # Put code here to determine whether to check for new events
  1;
}

############################ Session Methods ###########################



sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];

  $self->session_init($_[HEAP]);
  $kernel->yield('get_events');
}

sub get_events {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  # Translate all events into callbacks
  while ( my $event = $self->get_event($heap) ) {
    $self->logger->debug("Received event: ", $event->get_type(), "\n");
    if ( my $handler = $self->get_handler( $event->get_type() ) ) {
      $self->logger->debug("Invoking handler for ", $event->get_type(), "\n");
      $handler->($self->source(), $event);
    }
  }

  # Keep checking so long as we're playing
  if ( $self->is_running() ) {
    $kernel->delay( 'get_events', $self->check_interval_secs() );
  }
}

no Moo::Role;

1;
