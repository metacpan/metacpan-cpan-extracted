#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Smtp.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to monitor SMTP servers.
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://www.gnu.org/copyleft/gpl.html
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#############################################################################
#
#
#       REVISION HISTORY:
#
#       $Log: Smtp.pm,v $
#       Revision 1.8  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/13 07:38:51  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/28 19:35:14  bhenry
#       Bug Fixes
#
#       Revision 1.3  2002/01/25 07:15:11  bhenry
#       Changed to inherit from Parser
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Smtp;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use Mail::Sendmail;

# Inherit methods from Parser class
our @ISA = qw(VBTK::Parser);

our $VERBOSE = $ENV{VERBOSE};
our $DEFAULT_TIMEOUT=10;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members,
#               create an Snmp session, check passed Snmp labels.
#
# Input Parms:  
# Output Parms: Pointer to self
#-------------------------------------------------------------------------------
sub new
{
    my ($type,$self);
    
    # If we're passed a hash as the first element, then it's probably from an
    # inheriting class
    if((defined $_[0])&&(UNIVERSAL::isa($_[0], 'HASH')))
    {
        $self = shift;
    }
    # Otherwise, allocate a new hash, bless it and handle any passed parms
    else
    {
        $type = shift;
        $self = {};
        bless $self, $type;

        # Store all passed input name pairs in the object
        $self->set(@_);
    }

    # Setup the header and detail formats for the pmobjects and log
    my $stdHeader   = [ 'Time              Resp Time (sec) Error',
                        '----------------- --------------- -----' ];
    my $stdDetail   = [ '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>> @>>>>',
                        '$time,            $data[0],       $data[1]' ];

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 300,
        Host              => $::REQUIRED,
        Port              => 25,
        To                => $::REQUIRED,
        From              => $self->{To},
        Subject           => "VBTK Test from $::HOST",
        Message           => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => '12:00am',
        Timeout           => $DEFAULT_TIMEOUT,
        ErrorStatus       => 'Warning'
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms);

    # Create a parser object to handle the response times.
    $self->SUPER::new();
    
    # Setup the mail hash
    $self->{mailHash} = { 
        To      => $self->{To},
        From    => $self->{From},
        Subject => $self->{Subject},
        Message => $self->{Message},
        Smtp    => $self->{Host} . ":" . $self->{Port},
    };

    # Add self to the list of all defined VBTK objects
    &VBTK::register($self);
    return $self;
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Pass the specified Rules name/value pairs to the Parser object
# Input Parms:  VBTK::Parser name/value pairs hash
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $Interval       = $self->{Interval};
    my $Host           = $self->{Host};
    my $Port           = $self->{Port};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 4);
    my $description = qq( 
        This object monitors the SMTP server '$Host:$Port'.  If will set the status
        to warning if it is unable to send an email or if response times become 
        unacceptable.
    );

    # Setup default parms
    my $defaultRules = {
        VBObjName            => ".$Host.smtp",
        TextHistoryLimit     => 30,
        ReverseText          => 1,
        Rules                => undef,
        Requirements         => undef,
        StatusHistoryLimit   => 30,
        StatusChangeActions  => undef, 
        StatusUpgradeRules   => [ 
            "Upgrade to Failed if Warning occurs 3 times in $expireAfterSec sec" ],
        ExpireAfter          => "$expireAfterSec seconds",
        Description          => $description,
        RrdTimeCol           => undef,
        RrdColumns           => [ '$data[0]', '$data[1]' ],
        RrdFilter            => undef,
        RrdMin               => 0,
        RrdMax               => undef,
        RrdXFF               => undef,
        RrdCF                => undef,
        RrdDST               => undef,
    };

    # Run the validation    
    &validateParms(\%args,$defaultRules) || &fatal("Exiting");

    # Setup the VB object for response time parser.
    my $vbObj = $self->SUPER::addVBObj(%args);
    return undef unless ($vbObj);

    # Now define what graphs to show on this object's page, but only if 
    # a value was specified for 'RrdColumns'
    if(($args{RrdColumns})&&(@{$args{RrdColumns}} > 0))
    {
        $vbObj->addGraphGroup (
            GroupNumber    => 1,
            DataSourceList => ':0',
            Labels         => 'resp time (sec)',
            Title          => "SMTP Svr $Host:$Port",
        );

        $vbObj->addGraphGroup (
            GroupNumber    => 2,
            DataSourceList => ':1',
            Labels         => 'errors',
            Title          => "SMTP Svr $Host:$Port",
        );
    }

    ($vbObj);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Retrieve and process the specified Snmp values
# Input Parms:  None
# Output Parms: Time till next retrieval
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $Interval       = $self->{Interval};
    my $Host           = $self->{Host};
    my $Port           = $self->{Port};
    my $Timeout        = $self->{Timeout};
    my $ErrorStatus    = $self->{ErrorStatus};
    my $lastTime       = $self->{lastTime};
    my $mailHash       = $self->{mailHash};
    my $To             = $self->{To};

    my ($sock,$elapsedTime,$sleepTime);

    # If it's not time to run yet, then return
    if(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to check $Host:$Port, wait $sleepTime seconds")
            if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }

    my $now = time;

    # Run all network operations within an alarmed eval, so that nomatter
    # where it hangs, if it doesn't finish in $timeout seconds, then it will
    # just fail gracefully.
    eval {
        local $SIG{ALRM} = sub { die "Timed out while connecting\n"; };
        alarm $Timeout;

        &log("Sending email for '$To' to $Host:$Port") if ($VERBOSE > 1);

        &sendmail(%{$mailHash}) || die "$Mail::Sendmail::error\n";

        alarm 0;
    };

    alarm 0;

    $elapsedTime = time - $now;

    # Check for errors
    if($@ ne '')
    {
        my $msg = "Error sending mail to '$Host:$Port' - $@";
        &error($msg);
        $self->parseData([[$elapsedTime,1]],$ErrorStatus,$msg);
    }
    else
    {
        # Call the response time parser, with the elapsed time
        $self->parseData([[$elapsedTime,0]],$::SUCCESS);
    }
    
    $sleepTime = $self->calcSleepTime(1);

    ($sleepTime,$::NOT_FINISHED);
}

1;
__END__

=head1 NAME

VBTK::Tcp - Tcp Listener Monitoring

=head1 SYNOPSIS

  $d = new VBTK::Tcp (
    Interval       => 60,
    Host           => 'myoracle',
    Port           => 1521,
    VBServerURI    => 'http://myvbserver:4712',
    VBHeader       => [ 
       'Time              Response Time (sec)',
       '----------------- -------------------' ],
    VBDetail       => [ 
       '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>>>>',
       '$time             $data[0]' ],
  );

  $d->addVBObj (
    VBObjName         => '.oracle.db.logincount',
    Rules             => [
      '$data[0] > 20' => 'Warning',
      '$data[0] > 40' => 'Failed' ],
    ExpireAfter       => '3 min',
    Description       => qq(
      This object monitors the number of users logged into the database),
  );

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library provides the ability to do simple monitoring of any TCP
listener.  It simply connects to the specified host and port and measures
the elapsed time it takes to make the connection.  If the connection attempt
fails or takes longer than 'Timeout' seconds, then the status of the 
corresponding VBObjects will be set to the 'ErrorStatus' value.

Note that the 'new VBTK::Tcp' and '$d->addVBObj' lines just initialize and 
register the objects.  It's the &VBTK::runAll which starts the monitoring.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $s = new VBTK::Tcp (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are as follows.

=over 4

=item Interval

The interval (in seconds) on which the SMTP send should be attempted.  
(Defaults to 300)

    Interval => 300,

=item Host

A string containing the host to connect to.  (Required)

    Host => 'myhost',

=item Port

A number indicating the TCP port to connect to.  (Required)

    Port => 1521,

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.  (Defaults to the following)

     VBHeader => [ 
        'Time              Resp Time (sec)',
        '----------------- ---------------' ];

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.  Be sure to either use single-quotes or escape out the '$' vars
so that they don't get evaluated until later.  (Defaults to the following)

    VBDetail => [
        '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>',
        '$time             $data[0]' ],

The following variables will be set just before these detail lines are evaluated:

=over 4

=item $time

A datestamp of the form YYYYMMDD-HH:MM:SS

=item @data

An array, the first element of which contains the elapsed time in seconds of 
the connection attempt.  

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.  

=back

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item LogFile

A string containing the path to a file where a log file should be written.  
Leave blank if no log file is desired.  (Defaults to undef).

    LogFile => '/var/log/tcp.1521.log',

=item LogHeader

Same as VBHeader, but to be used in formatting the log file.

=item LogDetail

Same as VBDetail, but to be used in formatting the log file.

=item RotateLogAt

A string containing a date/time expression indicating when the log file should
be rotated.  When the log is rotated, the current log will have a timestamp
appended to the end of it after which logging will continue to a new file with
the original name.  The expression will be passed to L<Date::Manip|Date::Manip>
so it can be just about any recognizable date/time expression.
(Defaults to 12:00am)

    RotateLogAt => '12:00am',

=item ErrorStatus

A string containing a status to which any VBObjects should be set if there
is an error while attempting to connect to the TCP listener.
(Defaults to Warning).

    ErrorStatus => 'Warning',

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  See L<VBTK::Parser> for a detailed
description of the main parameters.

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

VBTK::Server
VBTK::Wrapper

=head1 AUTHOR

Brent Henry, vbtoolkit@yahoo.com

=head1 COPYRIGHT

Copyright (C) 1996-2002 Brent Henry

This program is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public
License as published by the Free Software Foundation available at:
http://www.gnu.org/copyleft/gpl.html

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
