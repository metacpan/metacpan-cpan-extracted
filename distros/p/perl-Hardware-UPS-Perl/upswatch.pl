#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# Perl script to watch an UPS using an Hardware::UPS::Perl driver either via
# a running UPS agent or directly on a serial device, originally written by
# Bernd Holzhauer, www.cc-c.de, October 2006
#==============================================================================

#==============================================================================
# embedded pod documentation:
#------------------------------------------------------------------------------

=head1 NAME

upswatch - watches an UPS using an Hardware::UPS::Perl driver indirectly via
TCP or directly on a serial device

=head1 SYNOPSIS

B<upswatch>
S<[ B<-h>, B<--help> ]> S<[ B<-M>, B<--man> ]> S<[ B<-V>, B<--version> ]>
S<[ B<-D>, B<--driver> I<driver> ]>
S<[ B<-d>, B<--debug-level> [I<debuglevel>] ]>
S<[ B<-g>, B<--grace-period> I<grace> ]>
S<[ B<-L>, B<--logfile> I<logfile> ]>
S<[ B<-l>, B<--loop-time> I<loop> ]>
S<[ B<-m>, B<--mailto> I<mailto> ]>
S<[ B<-p>, B<--pidfile> I<pidfile> ]>
S<[ B<-r>, B<--remote> [I<HOST:[PORT]> ]>
[I<device-name>]

=head1 DESCRIPTION

B<upswatch> watches an UPS using a driver specified on the command line. There
are to ways of operating:

On the one hand, the UPS can reside on a local serial device specified by the
optional F<device-name> parameter. If the parameter is omitted, F</dev/ttyS0>,
i.e. the COM1 port, is used per default unless overriden by the environment
variable F<UPS_DEVICE>.

On the other hand, the UPS can be watched via TCP/IP, if there is an UPS agent
running at a remote host specified by the F<--remote> option.

The program examines the UPS every F<loop> seconds. For a period of one hour
the minimum and maximum line voltage and frequency are determined. At each
full hour these values are written to the syslog.

If the line voltage fails, the computer will be shutdown down savely after a
grace period of F<grace> minutes. If the line voltage returns within this
period of time, the program will switch back to standard monitoring. Both
events will be noted in the syslog. If a mail address F<mailto> is provided, a
mail will be sent to the corresponding recipient. This will be the case as
well if the environment variable F<UPS_MAILTO> is set.

All messages will be logged in a logfile specified by the B<-L> or
B<--logfile> option, if available, F</var/run/upswatch.log>, otherwise.

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
verbosity. The maximum is 5. If the debug level option is used the system will
not shutdown automatically.

=item B<-g>, B<--grace-period> I<grace>

Sets the grace period I<grace> in minutes after that the system will be safely
shutdown, if the line voltages failes. If not specified, a default value of 5
minutes is used.

=item B<-L>, B<--logfile> I<logfile>

Sets the logfile to I<logfile>. If this option is not specified, the
default logfile F</var/run/upswatch.log> will be used.

=item B<-l>, B<--loop-time> I<loop>

Sets the loop time I<loop> in seconds, the UPS is examined. If not specified,
a default value of 10 seconds is used.

=item B<-m>, B<--mailto> I<mailto>

Sets the mail address to I<mailto>. If not specified, no mail will be sent at
all unless the environment variable F<UPS_MAILTO> is set.

=item B<-p>, B<--pidfile> I<pidfile>

Sets the PID file to I<pidfile>. If this option is not specified, the default
PID file F</var/run/upswatch.pid> will be used.

=item B<-r>, B<--remote> [I<HOST[:PORT]>]

Switches to the remote operation modus, i.e. the UPS is watched via TCP/IP
using a remotely running UPS agent. The remote site is specified by the
F<HOST> and optionally the TCP port F<PORT> separated by ':'. If not
specified, the local host's default FQDN will be used together with default
TCP port F<9050>.

=back

=head1 EXAMPLES

=over 4

=item B<upswatch>

Monitors the UPS on COM1 every 10 seconds and performes a safe shutdown, if
the line voltage fails for more than 5 minutes.

=item B<upswatch> B<-g> I<10> B<-l> I<20> I</dev/ttyS1>

Monitors the UPS on COM2 every 20 seconds with a grace time of 10 minutes,
before the system will be shutdown in case of line voltage failure.

=item B<upswatch> B<-r> I<192.168.1.2:7030>

Monitors the UPS located at host F<192.168.1.2> via an UPS agent listening at
TCP port F<7030> at this host.

=back

=head1 SEE ALSO

groff(1),
less(1),
pod2man(1),
upsadm(1),
upsagent(1),
upsstat(1),
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

Bernd Holzhauer, info@cc-c.de
Christian Reile, Christian.Reile@t-online.de

=cut

#==============================================================================
# Entries for revision control:
#------------------------------------------------------------------------------
# Revision        : $Revision: 1.13 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:53:49 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: upswatch.pl,v $
# Revision 1.13  2007/04/17 19:53:49  creile
# unnecessary comments removed.
#
# Revision 1.12  2007/04/14 09:37:26  creile
# documentation update.
#
# Revision 1.11  2007/04/07 15:24:33  creile
# adaptations to "best practices" style;
# update of documentation.
#
# Revision 1.10  2007/03/13 17:25:32  creile
# adaptations to options as anonymous hashes;
# restart possibility added.
#
# Revision 1.9  2007/03/03 21:30:49  creile
# new variable $UPSERROR added;
# adaptations to new Constants.pm;
# call of getMinMax() replaced by printMinMax().
#
# Revision 1.8  2007/02/25 17:11:30  creile
# connection handling added;
# no fatal shutdown anymore if you get no data from UPS.
#
# Revision 1.7  2007/02/05 20:52:40  creile
# OO PID files and logging (log file) added;
# loading of driver;
# uninterruptible sleep;
# pod documentation revised.
#
# Revision 1.6  2007/01/28 05:38:01  creile
# adaptations to new package structure;
# network support added;
# pod documentation revised.
#
# Revision 1.5  2007/01/21 15:09:17  creile
# some beautifications;
# output of UPS info just in case of debug modus.
#
# Revision 1.4  2007/01/20 15:08:47  creile
# minor corrections due to CVS errors;
# bugfix concerning shutdown grace period.
#
# Revision 1.3  2007/01/20 11:30:48  creile
# cleam up for CVS errors
#
# Revision 1.2  2007/01/20 08:28:01  creile
# almost a complete rewrite.
#
#
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Getopt::Long                    - processing options
#   Time::HiRes                     - high resolution alarm, sleep,
#                                     gettimeofday, interval timers
#   strict                          - restricting unsafe constructs
#
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with log files
#   Hardware::UPS::Perl::PID        - importing Hardware::UPS::Perl methods
#                                     dealing with PID files
#
#==============================================================================

use Getopt::Long;
use Time::HiRes qw(
    time
    sleep
);
use strict;

use Hardware::UPS::Perl::Constants qw(
    UPSFQDN
    UPSLOGFILE
    UPSMAILTO
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
#   $Driver                 - the actual driver to use
#   $GracePeriod            - the actual grace period in minutes
#   $Host                   - the host the UPS resides
#   $Logger                 - the UPS logging object
#   $LoopTime               - the actual loop time in seconds (minus 2)
#   $MailTo                 - the mail address
#   $Pid                    - the PID file object
#   $Port                   - the actual serial device the UPS is located on
#
#==============================================================================

use vars qw(
    $DebugLevel
    $Driver
    $GracePeriod
    $Host
    $Logger
    $LoopTime
    $MailTo
    $Pid
    $Port
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
        "%d.%02d",      q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/
    );

    # revison date
    use constant REVISION_DATE      => sprintf(
        "%d/%02d/%02d", q$Date: 2007/04/17 19:53:49 $ =~ /(\d+)\/(\d+)\/(\d+)/
    );

    # the default driver
    use constant DRIVER             => "Megatec";

    # the default grace period before the system will shutdown if power fails.
    use constant GRACE_PERIOD       =>   5;

    # the default loop time
    use constant LOOP_TIME          =>  10;

} # end of subroutine "Init"


sub GetParameters {

    # subroutine for getting and checking options

    # hidden local variables
    my $debugLevel;         # switch to specify the debug level
    my $driver;             # switch to specify the driver to load
    my $gracePeriod;        # switch to specify the grace period
    my $host;               # switch to specify the host the UPS resides
    my $logFile;            # switch to specify the log file
    my $loopTime;           # switch to specify the loop time
    my $mailTo;             # switch to specify the mail address
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
        "driver|D=s"        => \$driver     ,
        "grace-period|g=i"  => \$gracePeriod,
        "logfile|L=s"       => \$logFile    ,
        "loop-time|l=i"     => \$loopTime   ,
        "mailto|m=s"        => \$mailTo     ,
        "pidfile|P=s"       => \$pidFile    ,
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
        Version(REVISION_VERSION, REVISION_DATE, "watches an UPS");
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

    # setting the grace period
    $GracePeriod = $gracePeriod ? $gracePeriod : GRACE_PERIOD;

    # setting the actual loop time
    $LoopTime    = $loopTime    ? $loopTime    : LOOP_TIME;

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

    } else {

        # local watch
        $Host    = q{};

        # setting the serial port
        $Port    = $ARGV[0]  ? $ARGV[0]        : UPSPORT;

    }

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
            Scheme  => "daily"   ,
        });
    }
    if (!defined $Logger) {
        Error("creating logger failed -- $UPSERROR");
    }

    SetLogger($Logger);

    # setting the mail address
    $MailTo = $mailTo ? $mailTo : UPSMAILTO;
    if ($MailTo) {
        $Logger->setMailTo($MailTo);
    }

    # writing the PID file
    if ($pidFile) {
        $Pid = Hardware::UPS::Perl::PID->new({
            PIDFile => $pidFile  ,
            Logger  => $Logger   ,
        });
    }
    else {
        $Pid = Hardware::UPS::Perl::PID->new({
            PIDFile => UPSPIDFILE,
            Logger  => $Logger   ,
        });
    }
    if (!defined $Pid) {
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
   -D, --driver driver              sets the driver to use [driver=${\(DRIVER)}].
   -d, --debug-level [debuglevel]   sets the optional debug level
                                    debuglevel [debuglevel=1].
   -g, --grace-period grace         sets the grace period in minutes
                                    [grace=${\(GRACE_PERIOD)}min].
   -L, --logfile logfile            sets the log file to logfile
                                    [logfile=${\(UPSLOGFILE)}.YYYY-MM-DD.x]
   -l, --loop-time loop             sets the loop time in seconds
                                    [loop=${\(LOOP_TIME)}s].
   -m, --mailto mailto              sends a mail to address mailto,
                                    if power fails or comes back
                                    [mailto=${\(UPSMAILTO)}].
   -p, --pidfile pidfile            sets the PID file to be used to pidfile
                                    [pidfile=/var/run/${\(UPSPIDFILE)}].
   -r, --remote [HOST[:PORT]]       connects to (remote) UPS agent running
                                    at host HOST and TCP port PORT
                                    [HOST=${\(UPSFQDN)}, PORT=${\(UPSTCPPORT)}].

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
my $date;               # the current date
my $hour;               # the current hour
my $minute;             # the current minute
my $lastHour   = -1;    # the previous hour
my $lastMinute = -1;    # the pervious minute
my $epoch;              # the current epoch in seconds
my $lastEpoch;          # the pervious epoch in seconds
my $wait;               # waiting period in seconds
my $powerfail  = 0;     # flag indicating that the power has failed
my $offline;            # time left before shutdown
my $message;            # general message string

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

# writing UPS information to log file
if ($ups->readUPSInfo()) {
    $ups->printUPSInfo("info");
}
else {
    $Logger->error(
        "getting UPS information failed -- ".$ups->getErrorMessage()
    );
}

# reading UPS Rating Info
if (!$ups->readRatingInfo()) {
    $Logger->error(
        "getting UPS rating info failed -- ".$ups->getErrorMessage()
    );
}

##### loops here until killed #####
$lastEpoch = time;

WATCH:
while (1) {

    $date   =  scalar localtime;
    $date   =~ /(..):(..):(..)/;
    $hour   =  $1;
    $minute =  $2;

    ##### read UPS Status #####
    if (!$ups->readStatus()) {
        $Logger->error(
            "getting UPS status failed -- ".$ups->getErrorMessage()
        );
    }

    if ($DebugLevel > 1) { ### more output
        if (!$ups->printData("info")) {
            $Logger->error(
                "printing UPS data failed -- ".$ups->getErrorMessage()
            );
        }
    }

    ##### Power fail #####
    my $powerStatus    = $ups->getPowerStatus();
    my $batteryVoltage = $ups->getBatteryVoltage();
    my $upsLoad        = $ups->getUPSLoad();

    if ($powerStatus) {
        if (!$powerfail) {

            $message = "Power failed - Battery=".$batteryVoltage
                     ."V - Load=".$upsLoad."%";

            if ($DebugLevel > 0) {
                $Logger->debug("*** $message ***");
            }

            $Logger->syslog($message);

            if ($MailTo) {
                if (!$Logger->sendmail({Subject => $message})) {
                    $Logger->error(
                        "sending mail failed -- ".$Logger->getErrorMessage()
                    );
                }
            }

            $offline = $GracePeriod + 1;
        }

        $powerfail = 1;

        if (!$ups->printStatus("info")) {
            $Logger->error(
                "printing UPS status failed -- ".$ups->getErrorMessage()
            );
        };
    }

    ##### Power Back #####
    if (!$powerStatus and $powerfail) {

        my $inputVoltage = $ups->getInputVoltage();
        $message = "Power back online - Input Voltage=".$inputVoltage."V";

        if ($DebugLevel > 0) {
            $Logger->debug("*** $message ***");
        }

        $Logger->syslog($message);

        if ($MailTo) {
            if (!$Logger->sendmail({Subject => $message})) {
                $Logger->error(
                    "sending mail failed -- ".$Logger->getErrorMessage()
                );
            }
        }

        $powerfail = 0;

    }

    ### Job once per Minute
    if ($lastMinute ne $minute) {

        if ($DebugLevel > 0) {

            if (!$ups->printData("info")) {
                $Logger->error(
                    "printing UPS data failed -- ".$ups->getErrorMessage()
                );
            }

            if (!$ups->printStatus("info")) {
                $Logger->error(
                    "printing UPS status failed -- ".$ups->getErrorMessage()
                );
            }
        }

        if ($powerStatus) {

            $Logger->syslog(
                "Power failed - Battery=${batteryVoltage}V - Load=${upsLoad}%"
            );

            $offline -= 1;

            $message = "Shutdown in $offline minutes";

            $Logger->syslog($message);
            if ($DebugLevel > 0) {
                $Logger->debug($message);
            }

            if (!$offline) {

                $message = "System will be shutdown by UPS";

                $Logger->syslog($message);

                if ($MailTo) {
                    if (!$Logger->sendmail({Subject => $message})) {
                        $Logger->error(
                            "sending mail failed -- ".$Logger->getErrorMessage()
                        );
                    }
                }

                if ($DebugLevel > 0) {
                    $Logger->debug("shutdown -h now");
                }
                else {
                    system "shutdown -h now";
                }

            }
        }
    }

    ### Job once per hour
    if ($lastHour ne $hour) {

        if ($DebugLevel > 0) {
            $Logger->info("*** HOUR ***");
        }

        if ($lastHour < 0) {
            $message = "Program Start at $date";
            if ($DebugLevel > 0) {
                $Logger->info($message);
            }
            $Logger->syslog($message);
        }

        if ($DebugLevel > 0) {
            $ups->printMinMax("info");
        }
        $ups->printMinMax("syslog");

        # reset of current values of line voltage and frequency
        $ups->resetMinMax();

    }

    $epoch      = time;
    $wait       = $LoopTime - ( $epoch - $lastEpoch );

    # uninterruptible sleep due to ALARM signal handler in logger
    SLEEP:
    while (0 <= $wait) {
        my $slept = sleep($wait);
        $wait -= $slept;
    }

    $lastHour   = $hour;
    $lastMinute = $minute;
    $lastEpoch  = time;

}

# exiting
exit 0;
