package Tibco::Rv::Cm::Listener;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.12';


use constant CANCEL => 1;
use constant PERSIST => 0;


@CARP_NOT = qw/ Tibco::Rv::Event /;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT,
      transport => undef, subject => '',
      callback => sub { print "CmListener received: @_\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   @$self{ qw/ transport subject / } = @params{ qw/ transport subject / };

   my ( $status ) = Tibco::Rv::Event::cmEvent_CreateListener( $self->{id},
      $self->{queue}{id}, $self->{internal_cmmsg_callback},
      $self->{transport}{id}, $self->{subject} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub transport { return shift->{transport} }
sub subject { return shift->{subject} }


sub setExplicitConfirm
{
   my ( $self ) = @_;
   my ( $status ) =
      Tibco::Rv::Event::tibrvcmEvent_SetExplicitConfirm( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub confirmMsg
{
   my ( $self, $msg ) = @_;
   my ( $status ) =
      Tibco::Rv::Event::tibrvcmEvent_ConfirmMsg( $self->{id}, $msg->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


# callback not supported
sub DESTROY
{
   my ( $self, $cancelAgreements ) = @_;
   return unless ( exists $self->{id} );

   $cancelAgreements = PERSIST unless ( defined $cancelAgreements );
   my ( $status ) =
      Tibco::Rv::Event::cmEvent_DestroyEx( $self->{id}, $cancelAgreements );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

}


1;


=pod

=head1 NAME

Tibco::Rv::Cm::Listener - Tibco Certified Messaging Listener event object

=head1 SYNOPSIS

   my ( $cmt ) = $rv->createCmTransport( ... );
   my ( $listener ) =
      $rv->createCmListener( transport => $cmt, subject => 'ABC',
         callback => sub
   {
      my ( $msg ) = @_;
      print "Listener got a message: $msg, from sender: ", $msg->CMSender,
         ', sequence: ', $msg->CMSequence, "\n";
   } );

=head1 DESCRIPTION

A C<Tibco::Rv::Cm::Listener> monitors a subject for incoming messages and
passes those messages along to a callback.  It is a subclass of
L<Tibco::Rv::Event|Tibco::Rv::Event>, so Event methods are available to
Listeners (documentation on Event methods are reproduced here for
convenience).

Certified Messaging ensures that messages will be recieved exactly once and
in sequence.  See your TIB/Rendevous documentation for more information.

=head1 CONSTRUCTOR

=over 4

=item $listener = new Tibco::Rv::Cm::Listener( %args )

   %args:
      queue => $queue,
      transport => $transport,
      subject => $subject,
      callback => sub { ... }

Creates a C<Tibco::Rv::Cm::Listener>.  transport must be a
L<Tibco::Rv::Cm::Transport|Tibco::Rv::Cm::Transport>.  If not specified,
queue defaults to the L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">,
subject defaults to the empty string, and callback defaults to:

   sub { print "cmListener received: @_\n" }

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

=item $listener->DESTROY( $cancelAgreements )

Cancels interest in this event.  Called automatically when C<$listener>
goes out of scope.  Calling DESTROY more than once has no effect.
C<$cancelAgreements> defaults to PERSIST.

If C<$cancelAgreements> is PERSIST, certified delivery agreements are left
in effect, so senders will store messages.  If C<$cancelAgreements> is
CANCEL, certified delivery agreements are cancelled, causing senders to
delete all messages sent to this listener.

=item $listener->setExplicitConfirm

By default, certified listeners automatically confirm delivery when the
callback returns.  By calling setExplicitConfirm, this behaviour is
overridden.  Instead, you must explicitly confirm delivery by calling
confirmMsg.

=item $listener->confirmMsg( $msg )

Explicitly confirm delivery of C<$msg> (see setExplicitConfirm).

=back

=head1 CONSTANTS

=over 4

=item Tibco::Rv::Cm::Listener::CANCEL => 1

=item Tibco::Rv::Cm::Listener::PERSIST => 0

See DESTROY for usage of these constants.

=back

=head1 OVERRIDING EVENT CALLBACK

As an alternative to passing in a callback function to the constructor, there
is another way to handle events.  You can subclass C<Tibco::Rv::Cm::Listener>
and override the onEvent method, as follows:

   package MyListener;
   use base qw/ Tibco::Rv::Cm::Listener /;

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
   my ( $transport ) = new Tibco::Rv::Cm::Transport( ... );
   my ( $myListener ) =
      new MyListener( transport => $transport, subject => 'ABC' );
   $rv->start;

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
