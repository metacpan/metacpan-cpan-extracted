package Tibco::Rv::Timer;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.04';


@CARP_NOT = qw/ Tibco::Rv::Event /;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT, interval => 1,
      callback => sub { print "Timer fired\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   $self->{interval} = $params{interval};

   my ( $status ) = Tibco::Rv::Event::Event_CreateTimer( $self->{id},
      $self->{queue}{id}, $self->{internal_nomsg_callback},
      $self->{interval} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub interval
{
   my ( $self ) = shift;
   return @_ ? $self->resetTimerInterval( @_ ) : $self->{interval};
}


sub resetTimerInterval
{
   my ( $self, $interval ) = @_;
   my ( $status ) =
      Tibco::Rv::Event::tibrvEvent_ResetTimerInterval( $self->{id}, $interval );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{interval} = $interval;
}


1;


=pod

=head1 NAME

Tibco::Rv::Timer - Tibco Timer event object

=head1 SYNOPSIS

   my ( $timer ) = $rv->createTimer( interval => 10, sub
   {
      print "Timer event happened!\n";
   } );

   $timer->interval( 5 );

   $timer->onEvent( );

=head1 DESCRIPTION

A C<Tibco::Rv::Timer> fires an event after every specified interval.  It is
a subclass of L<Tibco::Rv::Event|Tibco::Rv::Event>, so Event methods are
available to Timers (documentation on Event methods are reproduced here for
convenience).

=head1 CONSTRUCTOR

=over 4

=item $timer = new Tibco::Rv::Timer( %args )

   %args:
      queue => $queue,
      interval => $interval,
      callback => sub { ... }

Creates a C<Tibco::Rv::Timer>.  If not specified, queue defaults to the
L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">, interval defaults to 1,
and callback defaults to:

   sub { print "Timer fired\n" }

Create a Timer to cause an event to fire after every C<$interval> seconds.
The C<$interval> can specify fractions of a second.  When C<$queue>
dispatches such an event, it triggers the given callback.

=back

=head1 METHODS

=over 4

=item $interval = $timer->interval

Returns the number of seconds in the interval between firings of the Timer's
event.

=item $timer->interval( $interval ) (or $timer->resetTimerInterval( $interval ))

Set the interval at which the next Timer event will be dispatched.

=item $queue = $timer->queue

Returns the queue on which this Timer's events will be dispatched.

=item $callback = $timer->callback

Returns the callback code reference.

=item $timer->onEvent

Trigger an event directly.  The event will be processed as if it was
triggered via the event queue.

=item $timer->DESTROY

Cancels the Timer.  Called automatically when C<$timer> goes out of scope.
Calling DESTROY more than once has no effect.

=back

=head1 OVERRIDING EVENT CALLBACK

As an alternative to passing in a callback function to the constructor, there
is another way to handle events.  You can subclass C<Tibco::Rv::Timer>
and override the onEvent method, as follows:

   package MyTimer;
   use base qw/ Tibco::Rv::Timer /;

   sub new
   {
      my ( $proto, %args ) = @_;
      my ( $self ) = $proto->SUPER::new( %args );
      # your initialization code
      return $self;
   }

   sub onEvent
   {
      my ( $self ) = @_;
      # process event here
      # $self->queue, $self->interval are available
   }

   # any other implementation code for your class

   1;

The C<Tibco::Rv::Event> onEvent method simply calls the callback, so
overriding onEvent allows you to process the event however you want, and
you can just not use the callback.

The advantages of this method of handling events are: it is more
object-oriented; you have access to the queue and interval via the C<$self>
accessor methods; and, you can have more elaborate processing of timed
events without having to shove it all into one callback.

You can use your subclassed Timer as follows:

   use Tibco::Rv;
   use MyTimer;

   my ( $rv ) = new Tibco::Rv;
   my ( $myTimer ) = new MyTimer( interval => 4 );
   $rv->start;

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
