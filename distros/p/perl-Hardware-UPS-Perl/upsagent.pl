#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# Perl script to enable to watch an UPS on a serial device remotely via
# TCP/IP.
#==============================================================================

#==============================================================================
# embedded pod documentation:
#------------------------------------------------------------------------------

=head1 NAME

upsagent - enables remote control over a local UPS on a serial device

=head1 SYNOPSIS

B<upsagent>
S<[ B<-h>, B<--help> ]> S<[ B<-M>, B<--man> ]> S<[ B<-V>, B<--version> ]>
S<[ B<-d>, B<--debug-level> [I<debuglevel>] ]>
S<[ B<-L>, B<--logfile> [I<logfile>] ]>
S<[ B<-P>, B<--port> [I<port>] ]>
S<[ B<-p>, B<--pidfile> I<pidfile> ]>
[I<device-name>]

=head1 DESCRIPTION

B<upsagent> enables remote control over a local UPS on a serial device
specified by the optional F<device-name> parameter via TCP/IP using port
F<port>. If F<device-name> is omitted, F</dev/ttyS0>, i.e. the COM1 port, is
used per default unless overriden by the environment variable F<UPS_PORT>. If
the TCP/IP port F<port> is not specified port F<9050> is used unless overriden
by the environment variable F<UPS_TCPPORT>.

The program listens on F<port> for incoming requests and sends the data
received to the local UPS. The answer of the UPS is sent back.

=head1 OPTIONS

=over 4

=item B<-h>, B<--help>

Displays a short usage help message and exits without errors.

=item B<-M>, B<--man>

Displays the embedded pod documentation of B<upsagent> (this screen) using
B<pod2man>, B<groff> and B<less> as pager; it exits without errors.

=item B<-V>, B<--version>

Displays version information and exits without errors.

=item B<-d>, B<--debug-level> [I<debuglevel>]

Sets the integer debug level I<debuglevel>. If the debug level is not
specified a default of 1 is assumed. A higher debug level will increase the
verbosity.

=item B<-L>, B<--logfile> I<logfile>

Sets the logfile to I<logfile>. If not specified, the default log file
F</var/run/upsagent.log> will be used.

=item B<-p>, B<--pidfile> I<pidfile>

Sets the PID file to I<pidfile>. If not specified, the default PID file
F</var/run/upsagent.pid> will be used.

=item B<-P>, B<--port> I<port>

Sets the TCP/IP port I<port> the programs waits for incoming requests to the
local UPS. If not specified, the default port F<9050> is used unless overriden
by the environment variable F<UPS_TCPPORT>.

=back

=head1 EXAMPLES

=over 4

=item B<upsagent>

Listens on TCP/IP port 9050 for incoming requests and sends them to the local
UPS on COM1. The response of the UPS is sent back.

=item B<upsagent> B<-p> I<1200> I</dev/ttyS1>

Listens on TCP/IP port 1200 for incoming requests and sends them to the local
UPS on COM2. The response of the UPS is sent back.

=back

=head1 SEE ALSO

groff(1),
less(1),
pod2man(1),
upsadm(1),
upsstat(1),
upswatch(1),
Getopt::Long(3pm),
IO::Select(3pm),
IO::Socket::INET(3pm),
Net::hostent(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm)

=head1 AUTHOR

Christian Reile, Christian.Reile@t-online.de

=cut

#==============================================================================
# Entries for revision control:
#------------------------------------------------------------------------------
# Revision        : $Revision: 1.11 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:52:44 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: upsagent.pl,v $
# Revision 1.11  2007/04/17 19:52:44  creile
# unnecessary comments removed.
#
# Revision 1.10  2007/04/14 16:48:19  creile
# documentation bugfix.
#
# Revision 1.9  2007/04/14 09:37:26  creile
# documentation update.
#
# Revision 1.8  2007/04/07 15:25:20  creile
# adaptations to "best practices" style;
# update of documentation.
#
# Revision 1.7  2007/03/13 17:23:33  creile
# main while() loop revised for readers, writers and out-of-band
# data;
# adaptations to options as anonymous hashes.
#
# Revision 1.6  2007/03/03 21:29:48  creile
# new variable $UPSERROR added;
# adaptations to new Constants.pm.
#
# Revision 1.5  2007/02/25 17:12:15  creile
# connection handling added.
#
# Revision 1.4  2007/02/05 20:49:38  creile
# OO logging (log file) and OO PID files added;
# maximum connections at main socket;
# information about connections added.
#
# Revision 1.3  2007/01/28 05:43:58  creile
# adaptations to new package structure;
# timeout of 0.1s added to call of select();
# protocall change concerning size of response;
# bug fix concerning call of chomp();
# update of pod documentation.
#
# Revision 1.2  2007/01/21 15:07:20  creile
# some beautifications;
# writing/deleting PID file added.
#
# Revision 1.1  2007/01/20 08:22:52  creile
# initial revision
#
#
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Errno                           - System errno constants
#   Getopt::Long                    - processing options
#   IO::Select                      - OO interface to the select system call
#   IO::Socket                      - Object interface to socket communications
#   Net::hostent                    - by-name interface to Perl's built-in
#                                     gethost*() functions
#   strict                          - restricting unsafe constructs
#   Tie::RefHash                    - use references as hash keys
#
#   Hardware::UPS::Perl::Connection - importing a Hardware::UPS::Perl connection
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with log files
#   Hardware::UPS::Perl::PID        - importing Hardware::UPS::Perl methods
#                                     dealing with PID files
#
#==============================================================================

use Errno qw(
    EWOULDBLOCK
);
use Getopt::Long;
use IO::Select;
use IO::Socket::INET;
use Net::hostent;
use strict;
use Tie::RefHash;

use Hardware::UPS::Perl::Connection;
use Hardware::UPS::Perl::Constants qw(
    UPSFQDN
    UPSLOGFILE
    UPSPIDFILE
    UPSPORT
    UPSSCRIPT
    UPSTCPPORT
);
use Hardware::UPS::Perl::General;
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::PID;

#==============================================================================
# defining global variables:
#------------------------------------------------------------------------------
#
#   $DebugLevel             - the debug level
#   $Logger                 - the UPS logging object
#   $Pid                    - the PID file object
#   $Port                   - the actual serial device the UPS is located on
#   $TCPPort                - the TCP/IP port address
#   %ClientInfo             - hash containing client information (IP address
#                             and/or the FQDN)
#   %RequestBuffer          - hash holding the incoming requests of the clients
#   %ResponseBuffer         - hash holding the UPS responses for each client
#   %HandlingBuffer         - hash holding the final requests ready to be sent
#                             to the UPS
#
#==============================================================================

use vars qw(
    $DebugLevel
    $Logger
    $Port
    $Pid
    $TCPPort
    %ClientInfo
    %RequestBuffer
    %ResponseBuffer
    %HandlingBuffer
);

#==============================================================================
# defining subroutines:
#==============================================================================

sub Init {

    # subroutine for initializing the working environment

    # initializing the working environment
    InitWE();

    # revision number
    use constant REVISION_VERSION   => sprintf(
        "%d.%02d",     q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/
    );

    # revison date
    use constant REVISION_DATE      => sprintf(
        "%d/%02d/%02d", q$Date: 2007/04/17 19:52:44 $ =~ /(\d+)\/(\d+)\/(\d+)/
    );

    # initializing buffers
    %ClientInfo     = ();

    %RequestBuffer  = ();
    %ResponseBuffer = ();
    %HandlingBuffer = ();

    tie %ClientInfo    , 'Tie::RefHash';

    tie %RequestBuffer , 'Tie::RefHash';
    tie %ResponseBuffer, 'Tie::RefHash';
    tie %HandlingBuffer, 'Tie::RefHash';

    # setting the timeout
    use constant TIMEOUT    =>  0.1;

} # end of subroutine "Init"


sub GetParameters {

    # subroutine for getting and checking options

    # hidden local variables
    my $debugLevel;         # switch to specify the debug level
    my $tcpPort;            # switch to specify the TCP/IP port to listen to
    my $logFile;            # switch to specify the log file
    my $pidFile;            # switch to specify the PID file
    my $help;               # switch for displaying usage help
    my $manpage;            # switch for displaying man page
    my $version;            # switch for displaying version information
    my $return;             # returning error

    # configuring subroutine `GetOptions': case sensitivity
    &Getopt::Long::config("no_ignore_case");

    # getting options
    $return = GetOptions(
        "debug-level|d:i"   => \$debugLevel ,
        "logfile|L=s"       => \$logFile    ,
        "pidfile|p=s"       => \$pidFile    ,
        "port|P=i"          => \$tcpPort    ,
        "help|h"            => \$help       ,
        "man|M"             => \$manpage    ,
        "version|V"         => \$version    ,
    );

    # checking all options
    Usage(1)  if ( ! $return );

    # displaying usage help and exit without errors
    Usage(0)  if ( $help );

    # displaying man page and exit without errors
    ManPage() if ( $manpage );

    # displaying version information and exit without errors
    if ( $version ) {
        Version(
            REVISION_VERSION,
            REVISION_DATE,
            "enables remote control over a local UPS on a serial device"
        );
    }

    # checking individual options
    #
    # setting the debug level
    if ( defined($debugLevel) ) {
        $DebugLevel = $debugLevel ? $debugLevel : 1;
    }
    else {
        $DebugLevel = 0;
    }

    # setting the TCP/IP port
    $TCPPort     = $tcpPort       ? $tcpPort    : UPSTCPPORT;

    # setting the serial port
    $Port        = $ARGV[0]       ? $ARGV[0]    : UPSPORT;

    # opening the log file
    if ($logFile) {
        $Logger = Hardware::UPS::Perl::Logging->new({
            File    => $logFile   ,
            Scheme  => "daily"    ,
        });
    }
    else {
        $Logger = Hardware::UPS::Perl::Logging->new({
            File    => UPSLOGFILE,
            Scheme  => "daily"    ,
        });
    }
    if (!defined  $Logger) {
        Error("creating logger failed -- $UPSERROR");
    }

    SetLogger($Logger);

    # writing the PID file
    if ($pidFile) {
        $Pid = Hardware::UPS::Perl::PID->new({
            PIDFile => $pidFile   ,
            Logger  => $Logger    ,
        });
    }
    else {
        $Pid = Hardware::UPS::Perl::PID->new({
            PIDFile => UPSPIDFILE,
            Logger  => $Logger    ,
        });
    }
    unless (defined $Pid) {
        $Logger->fatal("PID file creation failed -- $UPSERROR");
    }

    SetPID($Pid);

} # end of subroutine "GetParameters"


sub Usage {

    # subroutine for displaying a short usage help and exiting, if
    # $exitStatus >= 0;
    #
    # parameters: $exitStatus (input) - status on exit

    # input as hidden local variable
    my $exitStatus = shift;

    # displaying short usage help on STDOUT
    print <<EOF;
Usage: ${\(UPSSCRIPT)} [options] [device-name]
Argument:
   device-name                      the (optional) serial device name
                                    [${\(UPSPORT)}]
Options:
   -h, --help                       Displays this help message.
   -M, --man                        Displays the man page of "${\(UPSSCRIPT)}".
   -V, --version                    Displays version information.
   -d, --debug-level [debuglevel]   sets the optional debug level
                                    debuglevel [debuglevel=1].
   -L, --logfile [logfile]          sets the log file to logfile
                                    [logfile=${\(UPSLOGFILE)}.YYYY-MM-DD.x]
   -p, --pidfile pidfile            sets the PID file to be used to pidfile
                                    [pidfile=/var/run/${\(UPSPIDFILE)}].
   -P, --port port                  sets the TCP/IP port to listen to for
                                    incoming requests [port=${\(UPSTCPPORT)}].

EOF

    # exiting, if $exitStatus >= 0
    exit $exitStatus;

} # end of subroutine "Usage"

#==============================================================================
# start of main body:
#==============================================================================

# hidden local variables
my $connection;         # the connection object to local UPS
my $serverSocket;       # the server socket
my $clientSocket;       # a client socket
my $selectObject;       # the select object
my $request;            # the request buffer
my $command;            # the command to be sent to the UPS
my $response;           # the response
my $responseSize;       # the size of the response buffer
my $return;             # the number of bytes received or sent
my $clientInfo;         # temporary client info

# initializing of working environment
Init();

# getting options
GetParameters();

# connecting to the local UPS
$connection = Hardware::UPS::Perl::Connection->new({
    Type    =>  "serial",
    Options =>  {
                    SerialPort  => $Port,
                },
    Logger  =>  $Logger,
});

if (!defined $connection) {
    $Logger->fatal("serial connection to $Port failed -- $UPSERROR");
}

$connection->getConnectionHandle()->setDebugLevel($DebugLevel);

# opening a listening socket
$serverSocket = new IO::Socket::INET (
    LocalHost   => UPSFQDN  ,
    LocalPort   => $TCPPort ,
    Listen      => SOMAXCONN,
    Proto       => "tcp"    ,
    ReuseAddr   => 1        ,
    Blocking    => 0        ,
);
if (!defined $serverSocket) {
    $Logger->fatal("unable to create server socket -- $!");
}

$selectObject = IO::Select->new($serverSocket)
    or $Logger->fatal("unable to create select object -- $!");

##### loops here until killed #####
RUN:
while (1) {

    # reading
    READING_CLIENT:
    foreach $clientSocket ($selectObject->can_read(TIMEOUT)) {

        if ($clientSocket == $serverSocket) {

            # new connection
            my $newClientSocket = $serverSocket->accept();
            my $hostinfo        = gethostbyaddr($newClientSocket->peeraddr());
            my $hostaddr        = $newClientSocket->peerhost();

            $clientInfo         = $hostinfo
                                ? $hostinfo->name().q{ (}.$hostaddr.q{)}
                                : $hostaddr
                                ;

            $Logger->info("connection received from ".$clientInfo);
            $ClientInfo{$newClientSocket} = $clientInfo;

            $selectObject->add($newClientSocket);
            
            # setting non-blocking mode to socket
            $newClientSocket->blocking(0);

        }
        else {

            # reading data
            $request = q{};
            $return  = $clientSocket->recv($request, 1024, 0);

            if (defined $return and length($request)) {

                $RequestBuffer{$clientSocket} .= $request;

                if ($RequestBuffer{$clientSocket} =~ s/(.*)\n//) {
                    $HandlingBuffer{$clientSocket} = $1;
                }

            }
            else {

                # end of receive, closing client
                $clientInfo = delete $ClientInfo{$clientSocket};
                $Logger->info("connection to $clientInfo closed");

                delete $RequestBuffer{$clientSocket};
                delete $ResponseBuffer{$clientSocket};
                delete $HandlingBuffer{$clientSocket};

                $selectObject->remove($clientSocket);
                $clientSocket->close();

              next READING_CLIENT;  

            }

        }

    }

    # handling requests
    HANDLING:
    foreach $clientSocket (keys %HandlingBuffer) {

        $request  = delete $HandlingBuffer{$clientSocket};
        ($command, $responseSize) = split(//, $request);

        $response = q{};

        if (!$connection->sendCommand($command, \$response, $responseSize)) {
            $Logger->error(
                "sending command <$command> failed -- ".$connection->getErrorMessage()
            );
        }

        chomp($response);

        if ($DebugLevel > 0) {
            $Logger->debug("command <$command> => response: <$response>");
        }

        $ResponseBuffer{$clientSocket} = $response . "\n";
    }

    # sending responses back
    WRITING_CLIENT:
    foreach $clientSocket ($selectObject->can_write(TIMEOUT)) {

        # skipping client without response
      next WRITING_CLIENT if (!exists $ResponseBuffer{$clientSocket});  

        # sending response
        $response = $ResponseBuffer{$clientSocket};

        $return   = $clientSocket->send($response, 0);

        if (!defined $return) {
            $Logger->error("could not deliver message -- $!");
          next WRITING_CLIENT;
        }

        my $responseSize = length($response);

        if ($responseSize == $return || EWOULDBLOCK == $!) {
            
            substr($ResponseBuffer{$clientSocket}, 0, $return) = q{};
            if (!$responseSize) {
                delete $ResponseBuffer{$clientSocket} 
            }

        }
        else {

            # closing connection
            $clientInfo = delete $ClientInfo{$clientSocket};
            $Logger->info("connection to $clientInfo closed");

            delete $RequestBuffer{$clientSocket};
            delete $ResponseBuffer{$clientSocket};
            delete $HandlingBuffer{$clientSocket};

            $selectObject->remove($clientSocket);
            $clientSocket->close();

          next WRITING_CLIENT;

        }

    }

    # handling out of band data
    OUT_OF_BAND:
    foreach $clientSocket ($selectObject->has_exception(0)) {
       $Logger->error(
           "out of band data for connection to host ".$ClientInfo{$clientSocket}
       );
    } 

}

# exiting
exit 0;
