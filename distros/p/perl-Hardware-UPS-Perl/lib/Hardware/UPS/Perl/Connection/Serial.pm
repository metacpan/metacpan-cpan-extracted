package Hardware::UPS::Perl::Connection::Serial;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to connect to a serial port. For a
# detailed description see the pod documentation included at the end of this
# file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a serial object
#   setPort                 - setting the serial port to connected to
#   getPort                 - getting the serial port connected to
#   setDebugLevel           - setting the debug level
#   getDebugLevel           - getting the debug level
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   getErrorMessage         - getting the error message
#   connect                 - connecting to serial port
#   connected               - connection status to serial port
#   disconnect              - disconnecting from serial port
#   sendCommand             - sending a command to the serial port
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
# Revision        : $Revision: 1.12 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/14 09:37:26 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Serial.pm,v $
#   Revision 1.12  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.11  2007/04/07 15:12:44  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.10  2007/03/13 17:11:18  creile
#   usage of Perl pragma constant for ENDCHAR and
#   READ_TIMEOUT instead of variables;
#   options as anonymous hashes.
#
#   Revision 1.9  2007/03/03 21:23:31  creile
#   new variable $UPSERROR added;
#   "return undef" replaced by "return";
#   adaptations to new Constants.pm.
#
#   Revision 1.8  2007/02/25 17:09:17  creile
#   option handling redesigned.
#
#   Revision 1.7  2007/02/06 16:55:01  creile
#   renamed to Hardware::UPS::Perl::Connection::Serial.
#
#   Revision 1.6  2007/02/05 20:37:09  creile
#   pod documentation revised.
#
#   Revision 1.5  2007/02/04 14:01:53  creile
#   bug fix in pod documentation.
#
#   Revision 1.4  2007/02/04 06:13:01  creile
#   documentation revised.
#
#   Revision 1.3  2007/02/03 22:05:23  creile
#   logging support added;
#   serial port will be locked using flock();
#   read timeout of serial port raised to 2;
#   options for method new() revised;
#   select() in method sendCommand() ignores error EINTR now;
#   update of documentation.
#
#   Revision 1.2  2007/01/28 05:23:15  creile
#   bug fix concerning pod documentation.
#
#   Revision 1.1  2007/01/27 16:03:23  creile
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

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/ );

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
#   Fcntl                           - load the C Fcntl.h defines
#   FileHandle                      - supply object methods for filehandles
#   IO::Select                      - OO interface to the select system call
#   IO::Stty                        - setting terminal parameters
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
use Fcntl qw(
    :DEFAULT
    :flock
);
use FileHandle;
use IO::Select;
use IO::Stty;

use Hardware::UPS::Perl::Constants qw(
    UPSPORT
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

use constant ENDCHAR        => "\r";
use constant READ_TIMEOUT   =>    2;     

#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct a serial object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following bare argument is recognized
    #
    #   $port           - the serial port the UPS resides
    #
    # The following option keys are recognized:
    #
    #   SerialPort  ($) - the serial port the UPS resides; optional;
    #   Logger      ($) - Hardware::UPS::Perl::Logging object; the logger to
    #                     use; optional

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self = {};          # referent to be blessed
    my $optionRefType;      # the reference type of the option input
    my $port;               # the serial port
    my $logger;             # the logger object
    my $option;             # an option

    # blessing serial connection object
    bless $self, $class;

    # checking options
    $optionRefType = ref($options);

    if (!$optionRefType) {

        # just the serial port has been specified
        $port   = $options;

        # we have no logger, so we have to create one with output on STDERR
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;

    }
    elsif ($optionRefType eq 'HASH') {

        # the logger; if we don't have one, we have to create our own with
        # output on STDERR
        $logger = delete $options->{Logger};

        if (!defined $logger) {
            $logger = Hardware::UPS::Perl::Logging->new()
                or return;
        }

        # the serial port
        $port = delete $options->{SerialPort};

        # checking for misspelled options
        foreach $option (keys %{$options}) {
            error("option unknown -- $option");
        }

    }
    else {
        error("not a hash reference -- <$optionRefType>");
    }

    # initializing
    #
    # the error message
    $self->{errorMessage} = q{};

    # the logger
    $self->setLogger($logger);

    # the debug level 
    $self->setDebugLevel(0);

    # opening connection to serial port, if a port was specified
    if (defined $port) {
        $self->connect($port)
           or   do {
                    $UPSERROR = $self->getErrorMessage();
                    return;
                };
    }

    # returning blessed serial object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will disconnect from the serial port if connected
    #
    # parameters: $self (input) - referent to a serial object

    # input as hidden local variable
    my $self = shift;

    # disconnect from serial port
    $self->disconnect();

} # end of the destructor

sub setPort {

    # public method to set the serial port to connect to
    #
    # parameters: $self (input) - referent to a serial object
    #             $port (input) - the serial port

    # input as hidden local variable
    my $self = shift;

    # checking for port
    @_ == 1 or error("usage: setPort(PORT)");
    my $port = shift;

    # getting old port
    my $oldPort = $self->getPort();

    # setting port
    $self->{port} = $port;

    # returning old port
    return $oldPort;

} # end of public method "setPort"

sub getPort {

    # public method to get the serial port connected to
    #
    # parameters: $self (input) - referent to a serial object

    # input as hidden local variable
    my $self = shift;

    # getting port
    if (exists $self->{port}) {
        return $self->{port};
    }
    else {
        return;
    }

} # end of public method "getPort"

sub setDebugLevel {

    # public method to set the debug level, the higher, the better
    #
    # parameters: $self       (input) - referent to a serial object
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
    # parameters: $self (input) - referent to a serial object

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

    # public method to set the logger
    #
    # parameters: $self   (input) - referent to a serial connection object
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

    # setting logger
    $self->{logger} = $logger;

    # returning old logger
    return $oldLogger;

} # end of public method "setLogger"

sub getLogger {

    # public method to get the logger
    #
    # parameters: $self (input) - referent to a serial connection object

    # input as hidden local variable
    my $self = shift;

    # getting logger
    if (exists $self->{logger}) {
        return $self->{logger};
    }
    else {
        return;
    }

} # end of public method "getLogger"

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a serial connection object

    # input as hidden local variable
    my $self = shift;

    # getting error message
    if (exists $self->{errorMessage} ) {
        return $self->{errorMessage};
    }
    else {
        return;
    }

} # end of public method "getErrorMessage"

sub connect {

    # public method to connect to a serial port
    #
    # parameters: $self (input) - referent to a serial object
    #             $port (input) - the serial port (optional)

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $port;               # the actual serial port
    my $oldPort;            # the previous serial port

    # checking for port
    @_ >= 0 and @_ <= 1 or error("usage: connect [PORT]");

    if ( @_ ) {

        $port = shift;
        $port = UPSPORT unless (defined $port);

        # already connected ?
        if ($self->connected()) {

            $oldPort = $self->getPort();

            if ( $oldPort ne $port ) {
                # different port
                $self->setPort($port);
                $self->disconnect();
            }
            else {
                $self->{errorMessage} = "serial port already connected";
                return 0;
            }

        }
        else {
            $self->setPort($port);
        }

    }
    else {

        if (defined $self->getPort()) {
            # already connected ?
            if ($self->connected()) {
                $self->{errorMessage} = "serial port already connected";
                return 0;
            }
            $port = $self->getPort();
        }
        else {
            $port = UPSPORT;
            $self->setPort($port);
        }
    }

    # opening file handle for serial port and locking it
    my $com_fh = new FileHandle $port, O_RDWR | O_NOCTTY | O_EXCL | O_NONBLOCK;

    unless (defined $com_fh) {
        $self->{errorMessage} = "cannot open serial port $port -- $!";
        return 0;
    }

    # locking serial port
    if (!flock($com_fh, LOCK_EX | LOCK_NB)) {
        $self->{errorMessage} = "serial port $port already in use -- $!";
        return 0;
    }

    $com_fh->autoflush();

    # setting properties of the serial port
    $self->{_oldSettings} = IO::Stty::stty(\*$com_fh, '-g');
    IO::Stty::stty(\*$com_fh, qw(2400 ixon -echo));

    $self->{_connection}  = $com_fh;

    return 1;

} # end of public method "connect"

sub connected {

    # public method to test the connection status
    #
    # parameters: $self (input) - referent to a serial object

    # input as hidden local variable
    my $self = shift;

    # checking for connection
    if (exists $self->{_connection}) {
        return $self->{_connection}->opened();
    }
    else {
        return 0;
    }

} # end of public method "connected"

sub disconnect {

    # public method to disconnect from the serial port
    #
    # parameters: $self (input) - referent to a serial object

    # input as hidden local variable
    my $self = shift;

    # deleting connection if connected
    if ($self->connected()) {

        # deleting connection
        my $com_fh = delete $self->{_connection};

        # unlocking
        flock($com_fh, LOCK_UN);

        # restoring properties of the serial port
        IO::Stty::stty(\*$com_fh, $self->{_oldSettings});

        # closing file handle
        undef $com_fh;

        return 1;

    }
    else {

        # error: no connection to serial port
        $self->{errorMessage} = "not connected to serial port";

        return 0;
    }

} # end of public method "disconnect"

sub sendCommand {

    # public method to send a command to the serial port and getting its
    # response
    #
    # parameters: $self         (input) - referent to a serial object
    #             $command      (input) - command sent to the serial port
    #             $response     (input) - response from the serial port
    #                                     (anonymous reference)
    #             $responseSize (input) - size of response from serial port
    #                                     (anonymous reference)

    # input as hidden local variable
    my $self         = shift;
    my $command      = shift;
    my $response     = shift;
    my $responseSize = shift;

    # hidden local variables
    my $com_fh;                         # the file handle of the connection
    my $selectObject;                   # the select object associated with the connection
    my $reader;                         # the reader
    my $answer;                         # the answer
    my $received = q{};                 # the total message received
    my $receivedSize = 0;               # the size of the total message
    my $logger = $self->getLogger();    # the logger

    # getting filehandle
    if (!$self->connected()) {
        $self->{errorMessage} = "not connected to serial port";
        return 0;
    }
    $com_fh = $self->{_connection};

    # send message to UPS
    $com_fh->syswrite($command.ENDCHAR);

    # reading response from the UPS
    $selectObject = IO::Select->new($com_fh);

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

            my $nfound = $com_fh->sysread($answer, $responseSize);
            if (!defined $nfound) {
                $self->{errorMessage} = "sysread failed -- $!";
                return 0;
            }

            PROCESS_ANSWER:
            while ($answer =~ /(\n|\r)$/ ) {
                chop($answer);
                $nfound -= 1;
            }

            $received     .= substr($answer, 0, $nfound);
            $receivedSize += $nfound;

            if (defined $logger and (3 < $self->getDebugLevel()) ) {
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

    # sending result to log file
    if (defined $logger and (2 < $self->getDebugLevel())) {
        $logger->debug("command <$command> => received <$received>");
    }

    return 1;

} # end of public method "sendCommand"

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

Hardware::UPS::Perl::Connection::Serial - package of methods dealing with
connection to a serial port

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Connection::Serial;

    $port   = '/dev/ttyS0';
    $serial = new Hardware::UPS::Perl::Connection::Serial $port;

    undef $serial;                        # disconnects

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Connection::Serial> provides methods dealing with
connections to a serial port.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new serial object

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial = Hardware::UPS::Perl::Connection::Serial->new($port);

	$serial = Hardware::UPS::Perl::Connection::Serial->new({
	    SerialPort => $port,
	    Logger     => $Logger,
    });

=item B<Description:>

B<new> initializes a serial object C<$serial> and opens the serial port to
connect to, if the port is specified.

B<new> expects either a single argument, the serial port, or an anonymous
hash as options consisting of key-value pairs.

=item B<Arguments:>

=over 4

=item C<< $port >>

optional; serial device; defines a valid serial port.

=item C<< SerialPort    => $port >>

optional; serial device; defines a valid serial port.

=item C<< Logger        => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to F<STDERR> is created.

=back

=item B<See Also:>

L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getLogger">,
L<"getPort">,
L<"setLogger">,
L<"setPort">

=back

=head2 setPort

=over 4

=item B<Name:>

setPort - sets the serial device to connect to

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->setPort($port);

=item B<Description:>

B<setPort> sets the serial port to connect to and returns the previous port
if available, undef otherwise.

=item B<Arguments:>

=over 4

=item C<< $port >>

serial device; defines a valid serial port.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getPort">

=back

=head2 getPort

=over 4

=item B<Name:>

getPort - gets the serial device being connected to

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new($port);

	$port   = $serial->getPort();

=item B<Description:>

B<getPort> returns the serial port being connected to.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">,
L<"setPort">

=back

=head2 setDebugLevel

=over 4

=item B<Name:>

setDebugLevel - sets the debug level

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->setDebugLevel(1);

=item B<Description:>

B<setDebugLevel> sets the debug level, the higher, the better. It returns the
previous one if available, 0 otherwise.

=item B<Arguments:>

=over 4

=item C<< $debugLevel >>

integer number; defines the debug level.

=back

=item B<See Also:>

L<"getDebugLevel">

=back

=head2 getDebugLevel

=over 4

=item B<Name:>

getDebugLevel - gets the current debug level

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$debugLevel = $serial->getDebugLevel();

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

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger, a B<Hardware::UPS::Perl::Logging> object, used
for logging. B<setLogger> returns the previous logger used.

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

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$logger = $serial->getLogger();

=item B<Description:>

B<getLogger> returns the current logger, a B<Hardware::UPS::Perl::Logging>
object used for logging, if defined, undef otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new($port);

	unless ($serial->connected()) {
	    print STDERR $serial->getErrorMessage($errorMessage), "\n";
	    exit 0;
	}

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head2 connect

=over 4

=item B<Name:>

connect - connects to a serial port

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->connect($port);

=item B<Description:>

B<connect> connects to a serial port $port using package B<FileHandle>. If
there is a connection already and the port has changed, the old connection is
dropped, otherwise nothing will be done. If no port is specified, it will be
checked whether the port has been previously set by method B<setPort>, and
used for the connection, consequently. If no port is available at all. the
default port provided by package B<Hardware::UPS::Perl::Constants> will be
used, usually being F</dev/ttyS0>. The serial port will be locked using the
Perl builtin function B<flock>, In addition, the serial port settings will be
modified to have a Baud rate of 2400, with XON/XOFF flow control enabled and
echo off using standard package B<IO::Stty>. 

=item B<Arguments:>

=over 4

=item $port

optional; serial device; defines a valid serial port.

=back

=item B<See Also:>

L<"new">,
L<"connected">,
L<"disconnect">,
L<"getPort">,
L<"setPort">

=back

=head2 connected

=over 4

=item B<Name:>

connected - tests the connection status

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->connect($port);
	if ($serial->connected()) {
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

disconnect - disconnects from a serial port

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->connect($port);
	$serial->disconnect();

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->connect($port);
	undef $serial;

=item B<Description:>

B<disconnect> disconnects from a serial port, unlocks it and restores the
previous settings of the serial port using package B<IO::Stty>.

=item B<Notes:>

C<< undef $serial >> has the same effect as C<< $serial->disconnect() >>.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"getPort">,
L<"setPort">

=back

=head2 sendCommand

=over 4

=item B<Name:>

sendCommand - sending a command to the serial port

=item B<Synopsis:>

	$serial = Hardware::UPS::Perl::Connection::Serial->new();

	$serial->connect($port);
	$serial->sendCommand($command, \$response, $responseSize);

=item B<Description:>

B<sendCommand> sends the command C<$command> appended with the F<\r> to a
serial port connected and reads the response from it using the package
B<IO::Select> awaiting the size of the response $responseSize.

=item B<Arguments:>

=over 4

=item C<< $command >>

string; defines a command.

=item C<< $response >>

string; the response from the serial port.

=item C<< $responseSize >>

integer; the buffer size of the response from the serial port.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"disconnect">

=back

=head1 SEE ALSO

Errno(3pm),
Fcntl(3pm),
FileHandle(3pm),
IO::Select(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::Connection::Serial> was inspired by the B<usv.pl>
program by Bernd Holzhauer, E<lt>www.cc-c.deE<gt>. The latest version of this
program can be obtained from

   http://www.cc-c.de/german/linux/linux_usv.php

Another great resource was the B<Network UPS Tools> site, which can be found
at

   http://www.networkupstools.org

B<Hardware::UPS::Perl::Connection::Serial> was developed using B<perl 5.8.8>
on a B<SuSE 10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Connection::Serial> are welcome,
though due to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
