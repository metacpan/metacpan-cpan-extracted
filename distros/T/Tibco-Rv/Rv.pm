package Tibco::Rv;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.15';


use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


use Carp;

use constant OK => 0;

use constant INIT_FAILURE => 1;
use constant INVALID_TRANSPORT => 2;
use constant INVALID_ARG => 3;
use constant NOT_INITIALIZED => 4;
use constant ARG_CONFLICT => 5;

use constant SERVICE_NOT_FOUND => 16;
use constant NETWORK_NOT_FOUND => 17;
use constant DAEMON_NOT_FOUND => 18;
use constant NO_MEMORY => 19;
use constant INVALID_SUBJECT => 20;
use constant DAEMON_NOT_CONNECTED => 21;
use constant VERSION_MISMATCH => 22;
use constant SUBJECT_COLLISION => 23;
use constant VC_NOT_CONNECTED => 24;

use constant NOT_PERMITTED => 27;

use constant INVALID_NAME => 30;
use constant INVALID_TYPE => 31;
use constant INVALID_SIZE => 32;
use constant INVALID_COUNT => 33;

use constant NOT_FOUND => 35;
use constant ID_IN_USE => 36;
use constant ID_CONFLICT => 37;
use constant CONVERSION_FAILED => 38;
use constant RESERVED_HANDLER => 39;
use constant ENCODER_FAILED => 40;
use constant DECODER_FAILED => 41;
use constant INVALID_MSG => 42;
use constant INVALID_FIELD => 43;
use constant INVALID_INSTANCE => 44;
use constant CORRUPT_MSG => 45;

use constant TIMEOUT => 50;
use constant INTR => 51;

use constant INVALID_DISPATCHABLE => 52;
use constant INVALID_DISPATCHER => 53;

use constant INVALID_EVENT => 60;
use constant INVALID_CALLBACK => 61;
use constant INVALID_QUEUE => 62;
use constant INVALID_QUEUE_GROUP => 63;

use constant INVALID_TIME_INTERVAL => 64;

use constant INVALID_IO_SOURCE => 65;
use constant INVALID_IO_CONDITION => 66;
use constant SOCKET_LIMIT => 67;

use constant OS_ERROR => 68;

use constant INSUFFICIENT_BUFFER => 70;
use constant EOF => 71;
use constant INVALID_FILE => 72;
use constant FILE_NOT_FOUND => 73;
use constant IO_FAILED => 74;

use constant NOT_FILE_OWNER => 80;

use constant TOO_MANY_NEIGHBORS => 90;
use constant ALREADY_EXISTS => 91;

use constant PORT_BUSY => 100;

use constant SUBJECT_MAX => 255;
use constant SUBJECT_TOKEN_MAX => 127;

use constant FALSE => 0;
use constant TRUE => 1;

use constant WAIT_FOREVER => -1.0;
use constant NO_WAIT => 0.0;


use Tibco::Rv::Status;
use Tibco::Rv::QueueGroup;
use Tibco::Rv::Cm::Transport;
@CARP_NOT =
   qw/ Tibco::Rv::Status Tibco::Rv::QueueGroup Tibco::Rv::Cm::Transport /;


sub die
{
   my ( $status ) = @_;
   $status = new Tibco::Rv::Status( status => $status )
      unless ( UNIVERSAL::isa( $status, 'Tibco::Rv::Status' ) );
   local( $Carp::CarpLevel ) = 1;
   croak 0+$status . ": $status\n";
}


sub version
{
   return 'tibrv ' . tibrv_Version( ) . '; tibrvcm ' . tibrvcm_Version( ) .
      "; Tibco::Rv $VERSION";
}


sub new
{
   my ( $proto ) = shift;
   my ( %params ) =
      ( service => undef, network => undef, daemon => 'tcp:7500' );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { processTransport => $Tibco::Rv::Transport::PROCESS,
      queue => $Tibco::Rv::Queue::DEFAULT, stop => 1, created => 1 }, $class;

   my ( $status ) = tibrv_Open( );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->{transport} = $self->createTransport( %params );
   $self->{queueGroup} = new Tibco::Rv::QueueGroup;
   $self->{queueGroup}->add( $self->{queue} );

   return $self;
}


sub processTransport { return shift->{processTransport} }
sub transport { return shift->{transport} }
sub defaultQueue { return shift->{queue} }
sub defaultQueueGroup { return shift->{queueGroup} }


sub start
{
   my ( $self ) = @_;
   $self->{stop} = 0;
   $SIG{TERM} = $SIG{KILL} = sub { $self->stop };
   $self->{queueGroup}->dispatch until ( $self->{stop} );
}


sub stop
{
   my ( $self ) = @_;
   $self->{stop} = 1;
}


sub createMsg { shift; return new Tibco::Rv::Msg( @_ ) }
sub createCmMsg { shift; return new Tibco::Rv::Cm::Msg( @_ ) }
sub createQueueGroup { shift; return new Tibco::Rv::QueueGroup( @_ ) }
sub createTransport { shift; return new Tibco::Rv::Transport( @_ ) }

sub createDispatcher { return shift->{queueGroup}->createDispatcher( @_ ) }
sub createQueue { return shift->{queueGroup}->createQueue( @_ ) }
sub add { shift->{queueGroup}->add( @_ ) }
sub remove { shift->{queueGroup}->remove( @_ ) }

sub hook { return shift->{queue}->hook( @_ ) }
sub createTimer { return shift->{queue}->createTimer( @_ ) }
sub createIO { return shift->{queue}->createIO( @_ ) }


sub createListener
{
   my ( $self, %args ) = @_;
   return
      $self->{queue}->createListener( transport => $self->{transport}, %args );
}


sub createCmListener
{
   my ( $self, %args ) = @_;

   unless ( exists $args{transport} and defined $args{transport} )
   {
      my ( %cmtArgs );
      my ( @cmtArgs ) = qw/ service network daemon cmName
         requestOld ledgerName syncLedger relayAgent defaultCMTimeLimit /;
      @cmtArgs{ @cmtArgs } = @args{ @cmtArgs };
      $cmtArgs{transport} = $self->transport
         unless ( ( exists $args{service} and defined $args{service} )
            or ( exists $args{network} and defined $args{network} )
            or ( exists $args{daemon} and defined $args{daemon} ) );
      $args{transport} = $self->createCmTransport( %cmtArgs );
   }

   my ( %cmlArgs );
   my ( @cmlArgs ) = qw/ transport subject callback /;
   @cmlArgs{ @cmlArgs } = @args{ @cmlArgs };
   return $self->{queue}->createCmListener( %cmlArgs );
}


sub createCmTransport
{
   my ( $self, %args ) = @_;
   $args{transport} = $self->transport
      unless ( ( exists $args{service} and defined $args{service} )
         or ( exists $args{network} and defined $args{network} )
	 or ( exists $args{daemon} and defined $args{daemon} ) );
   return new Tibco::Rv::Cm::Transport( %args );
}


sub send { shift->{transport}->send( @_ ) }
sub sendReply { shift->{transport}->sendReply( @_ ) }
sub sendRequest { shift->{transport}->sendRequest( @_ ) }
sub createInbox { shift->{transport}->createInbox( @_ ) }


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{created} );

   delete @$self{ keys %$self };
   my ( $status ) = tibrv_Close( );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv - Perl bindings and Object-Oriented library for TIBCO's TIB/Rendezvous

=head1 SYNOPSIS

   use Tibco::Rv;

   my ( $rv ) = new Tibco::Rv;

   my ( $listener ) =
      $rv->createListener( subject => 'ABC', callback => sub
   {
      my ( $msg ) = @_;
      print "Listener got a message: $msg\n";
   } );

   my ( $timer ) = $rv->createTimer( timeout => 2, callback => sub
   {
      my ( $msg ) = $rv->createMsg;
      $msg->addString( field1 => 'myvalue' );
      $msg->addString( field2 => 'myothervalue' );
      $msg->sendSubject( 'ABC' );
      print "Timer kicking out a message: $msg\n";
      $rv->send( $msg );
   } );

   my ( $killTimer ) =
      $rv->createTimer( timeout => 7, callback => sub { $rv->stop } );

   $rv->start;
   print "finished\n"

=head1 DESCRIPTION

C<Tibco::Rv> provides bindings and Object-Oriented classes for TIBCO's
TIB/Rendezvous message passing C API.

All methods die with a L<Tibco::Rv::Status|Tibco::Rv::Status> message if
there are any TIB/Rendezvous errors.

=head1 CONSTRUCTOR

=over 4

=item $rv = new Tibco::Rv( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon

Creates a C<Tibco::Rv>, which is the top-level object that manages all your
TIB/Rendezvous needs.  There should only ever be one of these created.
Calling this method does the following: opens up the internal Rendezvous
machinery; creates objects for the Intra-Process Transport and the Default
Queue; creates a default QueueGroup and adds the Default Queue to it; and,
creates the Default Transport using the supplied service/network/daemon
arguments.  Supply C<undef> (or supply nothing) as the arguments to create a
Default Transport connection to a Rendezvous daemon running under the default
service/network/daemon settings.

See the Transport documentation section on the
L<Intra-Process Transport|Tibco::Rv::Transport/"INTRA-PROCESS TRANSPORT">
for information on the Intra-Process Transport.

See the Queue documentation section on the
L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE"> for information on the
Default Queue.

See L<Tibco::Rv::QueueGroup> for information on QueueGroups.

See your TIB/Rendezvous documentation for information on
service/network/daemon arguments and connecting to Rendezvous daemons, and
all other TIB/Rendezvous concepts.

=back

=head1 METHODS

=over 4

=item Tibco::Rv::die( $status )

Dies (raises an exception) with the given C<$status>.  C<$status> can either
be a L<Status|Tibco::Rv::Status> object, or one of the
L<Status Constants|"STATUS CONSTANTS"> (below).  The exception is of the form:

   %d: %s

... where '%d' is the status number, and '%s' is a description of the error.
The file and line number where the error occurred is appended.

All Tibco::Rv methods use this method to raise an exception when they
encounter a TIB/Rendezvous error.  Use an C<eval { .. }; if ( $@ )> block
around all Tibco::Rv code if you care about that sort of thing.

To include a detailed stacktrace in the error message, include the string
"MCarp=verbose" in the PERL5OPT environment variable (see L<Carp>).

=item $ver = Tibco::Rv->version (or $ver = $rv->version)

Returns a string of the form:

   tibrv x.x.xx; tibrvcm y.y.yy; Tibco::Rv z.zz

where x.x.xx is the version of TIB/Rendezvous (the tibrv C library) that is
being used, y.y.yy is the version of TIB/Rv Certified Messaging (the tibrvcm
C library) that is being used, and z.zz is the version of Tibco::Rv (this Perl
 module) that is being used.

=item $transport = $rv->processTransport

Returns the Intra-Process Transport.

=item $transport = $rv->transport

Returns the Default Transport.

=item $queue = $rv->defaultQueue

Returns the Default Queue.

=item $queueGroup = $rv->defaultQueueGroup

Returns the Default QueueGroup.  The Default QueueGroup originally contains
only the Default Queue.

=item $rv->start

Begin processing events on the Default QueueGroup.  This call remains in
its own process loop until C<stop> is called.  Also, this call sets
up a signal handler for TERM and KILL signals, which calls C<stop>
when either of those signals are received.  It may also be useful to
create a Listener which listens to a special subject, which, when triggered,
calls C<stop>.

=item $rv->stop

Stops the process loop started by C<start>.  If the process loop is not
happening, this call does nothing.

=item $msg = $rv->createMsg

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Returns a new L<Msg|Tibco::Rv::Msg> object, with sendSubject and replySubject
as given in %args (sendSubject and replySubject default to C<undef> if not
specified).  Any other name => value pairs are added as string fields.

=item $queueGroup = $rv->createQueueGroup

Returns a new L<QueueGroup|Tibco::Rv::QueueGroup> object.

=item $transport = $rv->createTransport( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon,
      description => $description,
      batchMode => $batchMode

Returns a new L<Transport|Tibco::Rv::Transport> object, using the given
service/network/daemon arguments.  These arguments can be C<undef> or
not specified to use the default arguments.  Description defaults to C<undef>,
and batchMode defaults to Tibco::Rv::Transport::DEFAULT_BATCH.  If Tibco::Rv
was built against an Rv 6.x version, then this method will die with a
Tibco::Rv::VERSION_MISMATCH Status message if you attempt to set batchMode
to anything other than Tibco::Rv::Transport::DEFAULT_BATCH.

=item $dispatcher = $rv->createDispatcher( %args )

   %args:
      idleTimeout => $idleTimeout

Returns a new L<Dispatcher|Tibco::Rv::Dispatcher> object to dispatch on the
Default QueueGroup, with the given idleTimeout argument (idleTimeout
defaults to C<Tibco::Rv::WAIT_FOREVER> if it is C<undef> or not specified).

=item $queue = $rv->createQueue

Returns a new L<Queue|Tibco::Rv::Queue> object, added to the Default
QueueGroup.

=item $rv->add( $queue )

Add C<$queue> to the Default QueueGroup.

=item $rv->remove( $queue )

Remove C<$queue> from the Default QueueGroup.

=item $hook = $rv->hook

Returns the Default Queue's event arrival hook.

=item $rv->hook( sub { ... } )

Set the Default Queue's event arrival hook to the given sub reference.  This
hook is called every time an event is added to the queue.

=item $timer = $rv->createTimer( %args )

   %args:
      interval => $interval,
      callback => sub { ... }

Returns a new L<Timer|Tibco::Rv::Timer> object with the Default Queue and
given interval, callback arguments.

=item $io = $rv->createIO( %args )

   %args:
      socketId => $socketId,
      ioType => $ioType,
      callback => sub { ... }

Returns a new L<IO|Tibco::Rv::IO> object with the Default Queue and
given socketId, ioType, callback arguments.

=item $listener = $rv->createListener( %args )

   %args:
      subject => $subject,
      callback => sub { ... }

Returns a new L<Listener|Tibco::Rv::Listener> object with the Default Queue,
the Default Transport, and the given subject, callback arguments.

=item $rv->send( $msg )

Sends C<$msg> via the Default Transport.

=item $reply = $rv->sendRequest( $request, $timeout )

Sends the given C<$request> message via the Default Transport, using the
given C<$timeout>.  C<$timeout> defaults to Tibco::Rv::WAIT_FOREVER if given
as C<undef> or not specified.  Returns the C<$reply> message, or C<undef>
if the timeout is reached before receiving a reply.

=item $rv->sendReply( $reply, $request )

Sends the given C<$reply> message in response to the given C<$request> message
via the Default Transport.

=item $inbox = $rv->createInbox

Returns a new C<$inbox> subject.  See L<Tibco::Rv::Msg|Tibco::Rv::Msg> for
a more detailed discussion of sendRequest, sendReply, and createInbox.

=item $cmMsg = $rv->createCmMsg

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      CMTimeLimit => $CMTimeLimit,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Returns a new L<cmMsg|Tibco::Rv::Cm::Msg> object, with sendSubject,
replySubject, and CMTimeLimit as given in %args (these three values default
to C<undef> if not specified).  Any other name => value pairs are added as
string fields.

=item $cmTransport = $rv->createCmTransport( %args )

   %args:
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

Returns a new L<cmTransport|Tibco::Rv::Cm::Transport> object.  If not
specified, requestOld defaults to Tibco::Rv::FALSE, syncLedger defaults to
Tibco::Rv::FALSE, defaultCMTimeLimit defaults to 0 (no time limit), and
publisherInactivityDiscardInterval defaults to 0 (no time limit).  If
service/network/daemon parameters are not specified, the default transport
is used, otherwise a new transport is created using the given
service/network/daemon parameters.

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
to retain the message.  It may be overridden for each message.  It defaults
to C<0>.  A time limit of 0 represents no time limit.

See your TIB/Rendezvous documentation for more information about
publisherInactivityDiscardInterval, which was introduced in tibrv 7.3.  If
Tibco::Rv was built against a version prior to 7.3, then this method
will die with a Tibco::Rv::VERSION_MISMATCH Status message if you attempt
to set publisherInactivityDiscardInterval to anything other than 0.

=item createCmListener

   %args:
      queue => $queue,
      transport => $transport,
      subject => $subject,
      callback => sub { ... }

Returns a new L<cmListener|Tibco::Rv::Cm::Listener> object.  transport must
be a L<Tibco::Rv::Cm::Transport|Tibco::Rv::Cm::Transport>.  If not specified,
queue defaults to the L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE">,
subject defaults to the empty string, and callback defaults to:

   sub { print "cmListener received: @_\n" }

A program registers interest in C<$subject> by creating a Listener.  Messages
coming in on C<$subject> via C<$transport> are placed on the C<$queue>.
When C<$queue> dispatches such an event, it triggers the given callback.

=item $rv->DESTROY

Closes the TIB/Rendezvous machinery.  DESTROY is called automatically when
C<$rv> goes out of scope, but you may also call it explicitly.  All Tibco
objects that you have created are invalidated (except for Tibco::Rv::Msg
objects).  Nothing will happen if DESTROY is called on an already-destroyed
C<$rv>.

=back

=head1 STATUS CONSTANTS

=over 4

=item Tibco::Rv::OK => 0

=item Tibco::Rv::INIT_FAILURE => 1

=item Tibco::Rv::INVALID_TRANSPORT => 2

=item Tibco::Rv::INVALID_ARG => 3

=item Tibco::Rv::NOT_INITIALIZED => 4

=item Tibco::Rv::ARG_CONFLICT => 5

=item Tibco::Rv::SERVICE_NOT_FOUND => 16

=item Tibco::Rv::NETWORK_NOT_FOUND => 17

=item Tibco::Rv::DAEMON_NOT_FOUND => 18

=item Tibco::Rv::NO_MEMORY => 19

=item Tibco::Rv::INVALID_SUBJECT => 20

=item Tibco::Rv::DAEMON_NOT_CONNECTED => 21

=item Tibco::Rv::VERSION_MISMATCH => 22

=item Tibco::Rv::SUBJECT_COLLISION => 23

=item Tibco::Rv::VC_NOT_CONNECTED => 24

=item Tibco::Rv::NOT_PERMITTED => 27

=item Tibco::Rv::INVALID_NAME => 30

=item Tibco::Rv::INVALID_TYPE => 31

=item Tibco::Rv::INVALID_SIZE => 32

=item Tibco::Rv::INVALID_COUNT => 33

=item Tibco::Rv::NOT_FOUND => 35

=item Tibco::Rv::ID_IN_USE => 36

=item Tibco::Rv::ID_CONFLICT => 37

=item Tibco::Rv::CONVERSION_FAILED => 38

=item Tibco::Rv::RESERVED_HANDLER => 39

=item Tibco::Rv::ENCODER_FAILED => 40

=item Tibco::Rv::DECODER_FAILED => 41

=item Tibco::Rv::INVALID_MSG => 42

=item Tibco::Rv::INVALID_FIELD => 43

=item Tibco::Rv::INVALID_INSTANCE => 44

=item Tibco::Rv::CORRUPT_MSG => 45

=item Tibco::Rv::TIMEOUT => 50

=item Tibco::Rv::INTR => 51

=item Tibco::Rv::INVALID_DISPATCHABLE => 52

=item Tibco::Rv::INVALID_DISPATCHER => 53

=item Tibco::Rv::INVALID_EVENT => 60

=item Tibco::Rv::INVALID_CALLBACK => 61

=item Tibco::Rv::INVALID_QUEUE => 62

=item Tibco::Rv::INVALID_QUEUE_GROUP => 63

=item Tibco::Rv::INVALID_TIME_INTERVAL => 64

=item Tibco::Rv::INVALID_IO_SOURCE => 65

=item Tibco::Rv::INVALID_IO_CONDITION => 66

=item Tibco::Rv::SOCKET_LIMIT => 67

=item Tibco::Rv::OS_ERROR => 68

=item Tibco::Rv::INSUFFICIENT_BUFFER => 70

=item Tibco::Rv::EOF => 71

=item Tibco::Rv::INVALID_FILE => 72

=item Tibco::Rv::FILE_NOT_FOUND => 73

=item Tibco::Rv::IO_FAILED => 74

=item Tibco::Rv::NOT_FILE_OWNER => 80

=item Tibco::Rv::TOO_MANY_NEIGHBORS => 90

=item Tibco::Rv::ALREADY_EXISTS => 91

=item Tibco::Rv::PORT_BUSY => 100

=back

=head1 OTHER CONSTANTS

=over 4

=item Tibco::Rv::SUBJECT_MAX => 255

Maximum length of a subject

=item Tibco::Rv::SUBJECT_TOKEN_MAX => 127

Maximum number of tokens a subject can contain

=item Tibco::Rv::FALSE => 0

Boolean false

=item Tibco::Rv::TRUE => 1

Boolean true

=item Tibco::Rv::WAIT_FOREVER => -1.0

Blocking wait on event dispatch calls (waits until an event occurs)

=item Tibco::Rv::NO_WAIT => 0.0

Non-blocking wait on event dispatch calls (returns immediately)

=item Tibco::Rv::VERSION => <this version>

Programmatically access the installed version of Tibco::Rv, in the form 'x.xx'

=item Tibco::Rv::TIBRV_VERSION_RELEASE => <build option>

Programmatically access the major version of TIB/Rendezvous.  For instance,
TIBRV_VERSION_RELEASE = 7 for all releases in the Rv 7.x series, or 6 for
all releases in the Rv 6.x series.  This allows for backwards compatibility
when building Tibco::Rv against any version of tibrv, 6.x or later.

If Tibco::Rv is built against an Rv 6.x release, then using any function
available only in Rv 7.x will die with a Tibco::Rv::VERSION_MISMATCH Status
message.

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Status>

=item L<Tibco::Rv::Event>

=item L<Tibco::Rv::QueueGroup>

=item L<Tibco::Rv::Queue>

=item L<Tibco::Rv::Dispatcher>

=item L<Tibco::Rv::Transport>

=item L<Tibco::Rv::Msg>

=item L<Tibco::Rv::Cm::Listener>

=item L<Tibco::Rv::Cm::Transport>

=item L<Tibco::Rv::Cm::Msg>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=head1 WEBSITE

http://branewave.com/perl

=head1 MAILING LIST

perl-tibco-discuss@branewave.com

=head1 COPYRIGHT

Copyright (c) 2005 Paul Sturm.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

I would love to hear about my software being used; send me an email!

Tibco::Rv will not operate without TIB/Rendezvous, which is not included
in this distribution.  You must obtain TIB/Rendezvous (and a license to use
it) from TIBCO, Inc. (http://www.tibco.com).

TIBCO and TIB/Rendezvous are trademarks of TIBCO, Inc.

TIB/Rendezvous copyright notice:

/*
 * Copyright (c) 1998-2003 TIBCO Software Inc.
 * All rights reserved.
 * TIB/Rendezvous is protected under US Patent No. 5,187,787.
 * For more information, please contact:
 * TIBCO Software Inc., Palo Alto, California, USA
 *
 * $Id: tibrv.h,v 2.10 2003/01/13 12:08:40 randy Exp $
 */

=cut


__DATA__
__C__


tibrv_status tibrv_Open( );
tibrv_status tibrv_Close( );
const char * tibrv_Version( );
const char * tibrvcm_Version( );
