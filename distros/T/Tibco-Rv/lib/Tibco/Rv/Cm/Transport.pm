package Tibco::Rv::Cm::Transport;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.13';


use Tibco::Rv::Transport;
use Tibco::Rv::Msg;
use Tibco::Rv::Cm::Msg;
@CARP_NOT = qw/ Tibco::Rv::Transport Tibco::Rv::Msg Tibco::Rv::Cm::Msg /;
use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


my ( %defaults );
BEGIN
{
   %defaults = ( transport => undef, cmName => undef,
      requestOld => Tibco::Rv::FALSE, ledgerName => undef,
      syncLedger => Tibco::Rv::FALSE, relayAgent => undef,
      defaultCMTimeLimit => 0, publisherInactivityDiscardInterval => 0 );
}


sub new
{
   my ( $proto ) = shift;
   my ( %args ) = @_;
   $args{transport} = new Tibco::Rv::Transport( service => $args{service},
      network => $args{network}, daemon => $args{daemon} )
         unless ( exists $args{transport} and defined $args{transport} );
   delete @args{ qw/ service network daemon / };
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $defaults{$_} ) } keys %args;
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   @$self{ keys %defaults } = @params{ keys %defaults };

   my ( $status ) = cmTransport_Create( $self->{id}, $self->{transport}{id},
         @$self{ qw/ cmName requestOld ledgerName syncLedger relayAgent / } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->_getName unless ( defined $self->{cmName} );
   $self->defaultCMTimeLimit( $self->{defaultCMTimeLimit} )
      if ( $self->{defaultCMTimeLimit} != 0 );
   $self->publisherInactivityDiscardInterval(
      $params{publisherInactivityDiscardInterval} )
         if ( $params{publisherInactivityDiscardInterval} != 0 );

   return $self;
}


sub _getName
{
   my ( $self ) = @_;
   cmTransport_GetName( @$self{ qw/ id cmName / } );
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub name { return shift->{cmName} }
sub ledgerName { return shift->{ledgerName} }
sub relayAgent { return shift->{relayAgent} }
sub requestOld { return shift->{requestOld} }
sub syncLedger { return shift->{syncLedger} }
sub transport { return shift->{transport} }


sub defaultCMTimeLimit
{
   my ( $self ) = shift;
   return @_ ?
      $self->_setDefaultCMTimeLimit( @_ ) : $self->{defaultCMTimeLimit};
}


sub service { return shift->{transport}->service( @_ ) }
sub network { return shift->{transport}->transport( @_ ) }
sub daemon { return shift->{transport}->daemon( @_ ) }
sub description { return shift->{transport}->description( @_ ) }
sub batchMode { return shift->{transport}->batchMode( @_ ) }
sub createInbox { return shift->{transport}->createInbox( @_ ) }


sub _setDefaultCMTimeLimit
{
   my ( $self, $defaultCMTimeLimit ) = @_;
   my ( $status ) = tibrvcmTransport_SetDefaultCMTimeLimit(
      $self->{id}, $defaultCMTimeLimit );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{defaultCMTimeLimit} = $defaultCMTimeLimit;
}


sub send
{
   my ( $self, $msg ) = @_;
   my ( $status ) = tibrvcmTransport_Send( $self->{id}, $msg->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendReply
{
   my ( $self, $reply, $request ) = @_;
   my ( $status ) = tibrvcmTransport_SendReply( $self->{id},
      $reply->{id}, $request->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendRequest
{
   my ( $self, $request, $timeout ) = @_;
   $timeout = Tibco::Rv::WAIT_FOREVER unless ( defined $timeout );
   my ( $reply );
   my ( $status ) =
      cmTransport_SendRequest( $self->{id}, $request->{id}, $reply, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Cm::Msg->_adopt( $reply ) : undef;
}


sub addListener
{
   my ( $self, $cmName, $subject ) = @_;
   my ( $status ) =
      tibrvcmTransport_AddListener( $self->{id}, $cmName, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::NOT_PERMITTED );
   return new Tibco::Rv::Status( status => $status );
}


sub allowListener
{
   my ( $self, $cmName ) = @_;
   my ( $status ) = tibrvcmTransport_AllowListener( $self->{id}, $cmName );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub disallowListener
{
   my ( $self, $cmName ) = @_;
   my ( $status ) = tibrvcmTransport_DisallowListener( $self->{id}, $cmName );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub removeListener
{
   my ( $self, $cmName, $subject ) = @_;
   my ( $status ) =
      tibrvcmTransport_RemoveListener( $self->{id}, $cmName, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_SUBJECT );
   return new Tibco::Rv::Status( status => $status );
}


sub removeSendState
{
   my ( $self, $subject ) = @_;
   my ( $status ) = tibrvcmTransport_RemoveSendState( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sync
{
   my ( $self ) = @_;
   my ( $status ) = tibrvcmTransport_SyncLedger( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub reviewLedger
{
   my ( $self, $subject, $callback ) = @_;
   my ( $status ) = Tibco::Rv::Event::cmTransport_ReviewLedger( $self->{id},
      $subject, sub { $callback->( Tibco::Rv::Msg->_adopt( shift ) ) } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub connectToRelayAgent
{
   my ( $self ) = @_;
   my ( $status ) = tibrvcmTransport_ConnectToRelayAgent( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub disconnectFromRelayAgent
{
   my ( $self ) = @_;
   my ( $status ) = tibrvcmTransport_DisconnectFromRelayAgent( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub publisherInactivityDiscardInterval
{
   my ( $self ) = shift;
   return @_ ? $self->_setPublisherInactivityDiscardInterval( @_ )
      : $self->{publisherInactivityDiscardInterval};
}


sub _setPublisherInactivityDiscardInterval
{
   my ( $self, $timeout ) = @_;
   my ( $status ) = tibrvcmTransport_SetPublisherInactivityDiscardInterval(
      $self->{id}, $timeout );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{publisherInactivityDiscardInterval} = $timeout;
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( defined $self->{id} );

   my ( $status ) = tibrvcmTransport_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Cm::Transport - Tibco Certified Messaging transport object

=head1 SYNOPSIS

   my ( $cmt ) = $rv->createCmTransport( cmName => 'cmlisten',
      ledgerName => 'cmlisten.ldg', requestOld => Tibco::Rv::TRUE );
   $rv->createCmListener( subject => 'FOO', transport => $cmt, callback => sub
   {
      my ( $msg ) = shift;
      print "Message from ", $msg->CMSender, '/', $msg->CMSequence, ": $msg\n";
   } );

=head1 DESCRIPTION

A C<Tibco::Rv::Cm::Transport> object represents a connection to a Rendezvous
daemon, which routes messages to other Tibco programs.  With Certified
Messaging, each message is guaranteed to be delievered exactly once and in
sequence.

=head1 CONSTRUCTOR

=over 4

=item $transport = new Tibco::Rv::Cm::Transport( %args )

   %args:
      transport => $transport,
      service => $service,
      network => $network,
      daemon => $daemon,
      cmName => $cmName,
      requestOld => $requestOld,
      ledgerName => $ledgerName,
      syncLedger => $syncLedger,
      relayAgent => $relayAgent,
      defaultCMTimeLimit => $defaulCMTimeLimit,
      publisherInactivityDiscardInterval => $publisherInactivityDiscardInterval

Creates a C<Tibco::Rv::Cm::Transport>.  If not specified, requestOld defaults
to Tibco::Rv::FALSE, syncLedger defaults to Tibco::Rv::FALSE,
defaultCMTimeLimit defaults to 0 (no time limit), and
publisherInactivityDiscardInterval defaults to 0 (no time limit).  If transport
is not specified, a new transport is created using the given
service/network/daemon parameters (which default as usual).

cmName is the certified messaging correspondent name.  If cmName is C<undef>,
then a unique, non-reusable name is generated for the duration of the object.
If cmName is specified, it becomes a persistent correspondent identified by
this name.

If requestOld is Tibco::Rv::TRUE, then unacknowledged messages sent to
this persistent correspondent name will be re-requested from senders.  If
it is Tibco::Rv::TRUE, senders will not retain unacknowledged messages
in their ledger files.

If ledgerName is specified, then this transport will use a file-based
ledger by that name.  Otherwise, a process-based ledger will be used.

If syncLedger is Tibco::Rv::TRUE, operations that update the ledger file
will not return until changes are written out to the storage medium.  If it
is Tibco::Rv::TRUE, the operating system writes changes to the disk
asynchronously.

If relayAgent is specified, the transport will connect to the given rvrad.

defaultCMTimeLimit is the number of seconds a certified sender is guaranteed
to retain the message.  It may be overridden for each message.  A time limit
of 0 represents no time limit.

See your TIB/Rendezvous documentation for more information about
publisherInactivityDiscardInterval, which was introduced in tibrv 7.3.  If
Tibco::Rv was built against a version prior to 7.3, then the constructor
will die with a Tibco::Rv::VERSION_MISMATCH Status message if you attempt
to set publisherInactivityDiscardInterval to anything other than 0.

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

=item $batchMode = $transport->batchMode

Returns the batchMode of C<$transport>.  If Tibco::Rv was built against
an Rv 6.x version, this method will always return
Tibco::Rv::Transport::DEFAULT_BATCH.

=item $transport->batchMode( $batchMode )

Sets the batchMode of C<$transport>.  See the
L<Constants|Tibco::Rv::Transport/"CONSTANTS"> section for a discussion of
the available batchModes.  If Tibco::Rv was built against an Rv 6.x version,
this method will die with a Tibco::Rv::VERSION_MISMATCH Status message.

=item $name = $transport->name

Returns the correspondent name of C<$transport>.

=item $ledgerName = $transport->ledgerName

Returns the ledger name of C<$transport>, or C<undef> if not using a
file-based ledger.

=item $relayAgent = $transport->relayAgent

Returns the relay agent of C<$transport>, or C<undef> if not using a
a relay agent.

=item $requestOld = $transport->requestOld

Returns the requestOld flag of C<$transport>.

=item $syncLedger = $transport->syncLedger

Returns the syncLedger flag of C<$transport>.

=item $transport = $transport->transport

Returns the underlying L<Tibco::Rv::Transport|Tibco::Rv::Transport> object
used by C<$transport>, a Tibco::Rv::Cm::Transport object.

=item $defaultCMTimeLimit = $transport->defaultCMTimeLimit

Returns the default certified messaging time limit C<$transport> will use
for messages that otherwise do not have a time limit assigned.

=item $transport->defaultCMTimeLimit( $defaultCMTimeLimit )

Set the default certified messaging time limit for C<$transport>.

=item $interval = $transport->publisherInactivityDiscardInterval

Returns the publisherInactivityDiscardInterval of C<$transport>.  See your
TIB/Rendezvous documentation for more information about
publisherInactivityDiscardInterval, which was introduced in tibrv 7.3.  If
Tibco::Rv was built against a version prior to 7.3, this method will always
return 0.

=item $transport->publisherInactivityDiscardInterval( $interval )

See your TIB/Rendezvous documentation for more information about
publisherInactivityDiscardInterval, which was introduced in tibrv 7.3.  If
Tibco::Rv was built against a version prior to 7.3, this method will die
with a Tibco::Rv::VERSION_MISMATCH Status message.

=item $transport->send( $msg )

Sends C<$msg> via C<$transport> on the subject specified by C<$msg>'s
sendSubject.

=item $reply = $transport->sendRequest( $request, $timeout )

Sends C<$request> (a L<Tibco::Rv::Cm::Msg|Tibco::Rv::Cm::Msg>) and waits
for a reply message.  This method blocks while waiting for a reply.
C<$timeout> specifies how long it should wait for a reply.  Using
Tibco::Rv::WAIT_FOREVER causes this method to wait indefinately for a
reply.

If C<$timeout> is not specified (or C<undef>), then this method uses
Tibco::Rv::WAIT_FOREVER.

If C<$timeout> is something other than Tibco::Rv::WAIT_FOREVER and that
timeout is reached before receiving a reply, then this method returns
C<undef>.

=item $transport->sendReply( $reply, $request )

Sends C<$reply> (a L<Tibco::Rv::Cm::Msg|Tibco::Rv::Cm::Msg>) in response to the
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

=item $status = $transport->addListener( $cmName, $subject )

Pre-register an anticipated listener named C<$cmName> on the given subject,
so that certified messages sent on that subject will be stored in
C<$transport>'s ledger.  Returns Tibco::Rv::NOT_PERMITTED if C<$cmName>
has been disallowed by a call to disallowListener, otherwise returns
Tibco::Rv::OK.

=item $status = $transport->removeListener( $cmName, $subject )

Unregister the listener listening on C<$subject> at correspondent named
C<$cmName>, and free associated storage in C<$transport>'s ledger.  Returns
Tibco::Rv::INVALID_SUBJECT if the correspondent named C<$cmName> does not
receive certified delivery onC<$subject>, otherwise returns Tibco::Rv::OK.

=item $transport->disallowListener( $cmName )

Cancel certified delivery to all listeners at correspondent named C<$cmName>,
and refuse subsequent certified delivery requests from that correspondent.

=item $transport->allowListener( $cmName )

Allow future certified delivery requests from correspondent named C<$cmName>,
cancelling the effect of a previous call to disallowListener.

=item $transport->removeSendState( $subject )

Remove send state for given subject in C<$transport>'s ledger file.

=item $status = $transport->sync

Synchronize C<$transport>'s ledger file to its storage medium.  Returns
Tibco::Rv::INVALID_ARG if C<$transport> does not have a ledger file,
otherwise returns Tibco::Rv::OK.

=item $transport->reviewLedger( $subject, $callback )

Subject information from C<$transport>'s ledger file matching the given subject
are passed to the given callback, which must be a subroutine reference
(C<sub { ... }>).  The callback is called once for each subject that matches
C<$subject> (i.e., wildcards are allowed).

The subject information is passed to the callback as a
L<Tibco::Rv::Msg|Tibco::Rv::Msg>.  See your TIB/Rendezvous documentation for
more information on the fields in the Msg and what they mean.

=item $status = $transport->connectToRelayAgent

Connect C<$transport> to its designated relay agent.  Returns
Tibco::Rv::INVALID_ARG if C<$transport> does not have a designated relay
agent (otherwise returns Tibco::Rv::OK).

=item $status = disconnectFromRelayAgent

Disconnects C<$transport> from its designated relay agent.  Returns
Tibco::Rv::INVALID_ARG if C<$transport> does not have a designated relay
agent (otherwise returns Tibco::Rv::OK).

=item $transport->DESTROY

Destroy this connection to a TIB/Rendezvous daemon after flushing all
outbound messages.  Events created with this transport are invalidated.
Called automatically when C<$transport> goes out of scope.  Calling
DESTROY more than once has no effect.

=back

=head1 SEE ALSO

L<Tibco::Rv::Transport>

L<Tibco::Rv::Cm::Msg>

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__


tibrv_status tibrvcmTransport_Destroy( tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_SetDefaultCMTimeLimit(
tibrvcmTransport cmTransport, tibrv_f64 timeLimit );
tibrv_status tibrvcmTransport_Send( tibrvcmTransport cmTransport,
   tibrvMsg message );
tibrv_status tibrvcmTransport_SendReply( tibrvcmTransport cmTransport,
   tibrvMsg reply, tibrvMsg request );
tibrv_status tibrvcmTransport_AddListener( tibrvcmTransport cmTransport,
   const char * cmName, const char * subject );
tibrv_status tibrvcmTransport_AllowListener( tibrvcmTransport cmTransport,
   const char * cmName );
tibrv_status tibrvcmTransport_DisallowListener( tibrvcmTransport cmTransport,
   const char * cmName );
tibrv_status tibrvcmTransport_RemoveListener( tibrvcmTransport cmTransport,
   const char * cmName, const char * subject );
tibrv_status tibrvcmTransport_ConnectToRelayAgent(
   tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_DisconnectFromRelayAgent(
   tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_RemoveSendState( tibrvcmTransport cmTransport,
   const char * subject );
tibrv_status tibrvcmTransport_SyncLedger( tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_SetPublisherInactivityDiscardInterval(
tibrvcmTransport cmTransport, tibrv_i32 timeout );
#if TIBRV_VERSION_RELEASE < 7 || ( TIBRV_VERSION_RELEASE == 7 && TIBRV_VERSION_MINOR < 3 )
tibrv_status tibrvcmTransport_SetPublisherInactivityDiscardInterval(
   tibrvcmTransport cmTransport, tibrv_i32 timeout )
{ return TIBRV_VERSION_MISMATCH; }
#endif


tibrv_status cmTransport_Create( SV * sv_cmTransport, tibrvTransport transport,
   SV * sv_cmName, tibrv_bool requestOld, SV * sv_ledgerName,
   tibrv_bool syncLedger, SV * sv_relayAgent )
{
   const char * cmName = NULL;
   const char * ledgerName = NULL;
   const char * relayAgent = NULL;
   tibrvcmTransport cmTransport = (tibrvcmTransport)NULL;
   tibrv_status status;

   if ( SvOK( sv_cmName ) ) cmName = SvPV( sv_cmName, PL_na );
   if ( SvOK( sv_ledgerName ) ) ledgerName = SvPV( sv_ledgerName, PL_na );
   if ( SvOK( sv_relayAgent ) ) relayAgent = SvPV( sv_relayAgent, PL_na );

   status = tibrvcmTransport_Create( &cmTransport, transport, cmName,
      requestOld, ledgerName, syncLedger, relayAgent );
   sv_setiv( sv_cmTransport, (IV)cmTransport );
   return status;
}


void cmTransport_GetName( tibrvcmTransport cmTransport, SV * sv_cmName )
{
   const char * cmName;
   tibrvcmTransport_GetName( cmTransport, &cmName );
   sv_setpv( sv_cmName, cmName );
}


tibrv_status cmTransport_SendRequest( tibrvcmTransport cmTransport,
   tibrvMsg request, SV * sv_reply, tibrv_f64 timeout )
{
   tibrvMsg reply = (tibrvMsg)NULL;
   tibrv_status status =
      tibrvcmTransport_SendRequest( cmTransport, request, &reply, timeout );
   sv_setiv( sv_reply, (IV)reply );
   return status;
}
