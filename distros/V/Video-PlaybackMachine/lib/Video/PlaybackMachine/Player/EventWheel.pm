package Video::PlaybackMachine::Player::EventWheel;

our $VERSION = '0.09'; # VERSION

use Moo;

use POE;
use Video::Xine;
use Video::PlaybackMachine::Player;
use Video::Xine::Stream qw/:status_constants/;
use Video::Xine::Event qw/:type_constants/;

with 'Video::PlaybackMachine::Logger';

has 'stream' => ( is => 'ro', required => 1 );

has 'handlers' => ( is => 'rw', 'clear' => 1, 'default' => sub { {} } );

has 'queue' => ( is => 'lazy' );

has 'check_interval_secs' => ( 'is' => 'ro', default => 2 );

sub _build_queue {
	my $self = shift;
	
	return Video::Xine::Event::Queue->new( $self->stream() );
}

sub spawn {
  my $self = shift;
  my ($callback) = @_;

  POE::Session->create(
		       object_states => [$self=>[qw(_start get_events)]]
		      );
}

sub _start {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  $kernel->yield('get_events');
}


sub clear_events {
	my $self = shift;
		
	1 while $self->queue()->get_event();	
}

sub has_handler_for {
	my $self = shift;
	my ($event) = @_;
	
	return exists $self->handlers()->{$event->get_type()};
}

sub handler {
	my $self = shift;
	my ($event) = @_;
	
	return $self->handlers()->{ $event->get_type() };
}

sub call_handler {
	my $self = shift;
	my ($event) = @_;
	
    $self->debug("Invoking handler for ", $event->get_type(), "\n");

	my $handler = $self->handler($event)
		or return;
	
	return $handler->($self->stream(), $event)
}

sub get_events {
  my ($self, $heap, $kernel) = @_[OBJECT, HEAP, KERNEL];

  # Translate all events into callbacks
  while ( my $event = $self->queue()->get_event() ) {
    $self->debug("Received Xine event: ", $event->get_type(), "\n");
    if ( $event->get_type() == XINE_EVENT_UI_PLAYBACK_FINISHED ) {
      $self->stream()->close();
    }
    if ( $self->has_handler_for($event) ) {
      $self->call_handler($event);
    }
  }

  # Keep checking so long as we're playing
  if ( $self->stream()->get_status() == XINE_STATUS_PLAY ) {
    $kernel->delay('get_events', $self->check_interval_secs() );
  }
}

sub set_handler {
  my $self = shift;
  my ($event_type, $callback) = @_;
  $self->handlers()->{$event_type} = sub { $callback->($_[0], Video::PlaybackMachine::Player::PLAYBACK_OK() ) };
}


# Convenience method
sub set_stop_handler {
  $_[0]->set_handler(XINE_EVENT_UI_PLAYBACK_FINISHED, $_[1]);
}

no Moo;

1;

__END__

=head1 NAME

Video::PlaybackMachine::Player::EventWheel - Bridge between Player events and POE events

=head1 SYNOPSIS

  use Video::PlaybackMachine::Player::EventWheel;

  # Create an event wheel watching $stream
  my $wheel = Video::PlaybackMachine::Player::EventWheel->new($stream);

  # Clear out any previous events
  $wheel->clear_events();

  # Call a handler when the stream stops
  $wheel->set_stop_handler(sub { print "All done!\n"});

  # Start the session
  $wheel->spawn();
  

=head1 DESCRIPTION

When spawned, will pass along events from the given streams to the
appropriate callbacks.

=cut
