#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# Perl script to get informations about the current UPS status, the comparison
# between the rating and current status and the manufacturer using an
# Hardware::UPS::Perl driver either via a running UPS agent or directly on a
# serial device.
#==============================================================================

#==============================================================================
# embedded pod documentation:
#------------------------------------------------------------------------------

=head1 NAME

upsstat - gets informations about the UPS using an Hardware::UPS::Perl
driver indirectly via TCP or directly on a serial device

=head1 SYNOPSIS

B<upsstat>
S<[ B<-h>, B<--help> ]> S<[ B<-M>, B<--man> ]> S<[ B<-V>, B<--version> ]>
S<[ B<-D>, B<--driver> I<driver> ]>
S<[ B<-d>, B<--debug-level> [I<debuglevel>] ]>
S<[ B<-r>, B<--remote> [I<HOST:[PORT]> ]>
S<[ B<-a>, B<--all> ]>
S<[ B<-c>, B<--comparison> ]>
S<[ B<-i>, B<--info> ]>
S<[ B<-s>, B<--status> ]>
[I<device-name>]

=head1 DESCRIPTION

B<upsstat> gets informations about an UPS itself, its current status and
the comparison between the rating and current data using a driver specified on
the command line and prints them to F<STDOUT>. There are to ways of operating:

On the one hand, the UPS can reside on a local serial device specified by the
optional F<device-name> parameter. If the parameter is omitted, F</dev/ttyS0>,
i.e. the COM1 port, is used per default unless overriden by the environment
variable F<UPS_DEVICE>.

On the other hand, the UPS informations can be retrieved via TCP/IP, if there
is an UPS agent running at a remote host specified by the F<--remote> option.

=head1 OPTIONS

=over 4

=item B<-h>, B<--help>

Displays a short usage help message and exits without errors.

=item B<-M>, B<--man>

Displays the embedded pod documentation of B<upswatch> (this screen) using
B<pod2man>, B<groff> and B<less> as pager; it exits without errors.

=item B<-V>, B<--version>

Displays version information and exits without errors.

=item B<-D>, B<--driver> I<driver>

Sets the UPS driver I<driver> to use. I<driver> is a case-insensitive string.
If not specified, the default driver "Megatec" is used.

=item B<-d>, B<--debug-level> [I<debuglevel>]

Sets the integer debug level I<debuglevel>. If the debug level is not
specified, a default of 1 is assumed. A higher debug level will increase the
verbosity. The maximum is 5.

=item B<-r>, B<--remote> [I<HOST[:PORT]>]

Switches to the remote operation modus, i.e. the UPS is watched via TCP/IP
using a remotely running UPS agent. The remote site is specified by the
F<HOST> and optionally the TCP port F<PORT> separated by ':'. If not
specified, the local host's default FQDN will be used together with default
TCP port F<9050>.

=item B<-a>, B<--all>

Gets all UPS informations available.

=item B<-c>, B<--comparison>

Gets the comparison between the rating info (firmware data) and the current
data of the UPS.

=item B<-i>, B<--info>

Gets the UPS informations, i.e. the manufacturer, model and the firmware
version.

=item B<-s>, B<--status>

Gets the current UPS status informations; this is the default.

=back

=head1 EXAMPLES

=over 4

=item B<upsstat>

Retrieves the status of an UPS on COM1.

=item B<upsstat> I</dev/ttyS1>

Retrieves the status of an UPS on COM2.

=item B<upsstat> B<-r> I<192.168.1.2:7030>

Connects to an UPS located at host F<192.168.1.2> via an UPS agent listening
at TCP port F<7030> at this host and retrieves its status.

=back

=head1 SEE ALSO

groff(1),
less(1),
pod2man(1),
upsadm(1)
upsagent(1),
upswatch(1),
Getopt::Long(3pm),
Time::HiRes(3pm),
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
# Revision        : $Revision: 1.3 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:53:34 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: upsstat.pl,v $
# Revision 1.3  2007/04/17 19:53:34  creile
# unnecessary comments removed.
#
# Revision 1.2  2007/04/14 09:37:26  creile
# documentation update.
#
# Revision 1.1  2007/04/07 14:53:06  creile
# initial revision.
#
#
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Getopt::Long                    - processing options
#   strict                          - restricting unsafe constructs
#
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with log files
#
#==============================================================================

use Getopt::Long;
use strict;

use Hardware::UPS::Perl::Constants qw(
    UPSFQDN
    UPSPORT
    UPSSCRIPT
    UPSTCPPORT
);
use Hardware::UPS::Perl::General;
use Hardware::UPS::Perl::Logging;

#==============================================================================
# defining global variables:
#------------------------------------------------------------------------------
#
#   $DebugLevel             - the debug level
#   $Driver                 - the actual driver to use
#   $Host                   - the host the UPS resides
#   $Logger                 - the logger
#   $Port                   - the actual serial device the UPS is located on
#   $GetCompareFlag         - flag to get the comparison between the rating
#                             info and the current UPS status
#   $GetInfoFlag            - flag to get the the UPS informations
#   $GetStatusFlag          - flag to get the the current UPS status
#
#==============================================================================

use vars qw(
    $DebugLevel
    $Driver
    $Host
    $Logger
    $Port
    $GetCompareFlag
    $GetInfoFlag
    $GetStatusFlag
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
        "%d.%02d",      q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/
    );

    # revison date
    use constant REVISION_DATE      => sprintf(
        "%d/%02d/%02d", q$Date: 2007/04/17 19:53:34 $ =~ /(\d+)\/(\d+)\/(\d+)/
    );

    # the default driver
    use constant DRIVER             => "Megatec";

} # end of subroutine "Init"


sub GetParameters {

    # subroutine for getting and checking options

    # hidden local variables
    my $debugLevel;         # switch to specify the debug level
    my $driver;             # switch to specify the driver to load
    my $host;               # switch to specify the host the UPS resides
    my $allFlag;            # switch to get all UPS informations available
    my $compareFlag;        # switch to get the rating info and current UPS data
    my $infoFlag;           # switch to get UPS info
    my $statusFlag;         # switch to get the UPS status
    my $help;               # switch for displaying usage help
    my $manpage;            # switch for displaying man page
    my $version;            # switch for displaying version information
    my $return;             # returning error

    # configuring subroutine `GetOptions': case sensitivity
    &Getopt::Long::config("no_ignore_case");

    # getting options
    $return = GetOptions(
        "all|a"             => \$allFlag    ,
        "compare|c"         => \$compareFlag,
        "debug-level|d:i"   => \$debugLevel ,
        "info|i"            => \$infoFlag   ,
        "status|s"          => \$statusFlag ,
        "driver|D=s"        => \$driver     ,
        "remote|r:s"        => \$host       ,
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
        Version(REVISION_VERSION, REVISION_DATE, "returns the UPS status");
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
 
    # the driver to use
    $Driver      = $driver      ? $driver      : DRIVER;

    # tasks
    $GetCompareFlag = 0;
    $GetInfoFlag    = 0;
    $GetStatusFlag  = 1;

    if ($allFlag) {

        $GetCompareFlag = 1;
        $GetInfoFlag    = 1;
        $GetStatusFlag  = 1;

    }
    else {

        if ($compareFlag) {
            $GetCompareFlag = 1;
            $GetStatusFlag  = 0;
        }

        if ($infoFlag) {
            $GetInfoFlag    = 1;
            $GetStatusFlag  = 0;
        }

        if ($statusFlag) {
            $GetStatusFlag  = 1;
        }
    }

    # setting the operation modus
    if (defined $host) {

        # remote watch
        $Host    = $host        ? $host        : UPSFQDN;

        if ($Host =~ /:/) {
            $Host = $`;
            $Port = $';
        }
        else {
            $Port = UPSTCPPORT;
        }

    }
    else {
   
        # local watch
        $Host    = q{};
   
        # setting the serial port
        $Port    = $ARGV[0]  ? $ARGV[0]        : UPSPORT;
   
    }
    
    # setting the logger
    $Logger = Hardware::UPS::Perl::Logging->new({
        File    => \*STDOUT,
    });
    if (!defined $Logger) {
        Error("creating logger failed -- $UPSERROR");
    }

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
   -D, --driver driver              sets the driver to use [driver=${\(DRIVER)}].
   -d, --debug-level [debuglevel]   sets the optional debug level
                                    debuglevel [debuglevel=1].
   -r, --remote [HOST[:PORT]]       connects to (remote) UPS agent running
                                    at host HOST and TCP port PORT
                                    [HOST=${\(UPSFQDN)}, PORT=${\(UPSTCPPORT)}].
   -a, --all                        gets all UPS informations available.
   -c, --comparison                 gets the comparison between the UPS rating
                                    info and the current UPS status.
   -i, --info                       gets the UPS informations about the
                                    manufacturer, the model and the firmware
                                    version.
   -s, --status                     gets the current UPS status; this is the
                                    default.

EOF

    # exiting, if $exitStatus >= 0
    exit $exitStatus;

} # end of subroutine "Usage"

#==============================================================================
# start of main body:
#==============================================================================

# hidden local variables
my $connectOptions;     # the connection options
my $ups;                # the UPS object

# initializing of working environment
Init();

# getting options
GetParameters();

# connecting to UPS
if ($Host) {

    # remotely via TCP
    $connectOptions = {
        Host        => $Host      ,
        TCPPort     => $Port      ,
        DebugLevel  => $DebugLevel,
        Driver      => $Driver    ,
        Logger      => $Logger    ,
    };

}
else {

    # locally via a serial port
    $connectOptions = {
        SerialPort  => $Port      ,
        DebugLevel  => $DebugLevel,
        Driver      => $Driver    ,
        Logger      => $Logger    ,
    };

}

$ups = ConnectUPS($connectOptions);

# reading UPS rating info, the current UPS status and printing the comparison
# to STDOUT
if ($GetCompareFlag) {

    if ($ups->readStatus()) {

        if ($ups->readRatingInfo()) {
            if (!$ups->printData()) {
                Warning(
                    "printing UPS data failed -- ".$ups->getErrorMessage()
                );
            }
        }
        else {
            Warning(
                "getting UPS rating info failed -- ".$ups->getErrorMessage()
            );
        }

    }
    else {

        Warning("getting UPS status failed -- ".$ups->getErrorMessage());
        $GetStatusFlag = 0;

    }

}

# reading UPS information and printing it to STDOUT
if ($GetInfoFlag) {

    if ($ups->readUPSInfo()) {

        if (!$ups->printUPSinfo()) {
            Warning(
                "printing UPS information failed -- ".$ups->getErrorMessage()
            );
        }

    }
    else {
        Warning("getting UPS information failed -- ".$ups->getErrorMessage());
    }

}

# reading UPS Status and printing it to STDOUT
if ($GetStatusFlag) {

    if (!$GetCompareFlag) {
        if (!$ups->readStatus()) {
            Warning("getting UPS status failed -- ".$ups->getErrorMessage());
            $GetStatusFlag = 0;
        }
    }

    if ($GetStatusFlag) {
        if (!$ups->printStatus()) {
            Warning("printing UPS status failed -- ".$ups->getErrorMessage());
        }
    }

}

# exiting
exit 0;
