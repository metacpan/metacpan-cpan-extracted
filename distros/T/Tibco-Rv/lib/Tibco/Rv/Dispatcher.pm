package Tibco::Rv::Dispatcher;


use vars qw/ $VERSION /;
$VERSION = '1.11';


use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( dispatchable => $Tibco::Rv::Queue::DEFAULT,
      idleTimeout => Tibco::Rv::WAIT_FOREVER, name => 'dispatcher' );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { id => undef, %params }, $class;

   my ( $status ) = Dispatcher_Create(
      $self->{id}, $self->{dispatchable}{id}, $self->{idleTimeout} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   $self->name( $params{name} ) if ( defined $params{name} );

   return $self;
}


sub dispatchable { return shift->{dispatchable} }
sub idleTimeout { return shift->{idleTimeout} }


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}


sub _setName
{
   my ( $self, $name ) = @_;
   $name = '' unless ( defined $name );
   my ( $status ) = tibrvDispatcher_SetName( $self->{id}, $name );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{name} = $name;
}


# blah -- tibrvDispatcher_Destroy gets called automatically when
# idleTimeout times out, or you can call it manually!
# how would the idleTimeout inform this object?  Listening on
# DISPATCHER.THREAD_EXITED?
sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = tibrvDispatcher_Destroy( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Dispatcher - Tibco Queue dispatching thread

=head1 SYNOPSIS

   $queue = $rv->createQueue;
   $dispatcher = new Tibco::Rv::Dispatcher( dispatchable => $queue );

=head1 DESCRIPTION

A C<Tibco::Rv::Dispatcher> object is an independent thread that repeatedly
dispatches events waiting on the specified dispatchable.  A dispatchable
is either a L<Tibco::Rv::Queue|Tibco::Rv::Queue> or a
L<Tibco::Rv::QueueGroup|Tibco::Rv::QueueGroup>.

=head1 CONSTRUCTOR

=over 4

=item $dispatcher = new Tibco::Rv::Dispatcher( %args )

   %args:
      dispatchable => $dispatchable,
      name => $name,
      idleTimeout => $idleTimeout

Creates a C<Tibco::Rv::Dispatcher>.  If not specified, dispatchable defaults
to the L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">, name defaults to
'dispatcher', and idleTimeout defaults to C<Tibco::Rv::WAIT_FOREVER>.

Upon creating C<$dispatcher>, it starts a separate thread, which repeatedly
calls C<timedDispatch> on C<$dispatchable>, passing it the C<$idleTimeout>
value.  The thread exits after C<$idleTimeout> seconds have passed without
any events being placed on the C<$dispatchable>.  C<$idleTimeout> can
specify fractional seconds.

If C<$idleTimeout> is C<Tibco::Rv::WAIT_FOREVER> (the default value), then
C<$dispatcher> continues dispatching events until DESTROY is called or the
program exits -- when no events are waiting on the C<$dispatchable> in this
case, C<$dispatcher> simply blocks.  If C<$idleTimeout> is
C<Tibco::Rv::NO_WAIT>, then C<$dispatcher> dispatches events until no
events are waiting on C<$dispatchable>, at which point the thread exits.

=back

=head1 METHODS

=over 4

=item $dispatchable = $dispatcher->dispatchable

Returns the L<Queue|Tibco::Rv::Queue> or L<QueueGroup|Tibco::Rv::QueueGroup>
that C<$dispatcher> is dispatching events on.

=item $idleTimeout = $dispatcher->dispatchable

Returns the idleTimeout value C<$dispatcher> is using to call C<timedDispatch>
on its dispatchable.

=item $name = $dispatcher->name

Returns the name of C<$dispatcher>.

=item $dispatcher->name( $name )

Sets C<$dispatcher>'s name to C<$name>.  Use this to distinguish multiple
dispatchers and assist troubleshooting.  If C<$name> is C<undef>, sets name
to ''.

=item $dispatcher->DESTROY

Exits the thread and destroys C<$dispatcher>.  Called automatically at
program exit.

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Queue>

=item L<Tibco::Rv::QueueGroup>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__

tibrv_status tibrvDispatcher_SetName( tibrvDispatcher dispatcher,
   const char * name );
tibrv_status tibrvDispatcher_Destroy( tibrvDispatcher dispatcher );


tibrv_status Dispatcher_Create( SV * sv_dispatcher,
   tibrvDispatchable dispatchable, tibrv_f64 idleTimeout )
{
   tibrvDispatcher dispatcher = (tibrvDispatcher)NULL;
   tibrv_status status = tibrvDispatcher_CreateEx( &dispatcher, dispatchable,
      idleTimeout );
   sv_setiv( sv_dispatcher, (IV)dispatcher );
   return status;
}
