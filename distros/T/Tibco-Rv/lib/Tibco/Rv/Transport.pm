package Tibco::Rv::Transport;


use vars qw/ $VERSION $PROCESS /;
$VERSION = '1.12';


use constant PROCESS_TRANSPORT => 10;

use constant DEFAULT_BATCH => 0;
use constant TIMER_BATCH => 1;


use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


my ( %defaults );
BEGIN
{
   %defaults = ( service => '', network => '', daemon => 'tcp:7500',
      batchMode => DEFAULT_BATCH, description => undef );
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

   my ( @snd ) = qw/ service network daemon /;
   map { $params{$_} = '' unless ( defined $params{$_} ) } @snd;
   @$self{ @snd } = @params{ @snd };

   my ( $status ) = Transport_Create( @$self{ 'id', @snd } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->batchMode( $params{batchMode} )
      if ( $params{batchMode} != DEFAULT_BATCH );
   $self->description( $params{description} )
      if ( defined $params{description} );

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
   return bless $proto->_new( $id ), $proto unless ( $class );

   $proto->DESTROY;
   @$proto{ 'id', keys %defaults } = ( $id, values %defaults );
}


sub service { return shift->{service} }
sub network { return shift->{network} }
sub daemon { return shift->{daemon} }


sub send
{
   my ( $self, $msg ) = @_;
   my ( $status ) = tibrvTransport_Send( $self->{id}, $msg->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendReply
{
   my ( $self, $reply, $request ) = @_;
   my ( $status ) =
      tibrvTransport_SendReply( $self->{id}, $reply->{id}, $request->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendRequest
{
   my ( $self, $request, $timeout ) = @_;
   $timeout = Tibco::Rv::WAIT_FOREVER unless ( defined $timeout );
   my ( $reply );
   my ( $status ) =
      Transport_SendRequest( $self->{id}, $request->{id}, $reply, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg->_adopt( $reply ) : undef;
}


sub description
{
   my ( $self ) = shift;
   return @_ ? $self->_setDescription( @_ ) : $self->{description};
}


sub _setDescription
{
   my ( $self, $description ) = @_;
   $description = '' unless ( defined $description );
   my ( $status ) = tibrvTransport_SetDescription( $self->{id}, $description );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{description} = $description;
}


sub batchMode
{
   my ( $self ) = shift;
   return @_ ? $self->_setBatchMode( @_ ) : $self->{batchMode};
}


sub _setBatchMode
{
   my ( $self, $batchMode ) = @_;
   my ( $status ) = tibrvTransport_SetBatchMode( $self->{id}, $batchMode );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{batchMode} = $batchMode;
}


sub createInbox
{
   my ( $self ) = @_;
   my ( $inbox );
   my ( $status ) = Transport_CreateInbox( $self->{id}, $inbox );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $inbox;
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( defined $self->{id} );

   my ( $id ) = $self->{id};
   delete @$self{ keys %$self };
   return if ( $id == PROCESS_TRANSPORT );

   my ( $status ) = tibrvTransport_Destroy( $id );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


BEGIN { $PROCESS = Tibco::Rv::Transport->_adopt( PROCESS_TRANSPORT ) }


1;


=pod

=head1 NAME

Tibco::Rv::Transport - Tibco network transport object

=head1 SYNOPSIS

   $transport = new Tibco::Rv::Transport;
   $msg = $rv->createMessage;
   $msg->addString( abc => 123 );
   $transport->send( $msg );

=head1 DESCRIPTION

A C<Tibco::Rv::Transport> object represents a connection to a Rendezvous
daemon, which routes messages to other Tibco programs.

=head1 CONSTRUCTOR

=over 4

=item $transport = new Tibco::Rv::Transport( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon,
      description => $description,
      batchMode => $batchMode

Creates a C<Tibco::Rv::Transport>.  If not specified, service defaults to ''
(the rendezvous service), network defaults to '' (no network), and daemon
defaults to 'tcp:7500' (see your TIB/Rendezvous documentation for discussion
on the service/network/daemon parameters).  Description defaults to C<undef>,
and batchMode defaults to Tibco::Rv::Transport::DEFAULT_BATCH.  If Tibco::Rv
was built against an Rv 6.x version, then the constructor will die with a
Tibco::Rv::VERSION_MISMATCH Status message if you attempt to set batchMode
to anything other than Tibco::Rv::Transport::DEFAULT_BATCH.

=back

=head1 METHODS

=over 4

=item $service = $transport->service

Returns the service setting C<$transport> is connected to.

=item $network = $transport->network

Returns the network setting C<$transport> is connected to.

=item $daemon = $transport->daemon

Returns the daemon setting C<$transport> is connected to.

=item $description = $transport->description

Returns the description of C<$transport>.

=item $transport->description( $description )

Sets the description of C<$transport>.  Description identifies this transport
to TIB/Rendezvous components.  It is displayed in the browser administration
interface.

Although description defaults to C<undef>, if you try to set it to C<undef>,
it ends up being '' (this matches the behaviour of the C API, if you consider
Perl C<undef> to be equivalent to C NULL, and Perl '' to be equivalent to C
"").

=item $batchMode = $transport->batchMode

Returns the batchMode of C<$transport>.  If Tibco::Rv was built against
an Rv 6.x version, this method will always return
Tibco::Rv::Transport::DEFAULT_BATCH.

=item $transport->batchMode( $batchMode )

Sets the batchMode of C<$transport>.  See the L<Constants|"CONSTANTS">
section below for a discussion of the available batchModes.  If Tibco::Rv
was built against an Rv 6.x version, this method will die with a
Tibco::Rv::VERSION_MISMATCH Status message.

=item $transport->send( $msg )

Sends C<$msg> via C<$transport> on the subject specified by C<$msg>'s
sendSubject.

=item $reply = $transport->sendRequest( $request, $timeout )

Sends C<$request> (a L<Tibco::Rv::Msg|Tibco::Rv::Msg>) and waits for a reply
message.  This method blocks while waiting for a reply.  C<$timeout>
specifies how long it should wait for a reply.  Using
C<Tibco::Rv::WAIT_FOREVER> causes this method to wait indefinately for a
reply.

If C<$timeout> is not specified (or C<undef>), then this method uses
C<Tibco::Rv::WAIT_FOREVER>.

If C<$timeout> is something other than C<Tibco::Rv::WAIT_FOREVER> and that
timeout is reached before receiving a reply, then this method returns
C<undef>.

=item $transport->sendReply( $reply, $request )

Sends C<$reply> (a L<Tibco::Rv::Msg|Tibco::Rv::Msg>) in response to the
C<$request> message.  This method extracts the replySubject from C<$request>,
and uses it to send C<$reply>.

=item $inbox = $transport->createInbox

Returns a subject that is unique within C<$transport>'s domain.  If
C<$transport> is the L<Intra-Process Transport|"INTRA-PROCESS TRANSPORT">,
then $inbox is unique within this process; otherwise, $inbox is unique
across all processes within the local router domain.

Use createInbox to set up a subject for point-to-point communications.
That is, messages sent to this subject will go to a single destination.

createInbox should be used in conjunction with sendReply and sendRequest
to enable point-to-point communication, as follows:

On the replying end, create a listener that listens to some subject.  In
the callback of that listener, create a routine that sends a reply to
incoming requests via the sendReply method.

On the requesting end, create an inbox subject using createInbox.  Then,
create your request message, and use that message's replySubject method to
set the reply subject to be the inbox subject you just created.  Send that
request message via the transport's sendRequest method.  The sendRequest
method internally creates a listener and waits for the replying end to
send a reply.

=item $transport->DESTROY

Destroy this connection to a TIB/Rendezvous daemon after flushing all
outbound messages.  Events created with this transport are invalidated.
Called automatically when C<$transport> goes out of scope.  Calling
DESTROY more than once has no effect.

=back

=head1 CONSTANTS

=over 4

=item Tibco::Rv::Transport::DEFAULT_BATCH

Specifies that the transport should send outbound messages to the
TIB/Rendezvous daemon immediately.

=item Tibco::Rv::Transport::TIMER_BATCH

Specifies that the transport should accumulate outbound messages in a
buffer, and send them to the TIB/Rendezvous daemon when either the buffer is
full, or a timeout is reached (programs cannot change the timeout interval).

=back

=head1 INTRA-PROCESS TRANSPORT

The Intra-Process Transport is a special transport that is automatically
created when a new L<Tibco::Rv|Tibco::Rv> object is created.  It is available
as C<$Tibco::Rv::Transport::PROCESS>.  It can only be used to transport
messages within the process it was created in.  Internal advisory messages
are transported via this transport.

=head1 SEE ALSO

L<Tibco::Rv::Msg>

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__


tibrv_status tibrvTransport_SetDescription( tibrvTransport transport,
   const char * description );
tibrv_status tibrvTransport_Send( tibrvTransport transport, tibrvMsg message );
tibrv_status tibrvTransport_SendReply( tibrvTransport transport,
   tibrvMsg reply, tibrvMsg request );
#if TIBRV_VERSION_RELEASE < 7
typedef unsigned int tibrvTransportBatchMode;
#endif
tibrv_status tibrvTransport_SetBatchMode( tibrvTransport transport,
   tibrvTransportBatchMode mode );
tibrv_status tibrvTransport_Destroy( tibrvTransport transport );

#if TIBRV_VERSION_RELEASE < 7
tibrv_status tibrvTransport_SetBatchMode( tibrvTransport transport,
   tibrvTransportBatchMode mode )
{ return TIBRV_VERSION_MISMATCH; }
#endif


tibrv_status Transport_Create( SV * sv_transport, const char * service,
   const char * network, const char * daemon )
{
   tibrvTransport transport = (tibrvTransport)NULL;
   tibrv_status status =
      tibrvTransport_Create( &transport, service, network, daemon );
   sv_setiv( sv_transport, (IV)transport );
   return status;
}


tibrv_status Transport_SendRequest( tibrvTransport transport, tibrvMsg request,
   SV * sv_reply, tibrv_f64 timeout )
{
   tibrvMsg reply = (tibrvMsg)NULL;
   tibrv_status status =
      tibrvTransport_SendRequest( transport, request, &reply, timeout );
   sv_setiv( sv_reply, (IV)reply );
   return status;
}


tibrv_status Transport_CreateInbox( tibrvTransport transport, SV * sv_inbox )
{
   tibrv_u32 limit = TIBRV_SUBJECT_MAX + 1;
   char inbox[ limit ];
   tibrv_status status = tibrvTransport_CreateInbox( transport, inbox, limit );
   sv_setpv( sv_inbox, inbox );
   return status;
}
