package Tibco::Rv::Listener;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.04';


@CARP_NOT = qw/ Tibco::Rv::Event /;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT,
      transport => $Tibco::Rv::Transport::PROCESS, subject => '',
      callback => sub { print "Listener received: @_\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   @$self{ qw/ transport subject / } = @params{ qw/ transport subject / };

   my ( $status ) = Tibco::Rv::Event::Event_CreateListener( $self->{id},
      $self->{queue}{id}, $self->{internal_msg_callback},
      $self->{transport}{id}, $self->{subject} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub transport { return shift->{transport} }
sub subject { return shift->{subject} }


1;


=pod

=head1 NAME

Tibco::Rv::Listener - Tibco Listener event object

=head1 SYNOPSIS

   my ( $listener ) =
      $rv->createListener( subject => 'ABC', callback => sub
   {
      my ( $msg ) = @_;
      print "Listener got a message: $msg\n";
   } );

   my ( $msg ) = $rv->createMessage( field => 'value' );
   $listener->onEvent( $msg );

=head1 DESCRIPTION

A C<Tibco::Rv::Listener> monitors a subject for incoming messages and passes
those messages along to a callback.  It is a subclass of
L<Tibco::Rv::Event|Tibco::Rv::Event>, so Event methods are available to
Listeners (documentation on Event methods are reproduced here for
convenience).

=head1 CONSTRUCTOR

=over 4

=item $listener = new Tibco::Rv::Listener( %args )

   %args:
      queue => $queue,
      transport => $transport,
      subject => $subject,
      callback => sub { ... }

Creates a C<Tibco::Rv::Listener>.  If not specified, queue defaults to the
L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">, transport defaults to the
L<Intra-Process Transport|Tibco::Rv::Transport/"INTRA-PROCESS TRANSPORT">,
subject defaults to the empty string, and callback defaults to:

   sub { print "Listener received: @_\n" }

A program registers interest in C<$subject> by creating a Listener.  Messages
coming in on C<$subject> via C<$transport> are placed on the C<$queue>.
When C<$queue> dispatches such an event, it triggers the given callback.

=back

=head1 METHODS

=over 4

=item $transport = $listener->transport

Returns the transport via which Listener events are arriving.

=item $subject = $listener->subject

Returns the subject this Listener is listening on.

=item $queue = $listener->queue

Returns the queue on which this Listener's events will be dispatched.

=item $callback = $listener->callback

Returns the callback code reference.

=item $listener->onEvent( $msg )

Trigger an event directly by passing C<$msg> to the Listener.  The C<$msg>
will be processed as if it was triggered via the event queue.

=item $listener->DESTROY

Cancels interest in this event.  Called automatically when C<$listener>
goes out of scope.  Calling DESTROY more than once has no effect.

=back

=head1 OVERRIDING EVENT CALLBACK

As an alternative to passing in a callback function to the constructor, there
is another way to handle events.  You can subclass C<Tibco::Rv::Listener>
and override the onEvent method, as follows:

   package MyListener;
   use base qw/ Tibco::Rv::Listener /;

   sub new
   {
      my ( $proto, %args ) = @_;
      my ( $self ) = $proto->SUPER::new( %args );
      # your initialization code
      return $self;
   }

   sub onEvent
   {
      my ( $self, $msg ) = @_;
      # process $msg here
      # $self->queue, $self->transport, $self->subject are available
   }

   # any other implementation code for your class

   1;

The C<Tibco::Rv::Event> onEvent method simply passes the C<$msg> on to the
callback, so overriding onEvent allows you to process the C<$msg> however
you want, and you can just not use the callback.

The advantages of this method of handling events are: it is more
object-oriented; you have access to the transport, queue, and subject via
the C<$self> accessor methods; and, you can have more elaborate processing
of incoming messages without having to shove it all into one callback.

You can use your subclassed Listener as follows:

   use Tibco::Rv;
   use MyListener;

   my ( $rv ) = new Tibco::Rv;
   my ( $transport ) = new Tibco::Rv::Transport;
   my ( $myListener ) =
      new MyListener( transport => $transport, subject => 'ABC' );
   $rv->start;

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
