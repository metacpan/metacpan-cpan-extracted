package Tibco::Rv::Queue;


use vars qw/ $VERSION $DEFAULT @CARP_NOT /;
$VERSION = '1.14';


use constant DEFAULT_QUEUE => 1;

use constant DISCARD_NONE => 0;
use constant DISCARD_NEW => 1;
use constant DISCARD_FIRST => 2;
use constant DISCARD_LAST => 3;

use constant DEFAULT_POLICY => 0;
use constant DEFAULT_PRIORITY => 1;


use Tibco::Rv::Listener;
use Tibco::Rv::Timer;
use Tibco::Rv::IO;
use Tibco::Rv::Cm::Listener;
use Tibco::Rv::Dispatcher;
@CARP_NOT = qw/ Tibco::Rv::Listener Tibco::Rv::Timer Tibco::Rv::IO
   Tibco::Rv::Cm::Listener Tibco::Rv::Dispatcher /;
use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


my ( @limitProperties, %defaults );
BEGIN
{
   @limitProperties = qw/ policy maxEvents discardAmount /;
   %defaults = ( policy => DEFAULT_POLICY, maxEvents => 0, discardAmount => 0,
      name => 'tibrvQueue', priority => DEFAULT_PRIORITY, hook => undef );
}


sub new
{
   my ( $proto ) = shift;
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $defaults{$_} ) } keys %args;
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Queue_Create( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->limitPolicy( @params{ qw/ policy maxEvents discardAmount / } )
      if ( $params{policy} != DISCARD_NONE or $params{maxEvents} != 0
         or $params{discardAmount} != 0 );
   $self->name( $params{name} ) if ( $params{name} ne 'tibrvQueue' );
   $self->priority( $params{priority} ) if ( $params{priority} != 1 );
   $self->hook( $params{hook} ) if ( defined $params{hook} );

   return $self;
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $id ) = @_;

   my ( $class ) = ref( $proto );
   return $proto->_new( $id ) unless ( $class );

   $proto->DESTROY; 
   @$proto{ 'id', keys %defaults } = ( $id, values %defaults );
}


sub createListener
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Listener( queue => $self, %args );
}


sub createTimer
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Timer( queue => $self, %args );
}


sub createIO
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::IO( queue => $self, %args );
}


sub createCmListener
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Cm::Listener( queue => $self, %args );
}


sub createDispatcher
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Dispatcher( dispatchable => $self, %args );
}


sub dispatch
{
   my ( $self ) = @_;
   $self->timedDispatch( Tibco::Rv::WAIT_FOREVER );
}


sub poll
{
   my ( $self ) = @_;
   return $self->timedDispatch( Tibco::Rv::NO_WAIT );
}


sub timedDispatch
{
   my ( $self, $timeout ) = @_;
   my ( $status ) = tibrvQueue_TimedDispatch( $self->{id}, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return new Tibco::Rv::Status( status => $status );
}


sub count
{
   my ( $self ) = @_;
   my ( $count );
   my ( $status ) = Queue_GetCount( $self->{id}, $count );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $count;
}


sub limitPolicy
{
   my ( $self ) = shift;
   return @_ ? $self->_setLimitPolicy( @_ ) : @$self{ @limitProperties };
}


sub _setLimitPolicy
{
   my ( $self, %policy );
   ( $self, @policy{ @limitProperties } ) = @_;
   my ( $status ) =
      tibrvQueue_SetLimitPolicy( $self->{id}, @policy{ @limitProperties } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return @$self{ @limitProperties } = @policy{ @limitProperties };
}


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}


sub _setName
{
   my ( $self, $name ) = @_;
   $name = '' unless ( defined $name );
   my ( $status ) = tibrvQueue_SetName( $self->{id}, $name );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{name} = $name;
}


sub priority
{
   my ( $self ) = shift;
   return @_ ? $self->_setPriority( @_ ) : $self->{priority};
}


sub _setPriority
{
   my ( $self, $priority ) = @_;
   my ( $status ) = tibrvQueue_SetPriority( $self->{id}, $priority );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{priority} = $priority;
}


sub hook
{
   my ( $self ) = shift;
   return @_ ? $self->_setHook( @_ ) : $self->{hook};
}


sub _setHook
{
   my ( $self, $hook ) = @_;
   die "hook not supported"; # see BUGS
   $self->{hook} = $hook;
   my ( $status ) =
      Tibco::Rv::Event::Queue_SetHook( $self->{id}, $self->{hook} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{hook};
}


sub DESTROY
{
   my ( $self, $callback ) = @_;
   return unless ( exists $self->{id} );

   my ( $id ) = $self->{id};
   delete @$self{ keys %$self };
   return if ( $id == DEFAULT_QUEUE );

   my ( $status ) = Tibco::Rv::Event::Queue_DestroyEx( $id, $callback );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


BEGIN { $DEFAULT = Tibco::Rv::Queue->_adopt( DEFAULT_QUEUE ) }


1;


=pod

=head1 NAME

Tibco::Rv::Queue - Tibco Queue event-managing object

=head1 SYNOPSIS

   $queue = new Tibco::Rv::Queue;

   $queue->name( 'myQueue' );

   $queue->createListener( subject => 'ABC', callback => sub { } );

   while ( 1 ) { $queue->dispatch }

=head1 DESCRIPTION

A C<Tibco::Rv::Queue> manages events waiting to be dispatched.

=head1 CONSTRUCTOR

=over 4

=item $queue = new Tibco::Rv::Queue( %args )

   %args:
      policy => $policy,
      maxEvents => $maxEvents,
      discardAmount => $discardAmount,
      name => $name,
      priority => $priority,
      hook => undef

Creates a C<Tibco::Rv::Queue>.  If not specified, policy defaults to
C<Tibco::Rv::Queue::DEFAULT_POLICY> (discard none), maxEvents defaults to
0 (unlimited), discardAmount defaults to 0, name defaults to 'tibrvQueue',
priority defaults to C<Tibco::Rv::Queue::DEFAULT_PRIORITY> (1), and hook
defaults to C<undef> (no hook).

The settings policy, maxEvents, and discardAmount are described under the
limitPolicy method.  The name setting is described under the name method,
priority is described under the priority method, and hook is described
under the hook method.

=back

=head1 METHODS

=over 4

=item $listener = $queue->createListener( %args )

   %args:
      transport => $transport,
      subject => $subject,
      callback => sub { ... }

Creates a L<Tibco::Rv::Listener|Tibco::Rv::Listener> with this C<$queue> as
the queue.  See the L<Listener constructor|Tibco::Rv::Listener/"CONSTRUCTOR">
for more details.

=item $timer = $queue->createTimer( %args )

   %args:
      interval => $interval,
      callbcak => sub { ... }

Creates a L<Tibco::Rv::Timer|Tibco::Rv::Timer> with this C<$queue> as the
queue.  See the L<Timer constructor|Tibco::Rv::Timer/"CONSTRUCTOR"> for more
details.

=item $io = $queue->createIO( %args )

   %args:
      socketId => $socketId,
      ioType => $ioType,
      callback => sub { ... }

Creates a L<Tibco::Rv::IO|Tibco::Rv::IO> with this C<$queue> as the queue.
See the L<IO constructor|Tibco::Rv::IO/"CONSTRUCTOR"> for more details.

=item $dispatcher = $queue->createDispatcher( %args )

   %args:
      name => $name,
      idleTimeout => $idleTimeout

Creates a L<Tibco::Rv::Dispatcher|Tibco::Rv::Dispatcher> with this C<$queue>
as the dispatchable.  See the
L<Dispatcher constructor|Tibco::Rv::Dispatcher/"CONSTRUCTOR"> for more
details.

=item $queue->dispatch

Dispatch a single event.  If there are no events currently on the queue,
then this method blocks until an event arrives.

=item $status = $queue->poll

Dispatch a single event if there is at least one event waiting on the queue.
If there are no events on the queue, then this call returns immediately.
Returns a Tibco::Rv::OK Status object if an event was dispatched, or
Tibco::Rv::TIMEOUT if there were no events on the queue.

=item $status = $queue->timedDispatch( $timeout )

Dispatches a single event if there is at least one event waiting on the
queue, or if an event arrives before C<$timeout> seconds have passed.  In
either case, returns Tibco::Rv::OK.  If C<$timeout> is reached before
dispatching an event, returns Tibco::Rv::TIMEOUT.  If Tibco::Rv::WAIT_FOREVER
is passed as C<$timeout>, behaves the same as C<dispatch>.  If
Tibco::Rv::NO_WAIT is passed as C<$timeout>, behaves the same as C<poll>.

=item $count = $queue->count

Returns the number of events waiting on the queue.

=item ( $policy, $maxEvents, $discardAmount ) = $queue->limitPolicy

=item $queue->limitPolicy( $policy, $maxEvents, $discardAmount )

Returns or sets the three limitPolicy parameters.  C<$policy> is described
in the L<Constants|"CONSTANTS"> section below.  C<$maxEvents> is the maximum
number of events allowed in the queue.  0 represents unlimited events.  If
C<$maxEvents> is greater than 0, then events are discarded according to the
other two limitPolicy parameters.  C<$discardAmount> is the number of events
to discard when C<$queue> reaches its C<$maxEvents> limit.

=item $name = $queue->name

Returns the name of C<$queue>.

=item $queue->name( $name )

Sets C<$queue>'s name to C<$name>.  The queue's name appears in advisory
messages concerning queues, so it should be set to a unique value in order
to assist troubleshooting.  If C<$name> is C<undef>, sets name to ''.

=item $priority = $queue->priority

Returns the C<$queue>'s priority.

=item $queue->priority( $priority )

Sets the C<$queue>'s priority.  Within a queue group, queues with higher
priorities have their events dispatched before queues with lower priorities.
The default setting is 1.  0 is the lowest possible priority.

=item $hook = $queue->hook

Returns the C<$queue>'s event arrival hook.

=item $queue->hook( sub { ... } )

Set the C<$queue>'s event arrival hook to the given sub reference.  This
hook is called every time an event is added to the queue.

=item $queue->DESTROY( $callback )

Destroys this queue and discards all events left on the queue.  If the
optional C<$callback> is specified, then it (which should be a sub
reference) will be called after all event callbacks currently being
dispatched from this queue finish.  Called automatically when C<$queue>
goes out of scope.  Calling DESTROY more than once has no effect.

=back

=head1 CONSTANTS

=over 4

=item Tibco::Rv::Queue::DISCARD_NONE => 0

=item Tibco::Rv::Queue::DISCARD_NEW => 1

=item Tibco::Rv::Queue::DISCARD_FIRST => 2

=item Tibco::Rv::Queue::DISCARD_LAST => 3

=item Tibco::Rv::Queue::DEFAULT_POLICY => 0

=item Tibco::Rv::Queue::DEFAULT_PRIORITY => 1

These constants control the queue's behaviour when it overflows and in how
different queues are dispatched relative to each other.

The DISCARD_* policies determine which events will be discarded when the
queue reaches its maxEvents limit (set by C<limitPolicy>).  DISCARD_NONE
should be used when the queue has no limit.  DISCARD_NEW causes the event
that would otherwise cause the queue to overflow its limit to be discarded.
DISCARD_FIRST causes the oldest event (the one that would otherwise be
dispatched next) to be discarded.  DISCARD_LAST casues the youngest event
to be discarded.

DEFAULT_PRIORITY is the default priority given to queues when they are
created.  Queues with higher priorities are dispatched before queues
with lower priorities, when multiple priorities are in the same queue group.

=back

=head1 DEFAULT QUEUE

The Default Queue is a queue that is automatically created when a new
L<Tibco::Rv|Tibco::Rv> object is created.  It is available as
C<$Tibco::Rv::Queue::DEFAULT>.  It never discards events and has a priority
of 1.  Advisories pertaining to queue overflow are placed on this queue.

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__

tibrv_status tibrvQueue_TimedDispatch( tibrvQueue queue, tibrv_f64 timeout );
tibrv_status tibrvQueue_SetLimitPolicy( tibrvQueue queue,
   tibrvQueueLimitPolicy policy, tibrv_u32 maxEvents, tibrv_u32 discardAmount );tibrv_status tibrvQueue_SetName( tibrvQueue queue, const char * name );
   tibrv_status tibrvQueue_SetPriority( tibrvQueue queue, tibrv_u32 priority );


tibrv_status Queue_Create( SV * sv_queue )
{
   tibrvQueue queue = (tibrvQueue)NULL;
   tibrv_status status = tibrvQueue_Create( &queue );
   sv_setiv( sv_queue, (IV)queue );
   return status;
}


tibrv_status Queue_GetCount( tibrvQueue queue, SV * sv_count )
{
   tibrv_u32 count;
   tibrv_status status = tibrvQueue_GetCount( queue, &count );
   sv_setuv( sv_count, (UV)count );
   return status;
}
