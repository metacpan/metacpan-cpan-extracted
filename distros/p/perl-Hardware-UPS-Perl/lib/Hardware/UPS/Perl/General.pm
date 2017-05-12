package Hardware::UPS::Perl::General;

#==============================================================================
# package description:
#==============================================================================
# This package defines the following subroutines to be used in Perl scripts
# dealing with an UPS. For a detailed description see the pod documentation
# included at the end of this file.
#
# Variables:
# ----------
#   $UPSERROR       - the global error text
#
# Subroutines:
# ------------
#   &InitWE         - initializing working environment
#   &Catch          - signal handler
#   &Error          - displaying error messages and exit
#   &Warning        - displaying warning messages
#   &ManPage        - displaying man page of `UPSSCRIPT'
#   &Version        - displaying version information of `UPSSCRIPT'
#   &SetLogger      - setting the logger
#   &SetPID         - setting the PID object
#   &ConnectUPS     - connecting to the UPS
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
# Revision        : $Revision: 1.15 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:46:00 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: General.pm,v $
#   Revision 1.15  2007/04/17 19:46:00  creile
#   documentation bugfixes.
#
#   Revision 1.14  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.13  2007/04/07 15:18:20  creile
#   new function ConnectUPS() added;
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.12  2007/03/13 17:04:09  creile
#   new subroutines SetLogger() and SetPID();
#   prototypes removed;
#   restarting by catching signal HUP implemented.
#
#   Revision 1.11  2007/03/03 21:14:31  creile
#   new variable $UPSERROR added;
#   adaptations to revised Constants.pm.
#
#   Revision 1.10  2007/02/05 20:33:17  creile
#   pod documentation revised.
#
#   Revision 1.9  2007/02/04 19:10:25  creile
#   bug fix of pod documentation.
#
#   Revision 1.8  2007/02/04 14:03:31  creile
#   bug fix in pod documentation.
#
#   Revision 1.7  2007/02/03 16:03:58  creile
#   all variables moved to new package
#   Hardware::UPS::Perl::Constants;
#   subroutine SendMail() incorporated into new package
#   Hardware::UPs::Perl::Logging;
#   subroutines WritePIDFile() and DeletePIDFile() removed
#   because of OO PID file handling;
#   cleanup for unnecessary packages;
#   update of documentation.
#
#   Revision 1.6  2007/01/28 21:05:47  creile
#   exclusion of signal TERM from error handling in subroutine
#   &Catch().
#
#   Revision 1.5  2007/01/28 05:26:44  creile
#   bug fix concerning pod documentation.
#
#   Revision 1.4  2007/01/27 16:08:57  creile
#   rename to Hardware::UPS::Perl::General;
#   removal of unnecessary comments;
#   variables exported prepended by UPS.
#
#   Revision 1.3  2007/01/21 15:05:09  creile
#   some beautifications.
#
#   Revision 1.2  2007/01/20 16:05:34  creile
#   subroutine &SendMail() revised
#
#   Revision 1.1  2007/01/20 08:10:54  creile
#   initial revision
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {
    use Exporter ();
    use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION     = sprintf( "%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/ );

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
        $UPSERROR
        &InitWE
        &Catch
        &Error
        &Warning
        &ManPage
        &Version
        &SetPID
        &SetLogger
        &ConnectUPS
    );
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = qw();

}

use vars @EXPORT, @EXPORT_OK;

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   POSIX                           - Perl interface to IEEE Std 1003.1
#
#   Hardware::UPS::Perl::Connection - importing Hardware::UPS::Perl connection
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::Driver     - importing Hardware::UPS::Perl driver
#
#==============================================================================

use POSIX qw(
    :signal_h sigprocmask
);

use Hardware::UPS::Perl::Connection;
use Hardware::UPS::Perl::Constants qw(
    UPSEXECUTABLE
    UPSSCRIPT
);
use Hardware::UPS::Perl::Driver;

#==============================================================================
# defining exported variables:
#==============================================================================

$UPSERROR  = q{};

#==============================================================================
# defining user invisible package variables:
#------------------------------------------------------------------------------
#
#   @SCRIPTARGUMENTS                - list of arguments
#   $LOGGER                         - the logger object used
#   $PID                            - the PID object used
#
#==============================================================================

my @SCRIPTARGUMENTS = (
);

my $LOGGER          = undef;
my $PID             = undef;

#==============================================================================
# defining exported subroutines:
#==============================================================================

sub InitWE {

    # subroutine for initializing working environment for Perl scripts
    # dealing with an UPS

    # the argument list
    @SCRIPTARGUMENTS = @ARGV;

    # special signal case: hangup detected (restart) 
    #
    # POSIX unmasks the sigprocmask properly
    my $sigset = POSIX::SigSet->new();
    my $action = POSIX::SigAction->new(\&Catch, $sigset, &POSIX::SA_NODEFER);

    POSIX::sigaction(&POSIX::SIGHUP, $action);

    # catching all other signals
    $SIG{ INT  } = \&Catch;     # Interrupt from keyboard
    $SIG{ QUIT } = \&Catch;     # Quit from keyboard
    $SIG{ PIPE } = \&Catch;     # Broken pipe: write to pipe with no readers
    $SIG{ TERM } = \&Catch;     # Termination signal

} # end of subroutine "InitWE"
 
sub Catch {
    
    # subroutine for catching signals and performing actions
    #
    # parameter: $signal (input) - signal to be caught
    
    # input as hidden local variable
    my $signal = shift;
    
    # hidden local variables
    my %signalHandler;      # the signal handler

    # setting up the signal handler
    %signalHandler = (
        HUP     =>  sub {   # restarting

                        # deactivate signals
                        DEACTIVATE:
                        for my $sig (qw(HUP INT QUIT PIPE TERM)) {
                            $SIG{$sig} = sub {};
                        }

                        # restoring signals
                        my $s = POSIX::SigSet->new();
                        my $t = POSIX::SigSet->new();
                        sigprocmask(SIG_BLOCK, $s, $t);

                        # deleting PID file
                        if (defined $PID) {
                            $PID->delete();
                        }

                        # restart
                        if (defined $LOGGER) {
                            $LOGGER->info("restarting ...")
                        }

                        exec ${\(UPSEXECUTABLE)} => @SCRIPTARGUMENTS
                            or Error("restart failed -- $!");

                    },
        TERM    =>  sub {   # normal exit
                        exit 0;
                    },
    );

    # signal handling
    if (exists $signalHandler{$signal}) {
        $signalHandler{$signal}->();
    }
    else {
        Error("caught a SIG$signal -- stopping execution");
    }

} # end of subroutine "Catch"

sub Error {

    # subroutine for displaying any error message, cleaning up and exit
    #
    # parameter: $errorMessage (input) - error message to be displayed

    # input as hidden local variable
    my $errorMessage = shift;

    # displaying error message
    print STDERR "${\(UPSSCRIPT)}: $errorMessage\n";

    # exiting with error
    exit 1;
    
} # end of subroutine "Error"

sub Warning {

    # subroutine for displaying a warning message to STDERR without exiting
    # the program
    #
    # parameter: $warningMessage (input) - warning message to be displayed

    # input as hidden local variable
    my $warningMessage = shift;

    # displaying warning message
    print STDERR "${\(UPSSCRIPT)}: $warningMessage\n";

} # end of subroutine "Warning"

sub ManPage {

    # subroutine for displaying the man page of the calling main program
    # and exiting without error

    # displaying man page
    CORE::system("pod2man $0 | groff -man -Tlatin1 | less");

    # exiting without error
    exit 0;

} # end of subroutine "ManPage"

sub Version {

    # subroutine for displaying the version information on the calling Perl
    # script and exiting without error
    #
    # parameter: $version     (input) - revision number
    #            $date        (input) - revison date
    #            $description (input) - short description of calling script
    
    # input as hidden local variables
    my $version     = shift;
    my $date        = shift;
    my $description = shift;

    # displaying version information
    print <<EOF;
${\(UPSSCRIPT)}, $description

    Version $version, $date

    Copyright (c) 2007 by Christian Reile

    This is free software; you can redistribute it and/or modify it under the
    terms of the GNU General Public License as published by the Free Software
    Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
    for more details.

${\(UPSSCRIPT)}: For help, type `${\(UPSSCRIPT)} -h' or `${\(UPSSCRIPT)} --help'.

EOF

    # exiting without error
    exit 0;

} # end of subroutine "Version"

sub SetLogger {

    # subroutine to set the logging object
    #
    # parameters: $logger (input) - the logger

    # input as hidden variable
    my $logger = shift;

    # hidden local variables
    my $refType;            # a reference type

    # checking logger
    if (defined $logger) {
        $refType = ref($logger);
        if ($refType ne "Hardware::UPS::Perl::Logging") {
            Error("no logger -- <$refType>");
        }
    }
    else {
        Error("no logger defined");
    }

    # setting logger
    $LOGGER = $logger;

} # end of subroutine "SetLogger"

sub SetPID {

    # subroutine to set the PID object
    #
    # parameters: $pidObject (input) - the PID object

    # input as hidden variable
    my $pidObject = shift;

    # hidden local variables
    my $refType;            # a reference type

    # checking logger
    if (defined $pidObject) {
        $refType = ref($pidObject);
        if ($refType ne "Hardware::UPS::Perl::PID") {
            Error("no PID object -- <$refType>");
        }
    }
    else {
        Error("no PID object defined");
    }

    # setting PID object
    $PID = $pidObject;

} # end of subroutine "SetPID"

sub ConnectUPS {

    # subroutine to connect to the UPS
    #
    # parameters: $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Host        ($) - the remote host; string; optional
    #   TCPPort     ($) - the TCP port to use; required, if host is specified
    #   SerialPort  ($) - the serial port to use; required, if host is not
    #                     specified
    #   DebugLevel  ($) - the debug level; natural number; optional
    #   Driver      ($) - the driver; string; required
    #   Logger      ($) - Hardware::UPS::Perl::Logging object; the logger to
    #                     use; required

    # input as hidden local variable
    my $options = shift;

    # hidden local variables
    my $refType;            # a reference type
    my $host;               # the remote host
    my $port;               # the TCP or serial port
    my $debugLevel;         # the debug level
    my $driverName;         # the name of the driver to use
    my $logger;             # the logger to use
    my $connectionType;     # the connection type
    my $connectionOptions;  # the connection options
    my $connection;         # the connection object
    my $driver;             # the driver object
    my $ups;                # the UPS object

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        Error("not a hash reference -- <$refType>");
    }

    # processing options
    #
    # the host
    $host = delete $options->{Host};

    # the driver
    $driverName = delete $options->{Driver};
    if (!defined $driverName) {
        Error("driver missing");
    }

    # the debug level
    $debugLevel = delete $options->{DebugLevel};
    if (!defined $debugLevel) {
        $debugLevel = 0;
    }

    # the logger
    $logger = delete $options->{Logger};
    if (!defined $logger) {
        Error("logger missing");
    }

    # getting connection
    if (defined $host) {

        # remotely via TCP
        $connectionType    = "net"; 

        $port = delete $options->{TCPPort};
        if (!defined $port) {
            Error("TCP port missing");
        }

        $connectionOptions = {
            Host        => $host  ,
            TCPPort     => $port  ,
            Logger      => $logger,
        };

    }
    else {

        # locally via a serial port
        $connectionType    = "serial"; 

        $port = delete $options->{SerialPort};
        if (!defined $port) {
            Error("serial port missing");
        }

        $connectionOptions = {
            SerialPort  => $port  ,
            Logger      => $logger,
        };

    }

    # getting connection
    $connection = Hardware::UPS::Perl::Connection->new({
        Type    =>  $connectionType   ,
        Options =>  $connectionOptions,
        Logger  =>  $logger           ,
    });
    if (!defined $connection) {
        Error("creating connection failed -- $UPSERROR");
    }

    # getting driver
    $driver = Hardware::UPS::Perl::Driver->new({
        Driver      =>  $driverName,
        Options     =>  {
                            Connection  => $connection,
                            Logger      => $logger,
                        },
        Logger      =>  $logger,
    });
    if (!defined $driver) {
        Error("creating driver failed -- $UPSERROR");
    }

    # connecting to UPS
    $ups = $driver->getDriverHandle();
    if (!defined $ups) {
        Error("creating UPS object failed -- ".$driver->getErrorMessage());
    }

    # setting debug level
    $ups->setDebugLevel($debugLevel);

    # flushing UPS buffer
    $ups->flush();

    # returning UPS object
    return $ups;

} # end of subroutine "ConnectUPS"

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

Hardware::UPS::Perl::General - general functions for Hardware::UPS::Perl
scripts

=head1 SYNOPSIS

    use Hardware::UPS::Perl::General;

    &InitWE()

    &Error("this is an error message");
    &Warning("this is an warning message");

    &ManPage();

    &Version("1.1", "01-02-2007", "this is the description");

=head1 DESCRIPTION

B<Hardware::UPS::Perl::General> provides general functions for Perl scripts
dealing with an UPS.

=head1 VARIABLES

=head2 @EXPORT

=over 4

=item B<$UPSERROR>

The global error text.

=back

=head1 FUNCTIONS

=head2 InitWE

=over 4

=item B<Name:> 

InitWE - main initializing function

=item B<Synopsis:>

    &InitWE();

=item B<Description:>

B<InitWE> sets up the signals to be catched so far only. This might change in
a future release.

=item B<See Also:>

L<"Catch">

=back

=head2 Catch

=over 4

=item B<Name:> 

Catch - signal catcher

=item B<Synopsis:>

    &Catch($signal);

=item B<Description:>

B<Catch> catches the signal C<$signal>. In case of signal 'TERM' the script
will be terminated regulary (status F<0>), while for signal 'HUP' the script
will be restarted. In all other cases, the script will be terminated with
status F<1> by calling the function L<"Error">.

=item B<Arguments:>

=over 4

=item C<< $signal >>

string; the signal to be caught.

=back

=item B<See Also:>

L<"Error">

=back

=head2 Error

=over 4

=item B<Name:> 

Error - displays errors

=item B<Synopsis:>

    &Error($errorMessage);

=item B<Description:>

B<Error> writes the error message C<$errorMessage>, a text string, to
F<STDERR> and exits with status F<1>. The error message is prepended by the
basename of the calling script.

=item B<Arguments:>

=over 4

=item C<< $errorMessage >>

string; the error message.

=back

=item B<See Also:>

L<"Catch">,
L<"Warning">

=back

=head2 Warning

=over 4

=item B<Name:> 

Warning - displays warning messages

=item B<Synopsis:>

    &Warning($warningMessage);

=item B<Description:>

B<Warning> writes the warning message C<$warningMessage>, a text string, to
F<STDERR>. The warning message is prepended by the basename of the calling
script. 

=item B<Arguments:>

=over 4

=item C<< $warningMessage >>

string; the warning message.

=back

=item B<See Also:>

L<"Error">

=back

=head2 ManPage

=over 4

=item B<Name:> 

ManPage - displays embedded pod documentation

=item B<Synopsis:>

    &ManPage();

=item B<Description:>

B<ManPage> displays the embedded pod documentation of the calling script and
exits without errors. It uses B<pod2man>, B<groff> and B<less> as pager.

=item B<See Also:>

groff(1),
less(1),
pod2man(1)

=back

=head2 Version

=over 4

=item B<Name:> 

Version - displaying version information

=item B<Synopsis:>

    &Version($revisionVersion, $revisionDate, $description);

=item B<Description:>

B<Version> displays the version information consisting of the revision version
C<$revisionVersion>, revision date C<$revisionDate> and the program
description C<$description> together with a copyright statement of the
calling script and exits without errors.

=item B<Arguments:>

=over 4

=item C<< $revisionVersion >>

string; the revision version.

=item C<< $revisionDate >>

string; the revision date.

=item C<< $description >>

string; the description text.

=back

=item B<See Also:>

=back

=head2 SetLogger

=over 4

=item B<Name:> 

SetLogger - sets the logger

=item B<Synopsis:>

    &SetLogger($logger);

=item B<Description:>

B<SetLogger> sets the logger to be used in the generalized signal handler
B<Catch>.

=item B<Arguments:>

=over 4

=item C<< $logger >>

a Hardware::UPS::Perl::Logging object; the logger.

=back

=item B<See Also:>

L<"Catch">
L<"SetPID">

=back

=head2 SetPID

=over 4

=item B<Name:> 

SetPID - sets the PID object

=item B<Synopsis:>

    &SetPID($pid);

=item B<Description:>

B<SetPID> sets the PID object to be used in the generalized signal handler
B<Catch>.

=item B<Arguments:>

=over 4

=item C<< $pid >>

a Hardware::UPS::Perl::PID object; the PID object.

=back

=item B<See Also:>

L<"Catch">
L<"SetLogger">

=back

=head2 ConnectUPS

=over 4

=item B<Name:> 

ConnectUPS - connects to a UPS

=item B<Synopsis:>

    my $ups = &ConnectUPS({
        Host        => $host,
        TCPPort     => $Port
        DebugLevel  => $DebugLevel,
        Driver      => $Driver,
        Logger      => $Logger,
    });

    my $ups = &ConnectUPS({
        SerialPort  => $Port
        DebugLevel  => $DebugLevel,
        Driver      => $Driver,
        Logger      => $Logger,
    });

=item B<Description:>

B<ConnectUPS> returns an UPS object connected to a UPS.

B<ConnectUPS> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< Host          => $host >>

optional; string; defines the remote host to connect to.

=item C<< TCPPort       => $tcpPort >>

required, if host is specified; natural number; defines the TCP port at the
remote host to connect to.

=item C<< SerialPort    => $serialPort >>

required, if host is not specified; string; defines the serial port the UPS
resides at.

=item C<< DebugLevel    => $debugLevel >>

optional; natural number; defines the debug level.

=item C<< Driver        => $driver >>

required; string; defines the UPS driver to use.

=item C<< Logger        => $logger >>

required; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to STDERR is created.

=back

=item B<See Also:>

L<"SetLogger">

=back

=head1 SEE ALSO

Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm)

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::General> are welcome, though due
to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
