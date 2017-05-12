package Tibco::Rv::Event;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.12';


use Tibco::Rv::Msg;
use Tibco::Rv::Cm::Msg;
@CARP_NOT = qw/ Tibco::Rv::Msg Tibco::Rv::Cm::Msg /;
use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) =
      ( queue => $Tibco::Rv::Queue::DEFAULT, callback => sub { } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { queue => $params{queue}, id => undef }, $class;

   $self->{callback} = $params{callback};
   $self->{internal_nomsg_callback} = sub { $self->onEvent( ) };
   $self->{internal_msg_callback} =
      sub { $self->onEvent( Tibco::Rv::Msg->_adopt( shift ) ) };
   $self->{internal_cmmsg_callback} =
      sub { $self->onEvent( Tibco::Rv::Cm::Msg->_adopt( shift ) ) };

   return $self;
}


sub queue { return shift->{queue} }
sub callback { return shift->{callback} }


sub onEvent
{
   my ( $self, @args ) = @_;
   $self->{callback}->( @args );
}


# callback not supported
sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Event_DestroyEx( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Event - Base class for Tibco events

=head1 SYNOPSIS

   use base qw/ Tibco::Rv::Event /;

   sub new
   {
      # ...
      my ( $self ) =
         $proto->SUPER::new( queue => $queue, callback => $callback );
      # ...
   }

=head1 DESCRIPTION

Base class for Tibco Events -- Listeners, Timers, and IO events.  Don't
use this directly.

=head1 CONSTRUCTOR

=over 4

=item $self = $proto->SUPER::new( %args )

   %args:
      queue => $queue,
      callback => sub { ... }

Creates a C<Tibco::Rv::Event>, or more specifically, one of the Event
subclasses -- Listener, Timer, or IO, with queue $queue (defaults to
$Tibco::Rv::Queue::DEFAULT if not specified), and the given callback
(defaults to sub { } if not specified).

=back

=head1 METHODS

=over 4

=item $queue = $event->queue

Returns the queue on which events will be dispatched.

=item $callback = $event->callback

Returns the callback code reference.

=item $event->onEvent

=item $event->onEvent( $msg )

Trigger an event directly.  Subclasses determine which version will be
called.  L<Listener|Tibco::Rv::Listener> objects use the version with a
C<$msg> parameter, L<Timer|Tibco::Rv::Timer> and L<IO|Tibco::Rv::IO>
objects use the version with no paramters.

=item $event->DESTROY

Cancels interest in this event.  Called automatically when C<$event>
goes out of scope.  Calling DESTROY more than once has no effect.

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Listener>

=item L<Tibco::Rv::Timer>

=item L<Tibco::Rv::IO>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__


tibrv_status tibrvEvent_ResetTimerInterval( tibrvEvent event,
   tibrv_f64 interval );
tibrv_status tibrvcmEvent_SetExplicitConfirm( tibrvcmEvent cmListener ); 
tibrv_status tibrvcmEvent_ConfirmMsg( tibrvcmEvent cmListener,
   tibrvMsg message );


static void callback_perl_noargs( SV * callback )
{
   dSP;
   PUSHMARK( SP );
   perl_call_sv( callback, G_VOID | G_DISCARD );
}


static void callback_perl_msg( SV * callback, tibrvMsg message )
{
   dSP;

   ENTER;
   SAVETMPS;

   PUSHMARK( SP );
   tibrvMsg_Detach( message );
   XPUSHs( sv_2mortal( newSViv( (IV)message ) ) );
   PUTBACK;

   perl_call_sv( callback, G_VOID | G_DISCARD );

   FREETMPS;
   LEAVE;
}


/*
static void onEventDestroy( tibrvEvent event, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}
*/


/* no closure data here -- it gets closure data from constructor
 * so to support this, we'd have to store both callbacks in the closure
 * and have a "completionCallback" argument in constructor
 */
tibrv_status Event_DestroyEx( tibrvEvent event )
{
   return tibrvEvent_DestroyEx( event, NULL );
}


tibrv_status cmEvent_DestroyEx( tibrvcmEvent cmEvent,
   tibrv_bool cancelAgreements )
{
   return tibrvcmEvent_DestroyEx( cmEvent, cancelAgreements, NULL );
}


static void onEventMsg( tibrvEvent event, tibrvMsg message, void * closure )
{
   callback_perl_msg( (SV *)closure, message );
}


static void onEventCmMsg( tibrvcmEvent event, tibrvMsg message, void * closure )
{
   callback_perl_msg( (SV *)closure, message );
}


static void onEventNoMsg( tibrvEvent event, tibrvMsg message, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}


tibrv_status Event_CreateListener( SV * sv_event, tibrvQueue queue,
   SV * callback, tibrvTransport transport, const char * subject )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateListener( &event, queue, onEventMsg,
      transport, subject, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


tibrv_status Event_CreateTimer( SV * sv_event, tibrvQueue queue, SV * callback,
   tibrv_f64 interval )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateTimer( &event, queue, onEventNoMsg,
      interval, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


tibrv_status Event_CreateIO( SV * sv_event, tibrvQueue queue, SV * callback,
   tibrv_i32 socketId, tibrvIOType ioType )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateIO( &event, queue, onEventNoMsg,
      socketId, ioType, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


/*
 * BUG -- tibrv seems to pass back the event's closure data, not what
 * Queue_SetHook passed in (and then segfaults)
 */
static void onQueueEvent( tibrvQueue queue, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}


tibrv_status Queue_SetHook( tibrvQueue queue, SV * callback )
{
   tibrvQueueHook eventQueueHook = NULL;
   if ( SvOK( callback ) ) eventQueueHook = onQueueEvent;
   return tibrvQueue_SetHook( queue, eventQueueHook, callback );
}


static void onQueueDestroy( tibrvQueue queue, void * closure )
{
   SV * callback = (SV *)closure;
   callback_perl_noargs( callback );
   SvREFCNT_dec( callback );
}


tibrv_status Queue_DestroyEx( tibrvQueue queue, SV * callback )
{
   tibrvQueueOnComplete completionFn = NULL;
   if ( SvOK( callback ) )
   {
      completionFn = onQueueDestroy;
      SvREFCNT_inc( callback );
   }
   return tibrvQueue_DestroyEx( queue, completionFn, callback );
}


static void * onLedgerSubject( tibrvcmTransport cmTransport,
   const char * subject, tibrvMsg message, void * closure )
{
   tibrvMsg copy = NULL;
   tibrv_status status = tibrvMsg_CreateCopy( message, &copy );
   if ( status == TIBRV_OK ) callback_perl_msg( (SV *)closure, copy );
   return NULL;
}


tibrv_status cmTransport_ReviewLedger( tibrvcmTransport cmTransport,
   const char * subject, SV * callback )
{
   return tibrvcmTransport_ReviewLedger( cmTransport, onLedgerSubject, subject,
      callback );
}


tibrv_status cmEvent_CreateListener( SV * sv_event, tibrvQueue queue,
   SV * callback, tibrvcmTransport transport, const char * subject )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvcmEvent_CreateListener( &event, queue,
      onEventCmMsg, transport, subject, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


void Msg_GetCMValues( tibrvMsg message, SV * sv_CMSender, SV * sv_CMSequence,
   SV * sv_CMTimeLimit )
{
   const char * CMSender = NULL;
   tibrv_u64 CMSequence = 0;
   tibrv_f64 CMTimeLimit = 0.0;

   if ( tibrvMsg_GetCMSender( message, &CMSender ) == TIBRV_OK )
      sv_setpv( sv_CMSender, CMSender );
   if ( tibrvMsg_GetCMSequence( message, &CMSequence ) == TIBRV_OK )
      sv_setuv( sv_CMSequence, (UV)CMSequence );
   if ( tibrvMsg_GetCMTimeLimit( message, &CMTimeLimit ) == TIBRV_OK )
      sv_setnv( sv_CMTimeLimit, CMTimeLimit );
}
