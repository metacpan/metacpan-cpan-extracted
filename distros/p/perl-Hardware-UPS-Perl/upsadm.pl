#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# Perl script to administrate an UPS using an Hardware::UPS::Perl
# driver either via a running UPS agent or directly on a serial device.
#==============================================================================

#==============================================================================
# embedded pod documentation:
#------------------------------------------------------------------------------

=head1 NAME

upsadm - administrates an UPS using an Hardware::UPS::Perl driver indirectly
via TCP or directly on a serial device

=head1 SYNOPSIS

B<upsadmin>
S<[ B<-h>, B<--help> ]> S<[ B<-M>, B<--man> ]> S<[ B<-V>, B<--version> ]>
S<[ B<-D>, B<--driver> I<driver> ]>
S<[ B<-d>, B<--debug-level> [I<debuglevel>] ]>
S<[ B<-r>, B<--remote> [I<HOST:[PORT]>]>
S<[ B<-T>, B<--toggle-beeper> ]>
S<[ B<-t>, B<--test> [I<period>] ]>
S<[ B<-B>, B<--test-battery-low> ]>
S<[ B<-c>, B<--cancel-test> ]>
S<[ B<-S>, B<--shutdown> I<period> ]>
S<[ B<-R>, B<--restore> I<period> ]>
S<[ B<-C>, B<--cancel-shutdown> ]>
[I<device-name>]

=head1 DESCRIPTION

B<upsadm> is a command line utility to administrate an UPS using a driver
specified on the command line. There are to ways of operating:

On the one hand, the UPS can reside on a local serial device specified by the
optional F<device-name> parameter. If the parameter is omitted, F</dev/ttyS0>,
i.e. the COM1 port, is used per default unless overriden by the environment
variable F<UPS_DEVICE>.

On the other hand, the UPS can be administrated via TCP/IP, if there is an UPS
agent running at a remote host speciefied by the F<--remote> option.

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

=item B<-T>, B<--toggle-beeper>

Toggles the beeper.

=item B<-t>, B<--test> [I<PERIOD>]

Tests the UPS for a period of I<PERIOD> in minutes. If the argument is
omitted, a standard test lasting 10 seconds is performed.

=item B<-B>, B<--test-battery-low>

Tests the UPS until the battery is low.

=item B<-c>, B<--cancel-test>

Cancels any test activity.

=item B<-S>, B<--shutdown> [I<PERIOD>]

Causes the UPS to shutdown in a period of I<PERIOD> minutes.

=item B<-R>, B<--restores> [I<PERIOD>]

Restores the UPS after a period of I<PERIOD> minutes after a shutdown has been
performed. This option requires the option F<--shutdown>.

=item B<-C>, B<--cancel-shutdown>

Cancels any shutdown activity.

=back

=head1 EXAMPLES

=over 4

=item B<upsadm>

Tests the UPS.

=item B<upsadm> -t 10 I</dev/ttyS1>

Tests the UPS on COM2 for 10 minutes.

=item B<upsadm> B<-r> I<192.168.1.2:7030>

Tests the UPS located at host F<192.168.1.2> via an UPS agent listening at
TCP port F<7030> at this host.

=back

=head1 SEE ALSO

groff(1),
less(1),
pod2man(1),
upsagent(1),
upsstat(1),
upswatch(1),
Getopt::Long(3pm),
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
# Last Modified On: $Date: 2007/04/17 19:52:26 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: upsadm.pl,v $
# Revision 1.3  2007/04/17 19:52:26  creile
# unnecessary comments removed.
#
# Revision 1.2  2007/04/14 09:37:26  creile
# documentation update.
#
# Revision 1.1  2007/04/07 14:52:43  creile
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
#   $Logger                 - the UPS logging object
#   $Port                   - the actual serial device the UPS is located on
#   $ToggleBeeperFlag       - flag indicating to toggle the beeper
#   %Test                   - hash indicating what to test
#   %ProcessTest            - action table to process testing
#   $CancelTestFlag         - flag indicating to cancel a test
#   $ShutdownPeriod         - period until the UPS is shut down
#   $RestartPeriod          - period until the UPS is restored again
#   $CancelShutdownFlag     - flag indicating to cancel any shutdown activity
#
#==============================================================================

use vars qw(
    $DebugLevel
    $Driver
    $Host
    $Logger
    $Port
    $ToggleBeeperFlag
    %Test
    %ProcessTest
    $CancelTestFlag
    %Shutdown
    %ProcessShutdown
    $CancelShutdownFlag
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
        "%d/%02d/%02d", q$Date: 2007/04/17 19:52:26 $ =~ /(\d+)\/(\d+)\/(\d+)/
    );

    # the default driver
    use constant DRIVER             => "Megatec";

    # action table to process tests
    %ProcessTest = (
        standard    =>  sub {   # the standard test
                            my $ups = shift;

                            if (!$ups->testUPS()) {
                                Warning(
                                    "testing UPS failed -- "
                                    .$ups->getErrorMessage()
                                ); 
                            }
                        },
        period      =>  sub {   # test for a certain period
                            my $ups    = shift;
                            my $period = shift;

                            if (!$ups->testUPSPeriod($period)) {
                                Warning(
                                    "testing UPS failed -- "
                                    .$ups->getErrorMessage()
                                ); 
                            }
                        },
        batteryLow  =>  sub {   # the test until battery low occurs
                            my $ups = shift;

                            if (!$ups->testUPS()) {
                                Warning(
                                    "testing UPS failed -- "
                                    .$ups->getErrorMessage()
                                ); 
                            }
                        },
    );

    # action table to process shutdowns
    %ProcessShutdown = (
        standard    =>  sub {   # a real shutdown without restore
                            my $ups    = shift;
                            my $period = shift;

                            if (!$ups->shutdownUPS($period)) {
                                Warning(
                                    "shutting UPS down failed -- "
                                    .$ups->getErrorMessage()
                                ); 
                            }
                        },
        restore     =>  sub {   # a shutdown followed be a restore
                            my $ups    = shift;
                            my $period = shift;

                            if (!$ups->shutdownRestore(@{$period})) {
                                Warning(
                                    "shutting UPS down with restore failed -- "
                                    .$ups->getErrorMessage()
                                ); 
                            }
                        },
    );

} # end of subroutine "Init"


sub GetParameters {

    # subroutine for getting and checking options

    # hidden local variables
    my $debugLevel;         # switch to specify the debug level
    my $driver;             # switch to specify the driver to load
    my $host;               # switch to specify the host the UPS resides
    my $toggleBeeper;       # switch to sepcify the beeper's toogle
    my $testPeriod;         # switch to sepcify the test period
    my $testBatteryLow;     # switch to sepcify the test the UPS until battery low
    my $cancelTest;         # switch to sepcify a cancelling of a test
    my $shutdownPeriod;     # switch to sepcify the shutdown period of an UPS
    my $restorePeriod;      # switch to sepcify the restore period of an UPS
    my $cancelShutdown;     # switch to sepcify a cancelling of a shutdown
    my $help;               # switch for displaying usage help
    my $manpage;            # switch for displaying man page
    my $version;            # switch for displaying version information
    my $return;             # returning error

    # configuring subroutine `GetOptions': case sensitivity
    &Getopt::Long::config("no_ignore_case");

    # getting options
    $return = GetOptions(
        "debug-level|d:i"   => \$debugLevel    ,
        "driver|D=s"        => \$driver        ,
        "remote|r:s"        => \$host          ,
        "toggle-beeper|T"   => \$toggleBeeper  ,
        "test|t:s"          => \$testPeriod    ,
        "test-low|B"        => \$testBatteryLow,
        "cancel-test|c"     => \$cancelTest    ,
        "shutdown|S=s"      => \$shutdownPeriod,
        "restore|R=s"       => \$restorePeriod ,
        "cancel-shutdown|C" => \$cancelShutdown,
        "help|h"            => \$help          ,
        "man|M"             => \$manpage       ,
        "version|V"         => \$version       ,
    );

    # checking all options
    Usage(1)  if ( ! $return );

    # displaying usage help and exit without errors
    Usage(0)  if ( $help );

    # displaying man page and exit without errors
    ManPage() if ( $manpage );

    # displaying version information and exit without errors
    if ( $version ) {
        Version(REVISION_VERSION, REVISION_DATE, "administrates an UPS");
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
    $Driver = $driver ? $driver : DRIVER;

    # tasks
    #
    # toggling of the beeper
    $ToggleBeeperFlag = $toggleBeeper ? $toggleBeeper : undef;

    # testing the UPS
    if ($testBatteryLow and $testPeriod) {
        Error("excluding options --test-battery-low and --test");
    }
    else {

        if (defined $testBatteryLow) {
            $Test{batteryLow}   = 1;
        }
        else {
            if (defined $testPeriod) {
                if ($testPeriod) {
                    $Test{period}   = $testPeriod;
                }
                else {
                    $Test{standard} = 1;
                }
            }
        }

    }

    # cancel test
    $CancelTestFlag = $cancelTest ? $cancelTest : 0;

    # shutdown of the UPS
    if ($restorePeriod and !$shutdownPeriod) {
        Error("option --restore requires --shutdown");
    }
    else {

        if ($restorePeriod) {
            $Shutdown{restore} = [
                $shutdownPeriod,
                $restorePeriod,
            ];
        }
        elsif ($shutdownPeriod) {
            $Shutdown{standard} = $shutdownPeriod;
        }

    }

    # cancel shutdown
    $CancelShutdownFlag = $cancelShutdown ? $cancelShutdown : 0;

    # setting the operation modus
    if (defined $host) {

        # remote watch
        $Host    = $host ? $host : UPSFQDN;

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
        $Port    = $ARGV[0] ? $ARGV[0] : UPSPORT;

    }

    # opening the log file
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
   -D, --driver driver              Sets the driver to use [driver=${\(DRIVER)}].
   -d, --debug-level [debuglevel]   Sets the optional debug level
                                    debuglevel [debuglevel=1].
   -r, --remote [HOST[:PORT]]       Connects to (remote) UPS agent running
                                    at host HOST and TCP port PORT
                                    [HOST=${\(UPSFQDN)}, PORT=${\(UPSTCPPORT)}].
   -T, --toogle-beeper              Toggles the beeper-
   -t, --test [PERIOD]              Tests the UPS for a period of PERIOD
                                    minutes; if the argument is omitted, a
                                    standard test of 10 secondes is performed.
   -B, --test-battery-low           Tests the UPS until the battery is low.
   -c, --cancel-test                Cancels any test activity.
   -S, --shutdown PERIOD            Performs a shutdown of the UPS in after
                                    a period of PERIOD minutes.
   -R, --restore PERIOD             Restores the UPS after a period of PERIOD
                                    minutes;
                                    requires the --shutdown option. 
   -C, --cancel-shutdown            Cnacels any shutdown activity.

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

# toggle the beeper
if (defined $ToggleBeeperFlag) {
    $ups->toggleBeeper();
}

# testing the UPS
TEST_UPS:
while (my ($testType, $arg) = each %Test) {
    $ProcessTest{ $testType }->($ups, $arg);
}

# cancel UPS test
if ($CancelTestFlag) {
    $ups->cancelTest()
        or Warning("cancel of testing UPS failed -- ".$ups->getErrorMessage());
}

# shutting the UPS down
SHUTDOWN_UPS:
while (my ($shutdownType, $arg) = each %Shutdown) {
    $ProcessShutdown{ $shutdownType }->($ups, $arg);
}

# cancel UPS shutdown
if ($CancelShutdownFlag) {
    $ups->cancelShutdown()
        or Warning("cancel of UPS shutdown failed -- ".$ups->getErrorMessage());
}

# exiting
exit 0;
