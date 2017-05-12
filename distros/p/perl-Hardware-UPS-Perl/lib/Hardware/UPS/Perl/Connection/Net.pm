package Hardware::UPS::Perl::Connection::Net;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to connect to a remote
# Hardware::UPS::Perl agent. For a detailed description see the pod
# documentation included at the end of this file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a TCP connection object
#   setHost                 - setting the host the remote agent is running on
#   getHost                 - getting the host the remote agent is running on
#   setTCPPort              - setting the TCP/IP port the remote agent is
#                             listening to
#   getTCPPort              - getting the TCP/IP port the remote agent is
#                             listening to
#   setDebugLevel           - setting the debug level
#   getDebugLevel           - getting the debug level
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   getErrorMessage         - getting the error message
#   connect                 - connecting to UPS agent
#   connected               - connection status to UPS agent
#   disconnect              - disconnecting from UPS agent
#   sendCommand             - sending a command to the UPS agent
#
#==============================================================================

#==============================================================================
# Copyright:
#==============================================================================
# Copyright (c) 2007 Christian Reile, <Christian.Reile@t-online.de>. All
# rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#==============================================================================

#==============================================================================
# Entries for Revision Control:
#==============================================================================
# Revision        : $Revision: 1.13 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/14 09:39:02 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Net.pm,v $
#   Revision 1.13  2007/04/14 09:39:02  creile
#   documentation update;
#   bugfix of private method _reconnect().
#
#   Revision 1.12  2007/04/07 15:10:31  creile
#   update of documentation.
#
#   Revision 1.11  2007/04/07 08:11:39  creile
#   adaptations to "best practices" style.
#
#   Revision 1.10  2007/03/13 17:09:44  creile
#   usage of Perl pragma constant for ENDCHAR and
#   READ_TIMEOUT instead of variables;
#   options as anonymous hashes.
#
#   Revision 1.9  2007/03/03 21:23:12  creile
#   new variable $UPSERROR added;
#   "return undef" replaced by "return";
#   adaptations to new Constants.pm.
#
#   Revision 1.8  2007/02/25 17:09:54  creile
#   option handling redesigned.
#
#   Revision 1.7  2007/02/06 16:53:29  creile
#   rrenamed to Hardware::UPS::Perl::Connection::Net.
#
#   Revision 1.6  2007/02/05 20:36:14  creile
#   some syntax errors removed;
#   pod documentation revised.
#
#   Revision 1.5  2007/02/04 14:02:20  creile
#   bug fix in pod documentation.
#
#   Revision 1.4  2007/02/04 06:20:12  creile
#   logging support added;
#   reconnect if connection unavailable;
#   read timeout of serial port raised from 2 to 5 seconds;
#   checking of TCP port option in new() and connect() added;
#   select() in method sendCommand() ignores error EINTR now;
#   update of documentation.
#
#   Revision 1.3  2007/01/28 05:21:40  creile
#   bug fix concerning pod documentation.
#
#   Revision 1.2  2007/01/28 04:08:40  creile
#   die() replaced by error().
#
#   Revision 1.1  2007/01/27 16:03:12  creile
#   initial revision.
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {
    
    use vars qw($VERSION @ISA);

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/ );

    @ISA     = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   constant                        - Perl pragma to declare constants
#   Errno                           - System errno constants
#   IO::Select                      - OO interface to the select system call
#   IO::Socket::INET                - setting terminal parameters
#
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with logfiles
#   Hardware::UPS::Perl::Utils      - importing Hardware::UPS::Perl utility
#                                     functions for packages
#
#==============================================================================

use Errno qw(
    EINTR
);
use IO::Select;
use IO::Socket::INET;

use Hardware::UPS::Perl::Constants qw(
    UPSFQDN
    UPSTCPPORT
);
use Hardware::UPS::Perl::General qw(
    $UPSERROR
);
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::Utils qw(
    error
);

#==============================================================================
# defining constants:
#------------------------------------------------------------------------------
# 
#   ENDCHAR                         - the end character
#   READ_TIMEOUT                    - timeout for reading from serial port in
#                                     seconds
# 
#==============================================================================

use constant ENDCHAR        => "\n";
use constant READ_TIMEOUT   =>    5;     

#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct a TCP connection object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following bare argument is recognized
    #
    #   $host[:$port]   - the host and optional the TCP port to connect to
    #
    # The following option keys are recognized:
    #
    #   Host        ($) - the host and optional the TCP port, separated by ':',
    #                     to connect to; optional;
    #   TCPPort     ($) - the TCP port; optional;
    #   Logger      ($) - Hardware::UPS::Perl::Logging object; the logger to
    #                     use; optional

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self = {};          # referent to be blessed
    my $optionRefType;      # the reference type of the options
    my $host;               # the host
    my $logger;             # the logger object

    # blessing TCP connection object
    bless $self, $class;

    # checking options
    $optionRefType = ref($options);

    if (!$optionRefType) {
        # just the hostname[:port] was specified
        $host = $options;
        undef $options;
        $options->{Host} = $host;
    }
    elsif ($optionRefType ne 'HASH') {
        error("not a hash reference -- <$optionRefType>");
    }

    # the logger; if we don't have one, we have to create our own with output
    # on STDERR
    $logger = delete $options->{Logger};

    if (!defined $logger) {
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;
    }

    # initializing
    #
    # the error message
    $self->{errorMessage} = q{};

    # the logger 
    $self->setLogger($logger);

    # the debug level 
    $self->setDebugLevel(0);
    
    # opening connection to UPS agent, if hostname and port was specified
    if ($options) {
        $self->connect($options)
            or  do {
                    $UPSERROR = $self->getErrorMessage();
                    return;
                };
    }

    # reconnecting, if remote server closes the connection
    $SIG{PIPE} = sub {
        $self->disconnect();
        $self->_reconnect();
    };

    # returning blessed connection object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will disconnect from the UPS agent if connected
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # disconnect from UPS agent
    $self->disconnect();

} # end of the destructor

sub setHost {

    # public method to set the host where the UPS agent resides
    #
    # parameters: $self (input) - referent to a connection object
    #             $host (input) - the host

    # input as hidden local variable
    my $self = shift;

    # checking for host
    @_ == 1 or error("usage: setHost(HOST)");
    my $host = shift;

    # getting old host
    my $oldHost = $self->getHost();

    # setting port
    $self->{host} = $host;

    # returning old host
    return $oldHost;

} # end of public method "setHost"

sub getHost {

    # public method to get the host where the UPS agent resides
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting port
    if (exists $self->{host}) {
        return $self->{host};
    }
    else {
        return;
    }

} # end of public method "getHost"

sub setTCPPort {

    # public method to set the TCP port the UPS agent resides
    #
    # parameters: $self    (input) - referent to a connection object
    #             $tcpport (input) - the TCP port

    # input as hidden local variable
    my $self = shift;

    # checking for TCP port
    @_ == 1 or error("usage: setTCPPort(TCPPORT)");
    my $tcpport = shift;

    if (defined $tcpport) {
        ( ($tcpport =~ /\d+/) and ($tcpport > 0) )
            or error("invalid TCP port -- $tcpport");
    }

    # getting old TCP port
    my $oldPort = $self->getTCPPort();

    # setting TCP port
    $self->{tcpport} = $tcpport;

    # returning old TCP port
    return $oldPort;

} # end of public method "setTCPPort"

sub getTCPPort {

    # public method to get the TCP port the UPS agent resides
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting port
    if (exists $self->{tcpport}) {
        return $self->{tcpport};
    }
    else {
        return;
    }

} # end of public method "getTCPPort"

sub setDebugLevel {

    # public method to set the debug level, the higher, the better
    #
    # parameters: $self       (input) - referent to a connection object
    #             $debugLevel (input) - the debug level

    # input as hidden local variables
    my $self       = shift;

    @_ == 1 or error("usage: setDebugLevel(debugLevel)");
    my $debugLevel = shift;

    # getting old debug level
    my $oldDebugLevel = $self->getDebugLevel();

    # setting debug level
    $self->{debugLevel} = $debugLevel;

    # returning old debug level
    return $oldDebugLevel;

} # end of public method "setDebugLevel"

sub getDebugLevel {

    # public method to get the current debug level
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting debug level
    if (exists $self->{debugLevel}) {
        return $self->{debugLevel};
    }
    else {
        return;
    }

} # end of public method "getDebugLevel"

sub setLogger {

    # public method to set the logging object
    #
    # parameters: $self   (input) - referent to a TCP connection object
    #             $logger (input) - the logging object

    # input as hidden local variables
    my $self   = shift;

    1 == @_ or error("usage: setLogger(LOGGER)");
    my $logger = shift;

    if (defined $logger) {
        my $loggerRefType = ref($logger);
        if ($loggerRefType ne 'Hardware::UPS::Perl::Logging') {
            error("no logger -- <$loggerRefType>");
        }
    }

    # getting old logger
    my $oldLogger = $self->getLogger();

    # setting new logger
    $self->{logger} = $logger;

    # returning old logger
    return $oldLogger;

} # end of public method "setLogger"

sub getLogger {

    # public method to get the current logger
    #
    # parameters: $self (input) - referent to a TCP connection object

    # input as hidden local variable
    my $self = shift;

    # getting logger
    if (exists $self->{logger} ) {
        return $self->{logger};
    }
    else {
        return;
    }

} # end of public method "getLogger"

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting error message
    if (exists $self->{errorMessage}) {
        return $self->{errorMessage};
    }
    else {
        return;
    }

} # end of public method "getErrorMessage"

sub connect {

    # public method to connect to an UPS agent via TCP
    #
    # parameters: $self    (input) - referent to a connection object
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Host        ($) - the host and optional the TCP port, separated by ':',
    #                     to connect to; optional;
    #   TCPPort     ($) - the TCP port; optional;

    # input as hidden local variables
    my $self    = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $optionRefType;      # the reference type of the option
    my %processOption;      # the action table to process options
    my $option;             # an option
    my $arg;                # an option argument
    my $host;               # the host to connect to
    my $oldHost;            # the old host
    my $tcpPort;            # the TCP port
    my $oldTCPPort;         # the old TCP port
    my $changeConnection;   # flag indicating to change the connection

    # checking options
    $optionRefType = ref($options);
    if ($optionRefType ne 'HASH') {
        error("not a hash reference -- <$optionRefType>");
    }

    if (%{$options}) {

        # processing options, starting with defaults
        $host    = UPSFQDN;
        $tcpPort = UPSTCPPORT;

        %processOption = (
            Host    =>  sub {
                            my $arg = shift;
                            if ($arg =~ /:/) {
                                $host = $`;
                                if (exists $options->{TCPPort}) {
                                    error("unexpected option -- host:TCPPort")
                                }
                                else {
                                    $tcpPort = $';
                                }
                            }
                            else {
                                $host = $arg;
                            }
                        },
            TCPPort =>  sub {
                            my $arg = shift;
                            $tcpPort = $arg;
                        },
        );

        OPTIONS:
        while (($option, $arg) = each %{$options}) {
            if (exists $processOption{$option}) {
                $processOption{$option}->($arg);
            }
            else {
                error("option unknown -- $option");
            }
        }

        # already connected ?
        if ($self->connected()) {

            $oldHost          = $self->getHost();
            $oldTCPPort       = $self->getTCPPort();
            $changeConnection = 0;

            if ($oldHost ne $host) {
                # different host
                $self->setHost($host);
                $changeConnection = 1;
            }

            if ($oldTCPPort ne $tcpPort) {
                # different port
                $self->setTCPPort($tcpPort);
                $changeConnection = 1;
            }

            if ($changeConnection) {
                $self->disconnect();
            }
            else {
                $self->{errorMessage} = "UPS agent already connected";
                return 0;
            }
        }
        else {

            $self->setHost($host);
            $self->setTCPPort($tcpPort);

        }

    }
    else {

        # no options available
        # already connected ?
        if ($self->connected()) {
            $self->{errorMessage} = "UPS agent already connected";
            return 0;
        }

        if (defined $self->getHost()) {
            $host = $self->getHost();
        }
        else {
            $host = UPSFQDN;
            $self->setHost(UPSFQDN);
        }

        if (defined $self->getTCPPort()) {
            $tcpPort = $self->getTCPPort();
        }
        else {
            $tcpPort = UPSTCPPORT;
            $self->setTCPPort(UPSTCPPORT);
        }

    }

    # opening connection to remote UPS agent
    $host .= q{:} . $tcpPort;
    my $socket = IO::Socket::INET->new($host);

    if (!defined $socket) {
        $self->{errorMessage} = "cannot connect to $host -- $!";
        return 0;
    }

    if (defined $self->getLogger() and (0 < $self->getDebugLevel())) {
        $self->getLogger()->info("connection to host $host succeeded");
    }

    $socket->autoflush();

    $self->{_socket} = $socket;

    return 1;

} # end of public method "connect"

sub connected {

    # public method to test the connection status
    #
    # parameters: $self (input) - referent to a TCP connection object

    # input as hidden local variable
    my $self = shift;

    # checking for connection
    if (exists $self->{_socket}) {
        my $socket = $self->{_socket};
        if (defined $socket->connected()) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return 0;
    }

} # end of public method "connected"

sub disconnect {

    # public method to disconnect from the remote running UPS agent
    #
    # parameters: $self (input) - referent to a TCP connection object

    # input as hidden local variable
    my $self = shift;

    # deleting connection if connected
    if ($self->connected()) {

        # deleting connection
        my $socket = delete $self->{_socket};

        # closing socket
        undef $socket;

        my $logger = $self->getLogger();
        if (defined $logger and (0 < $self->getDebugLevel())) {
            my $host = $self->getHost() . q{:} . $self->getTCPPort();
            $logger->info("host $host disconnected");
        }

        return 1;

    }
    else {

        # error: UPS agent was not connected
        $self->{errorMessage} = "not connected to UPS agent";

        return 0;
    }

} # end of public method "disconnect"

sub sendCommand {

    # public method to send a command to the UPS agent and getting its response
    #
    # parameters: $self         (input) - referent to a TCP connection object
    #             $command      (input) - command sent to UPS agent
    #             $response     (input) - response from UPS agent;
    #                                     anonymous reference
    #             $responseSize (input) - size of response from UPS agent

    # input as hidden local variable
    my $self         = shift;
    my $command      = shift;
    my $response     = shift;
    my $responseSize = shift;

    # hidden local variables
    my $socket;                         # the connection socket
    my $selectObject;                   # the select object associated with the connection
    my $reader;                         # reader
    my $answer;                         # the answer
    my $received = q{};                 # the total message received
    my $receivedSize = 0;               # the size of the total message
    my $logger = $self->getLogger();    # logger object

    # getting filehandle
    $self->_reconnect() if (!$self->connected());
    $socket = $self->{_socket};

    # send message to UPS
    $socket->syswrite($command.q{}.$responseSize.ENDCHAR);

    # reading response from the UPS
    $selectObject = IO::Select->new($socket);

    SELECT:
    while ($selectObject) {
        $! = 0;

        $reader = IO::Select->select($selectObject, undef, undef, READ_TIMEOUT)
            or  do {
                    if ($!) {
                        if (EINTR != $!) {
                            $self->{errorMessage} = "select failed -- $!";
                            return 0;
                        }
                    }
                    else {
                        last SELECT;
                    }
                };

        if ($reader) {

            my $nfound = $socket->sysread($answer, $responseSize);

            if (!defined $nfound) {
                $self->{errorMessage} = "sysread failed -- $!";
                return 0;
            }

            if ($answer =~ /${\(ENDCHAR)}$/ ) {
                chomp($answer);
                $nfound -= 1;
            }

            $received     .= substr($answer, 0, $nfound);
            $receivedSize += $nfound;

            if (defined $logger and (3 < $self->getDebugLevel())) {
                $logger->debug(
                    "sysread: size = <$receivedSize>, received = <$received>"
                );
            }

            $selectObject = undef if (!$nfound);
        }
    }

    # was the response complete ?
    if ($receivedSize != $responseSize) {
        $self->{errorMessage}
            = "response incomplete -- "
            . "received <$receivedSize> <=> expected <$responseSize>";
        return 0;
    }

    # setting response
    $$response = $received;

    # printing result to log file
    if (defined $logger and (2 < $self->getDebugLevel())) {
        $logger->debug("command <$command> => received <$received>");
    }

    return 1;

} # end of public method "sendCommand"

#==============================================================================
# private methods:
#==============================================================================

sub _reconnect {

    # private method to restart the client connection
    #
    # parameters: $self (input) - referent to a TCP connection object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $host    = $self->getHost();     # the host to connect to
    my $tcpport = $self->getTCPPort();  # the TCP port to use
    my $logger  = $self->getLogger();   # the logger
    my $count   = 1;                    # reconnect count

    # reconnecting
    $host .= q{:} . $tcpport;

    CONNECTED:
    while (! $self->connected()) {
        $self->connect({
            Host => $host,
        })
           or  do {
                    if (defined $logger) {
                        $logger->info(
                            "reconnect to ".$host." failed -- try no. ".$count
                        );
                        $count++;
                    }

                    my $wait = 60;
                    while ($wait > 0) { 
                        my $slept = sleep($wait);
                        $wait -= $slept;
                    }

                };
    }

} # end of private method "_reconnect"

#==============================================================================
# package return:
#==============================================================================
1;

__END__

#==============================================================================
# embedded pod documentation:
#==============================================================================

=pod

=head1 NAME

Hardware::UPS::Perl::Connection::Net - package of methods to connect to a
remote UPS agent.

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Connection::Net;

    $net = Hardware::UPS::Perl::Connection::Net->new();

    $net = Hardware::UPS::Perl::Connection::Net->new({
	    Host    =>  192.168.41.2,
	    TCPPort =>  9050,
    });

    undef $net;                        # disconnects

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Connection::Net> provides methods to connect to a
remote UPS agent running on host Host at TCP port TCPPort.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new UPS connection object using TCP/IP

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net = Hardware::UPS::Perl::Connection::Net->new({
	    Host    => $host  ,
	    TCPPort => $port  ,
	    Logger  => $Logger,
    });

=item B<Description:>

B<new> initializes a connection object $net and opens the connection to a
remotely running UPS agent via TCP, if the host $host and the TCP port $port
are specified. If the initialization fails, B<new> returns undef.

B<new> expects either a single argument, the host and, optionally, the TCP
port both separated by ":", or an anonymous hash as options consisting of
key-value pairs.

=item B<Arguments:>

=over 4

=item C<< $host[:$port] >>

optional; the host and, optionally, the TCP port; defines the host (and port),
where the UPS agent is running.

=item C<< Host    => $host[:$port] >>

optional; the host; defines the host (and port), where the UPS agent is
running.

=item C<< TCPPort => $port >>

optional; the TCP port; defines the port at the host, where the UPS agent is
running.

=item C<< Logger  => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to F<STDERR> is created.

=back

=item B<See Also:>

L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getHost">,
L<"getLogger">,
L<"getTCPPort">,
L<"setHost">,
L<"setLogger">,
L<"setTCPPort">

=back

=head2 setHost

=over 4

=item B<Name:>

setHost - sets the host to connect to

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->setHost($host);

=item B<Description:>

B<setHost> sets the host to connect to and returns the previous host if
available, undef otherwise.

=item B<Arguments:>

=over 4

=item C<< $host >>

host; defines a resolvable host.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getHost">,
L<"setTCPPort">,
L<"getTCPPort">

=back

=head2 getHost

=over 4

=item B<Name:>

getHost - gets the host to connect or connected to

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new({
	    Host    => 192.168.1.2
	    TCPPort => 9050,
    });

	$host = $net->getHost();

=item B<Description:>

B<getHost> returns the host to connect or already connected to.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getTCPPort">,
L<"setHost">,
L<"setTCPPort">

=back

=head2 setTCPPort

=over 4

=item B<Name:>

setTCPPort - sets the TCP port to connect to

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->setTCPPort($port);

=item B<Description:>

B<setTCPPort> sets the TCP port to connect to and returns the previous TCP
port if available, undef otherwise.

=item B<Arguments:>

=over 4

=item C<< $port >>

natural number; TCP port.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getHost">,
L<"getTCPPort">,
L<"setTCPPort">

=back

=head2 getTCPPort

=over 4

=item B<Name:>

getTCPPort - gets the TCP port to connect or connected to

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new({
	    Host    => 192.168.1.2
	    TCPPort => 9050,
    });

	$host = $net->getTCPPort();

=item B<Description:>

B<getTCPPort> returns the TCP port to connect or already connected to.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getHost">,
L<"getLogger">,
L<"setHost">,
L<"setLogger">,
L<"setTCPPort">

=back

=head2 setDebugLevel

=over 4

=item B<Name:>

setDebugLevel - sets the debug level

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->setDebugLevel(1);

=item B<Description:>

B<setDebugLevel> sets the debug level, the higher, the better. It returns the
previous one if available, 0 otherwise.

=item B<Arguments:>

=over 4

=item C<< $debugLevel >>

natural number; defines the debug level.

=back

=item B<See Also:>

L<"getDebugLevel">

=back

=head2 getDebugLevel

=over 4

=item B<Name:>

getDebugLevel - gets the current debug level

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$debugLevel = $net->getDebugLevel();

=item B<Description:>

B<getDebugLevel> returns the current debug level.

=item B<See Also:>

L<"setDebugLevel">

=back

=head2 setLogger

=over 4

=item B<Name:>

setLogger - sets the logger to use

=item B<Synopsis:>

	$net    = Hardware::UPS::Perl::Connection::Net->new();

	$logger = Hardware::UPS::Perl::Logging->new();

	$net->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger object used for logging. B<setLogger> returns
the previous logger used.

=item B<Arguments:>

=over 4

=item C<< $logger >>

required; a B<Hardware::UPS::Perl:Logging> object; defines the logger for
logging.

=back

=item B<See Also:>

L<"new">,
L<"getLogger">

=back

=head2 getLogger

=over 4

=item B<Name:>

getLogger - gets the current logger for logging

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$logger = $net->getLogger();

=item B<Description:>

B<getLogger> returns the current logger, i.e. a
B<Hardware::UPS::Perl::Logging> object used for logging, if defined, undef
otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	if (!$net->connected()) {
	    print STDERR $net->getErrorMessage(), "\n";
	    exit 0;
	}

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head2 connect

=over 4

=item B<Name:>

connect - connects to a romotely running UPS agent

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->connect();

	$net->connect({
	    Host    => $host,
	    TCPPort => $port,
    });

=item B<Description:>

B<connect> connects to an UPS agent running at TCP port $port on host $host
using package B<IO::Socket::INET>. If there is already a connection and the
host and/or TCP port have changed, the old connection is dropped, otherwise
nothing will be done. If no host and/or TCP port are specified, it will be
checked whether the host and/or TCP port has been previously set by methods
B<setHost> and B<setTCPPort>, respectively, and used for the connection,
consequently. If no host and/or no port is available at all. the default host
and default TCP port provided by package B<Hardware::UPS::Perl::Constants>
will be used, usually being the FQDN of the local host and port 9050.

=item B<Arguments:>

=over 4

=item C<< Host      => $host[:$port] >>

optional; host; defines a resolvable host (IP address, FQDN, hostname).
The TCP port to be used can be appended with a ":".

=item C<< TCPPort   =>  $port >>

optional; TCP port; defines a valid TCP port.

=back

=item B<See Also:>

L<"new">,
L<"connected">,
L<"disconnect">,
L<"setHost">,
L<"getHost">,
L<"setTCPPort">,
L<"getTCPPort">

=back

=head2 connected

=over 4

=item B<Name:>

connected - tests the connection status

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->connect();
	if ($net->connected()) {
	    ...
	}

=item B<Description:>

B<connected> tests the connection status, returning 0, when not connected, and
1 when connected.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"disconnect">

=back

=head2 disconnect

=over 4

=item B<Name:>

disconnect - disconnects from an UPS agent

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->connect();
	$net->disconnect();

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->connect();
	undef $net;

=item B<Description:>

B<disconnect> disconnects from an UPS agent.

=item B<Notes:>

C<< undef $net >> has the same effect as C<< $net->disconnect() >>.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"setHost">,
L<"getHost">,
L<"setTCPPort">,
L<"getTCPPort">

=back

=head2 sendCommand

=over 4

=item B<Name:>

sendCommand - sending a command to the UPS agent

=item B<Synopsis:>

	$net = Hardware::UPS::Perl::Connection::Net->new();

	$net->connect();
	$net->sendCommand($command, \$response, $responseSize);

=item B<Description:>

B<sendCommand> sends a command $command to an UPS agent connected appending
the response size expected using F<<C-A>> and F<"\n"> and reads the response
$response from the UPS agent using the package B<IO::Select>.

=item B<Arguments:>

=over 4

=item C<< $command >>

string; defines a command.

=back

=over 4

=item C<< $response >>

string; the response from the UPS.

=back

=over 4

=item C<< $responseSize >>

integer; the buffer size of the response from the UPS.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">

=back

=head1 SEE ALSO

Errno(3pm),
IO::Select(3pm),
IO::Socket::INET(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::Connection::Net> was inspired by the B<usv.pl> program
by Bernd Holzhauer, E<lt>www.cc-c.deE<gt>. The latest version of this program
can be obtained from

    http://www.cc-c.de/german/linux/linux_usv.php

Another great resource was the B<Network UPS Tools> site, which can be found
at

    http://www.networkupstools.org

B<Hardware::UPS::Perl::Connection::Net> was developed using B<perl 5.8.8> on a
B<SuSE 10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Connection::Net> are welcome,
though due to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

cut
