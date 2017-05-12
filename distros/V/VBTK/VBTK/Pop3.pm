#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Pop3.pm,v $
#            $Revision: 1.10 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to monitor POP3 servers.
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
#       $Log: Pop3.pm,v $
#       Revision 1.10  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.9  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.8  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.7  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/02/19 19:08:38  bhenry
#       Added 'total mailbox count' to data gathered
#
#       Revision 1.5  2002/02/13 07:38:51  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/28 19:35:14  bhenry
#       Bug Fixes
#
#       Revision 1.3  2002/01/25 07:15:25  bhenry
#       Changed to inherit from Parser
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Pop3;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use Mail::POP3Client;
use Date::Manip;

# Inherit methods from Parser class
our @ISA = qw(VBTK::Parser);

our $VERBOSE = $ENV{VERBOSE};
our $DEFAULT_TIMEOUT=30;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members,
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
    my $stdHeader   = [ '                  Retrieval Round-trip Retrieved MailBox',
                        'Time              (sec)     (sec)      Count     Count   Error',
                        '----------------- --------- ---------- --------- ------- -----' ];
    my $stdDetail   = [ '@<<<<<<<<<<<<<<<< @>>>>>>>> @>>>>>>>>> @>>>>>>>> @>>>>>> @>>>>',
                        '$time,@data[0..4]' ];

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 300,
        Host              => $::REQUIRED,
        Port              => 110,
        User              => $::REQUIRED,
        Password          => $::REQUIRED,
        RetrieveFilter    => undef,
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
    $self->SUPER::new() || return undef;

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
        to warning if it is unable to connect to the POP3 server or if response
        times become unacceptable.
    );

    # Setup default parms
    my $defaultRules = {
        VBObjName            => $::REQUIRED,
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
        RrdColumns           => [ '$data[0]', '$data[1]', '$data[4]' ],
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
    return undef if (! defined $vbObj);

    # Now define what graphs to show on this object's page, but only if 
    # a value was specified for 'RrdColumns'
    if(($args{RrdColumns})&&(@{$args{RrdColumns}} > 0))
    {
        $vbObj->addGraphGroup (
            GroupNumber    => 1,
            DataSourceList => ':0,:1',
            Labels         => 'retrieval time (sec),round-trip time (sec)',
            Title          => "POP3 Svr $Host:$Port",
        );

        $vbObj->addGraphGroup (
            GroupNumber    => 2,
            DataSourceList => ':2',
            Labels         => 'errors',
            Title          => "POP3 Svr $Host:$Port",
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
    my $User           = $self->{User};
    my $Password       = $self->{Password};
    my $Timeout        = $self->{Timeout};
    my $ErrorStatus    = $self->{ErrorStatus};
    my $RetrieveFilter = $self->{RetrieveFilter};
    my $lastTime       = $self->{lastTime};

    my $now = time;
    my ($sock,$elapsedTime,$pop,$roundTrip,$count,$sleepTime,$totMessages);

    # If it's not time to run yet, then return
    if(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to check $Host:$Port, wait $sleepTime seconds")
            if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }

    # Run all network operations within an alarmed eval, so that nomatter
    # where it hangs, if it doesn't finish in $timeout seconds, then it will
    # just fail gracefully.
    eval {
        local $SIG{ALRM} = sub { die "Timed out connecting to $Host:$Port\n"; };
        alarm $Timeout;

        &log("Connecting to $Host:$Port") if ($VERBOSE > 1);

        $pop = new Mail::POP3Client(
            USER       => $User,
            PASSWORD   => $Password,
            HOST       => $Host,
            PORT       => $Port,
            TIMEOUT    => $Timeout
        );

        $pop->Alive() || die "Can't connect\n";

        # If a processFilter was specified, then look for email which
        # have a subject matching the filter, and process them.
        ($roundTrip,$count,$totMessages) = $self->processEmail($pop) 
            if (defined $RetrieveFilter);

        $pop->Close();

        alarm 0;
    };

    alarm 0;

    $elapsedTime = time - $now;

    # Check for errors
    if($@ ne '')
    {
        my $msg = "Error retrieving mail from '$Host:$Port' - $@";
        &error($msg);
        $self->parseData([[$elapsedTime,0,0,0,1]],$ErrorStatus,$msg);
    }
    # If the RetrieveFilter is specified, then only report a status if the
    # count is > 0.  If the RetrieveFilter is not specified, then always report it.
    elsif(($count > 0)||(! defined $RetrieveFilter))
    {
        # Call the response time parser, with the elapsed time
        $self->parseData([[$elapsedTime,$roundTrip,$count,$totMessages,0]],$::SUCCESS);
    }

    $sleepTime = $self->calcSleepTime(1);

    ($sleepTime,$::NOT_FINISHED);
}

#-------------------------------------------------------------------------------
# Function:     processEmail
# Description:  Look through the email in the passed pop account and find any which
#               have a subject matching the specified RetrieveFilter.  If they match,
#               then get their headers and calculate the round-trip time.
# Input Parms:  None
# Output Parms: Email average round-trip time
#-------------------------------------------------------------------------------
sub processEmail
{
    my $self = shift;
    my $pop = shift;
    my $RetrieveFilter = $self->{RetrieveFilter};

    my ($roundTrip,$count,$i,@headers,@subject,@startDateLine,@endDateLine);
    my ($startTime,$endTime,$roundTripTotal);

    my $totMessages = $pop->Count();
    for($i = 1; $i <= $totMessages; $i++)
    {
        @headers = $pop->Head($i);
        @subject = grep(/^Subject:\s+/i,@headers);

        next unless(grep(/$RetrieveFilter/,@subject));

        $pop->Delete($i);

        @startDateLine = grep(/^Date:\s+/,@headers);
        @endDateLine = grep(/^Received:\s+/,@headers);

        # Convert the 'Date' entry to unix time.  Skip this email if the
        # conversion fails.
#        unless(($startDateLine[0] =~ /^Date:\s*(.+)\s*$/)&&
#           (($startTime = &Date::Manip::UnixDate($1, "%s")) > 0))
#        {
#            &error("Can't determine unix time from '$startDateLine[0]'");
#            next;
#        }

        # Convert the most recent 'Retrieved' entry to unix time.  Skip this
        # email if the conversion fails.
#        unless(($endDateLine[0] =~ /^Received:.*(\d{1,2}\s+\w{3,3}\s+\d{4,4}\s+.+)\s*$/)&&
#           (($endTime = &Date::Manip::UnixDate($1, "%s")) > 0))
#        {
#            &error("Can't determine unix time from '$endDateLine[0]'");
#            next;
#        }

        $count++;
        $roundTripTotal += $endTime - $startTime;
    }

    # Calculate the average round-trip time.
    $roundTrip = ($count > 0) ? $roundTripTotal/$count : 0;

    ($roundTrip,$count,$totMessages);
}

# Put in a stub for handleSignal
sub handleSignal  { (0); }


1;
__END__

=head1 NAME

VBTK::Tcp - Tcp Listener Monitoring

=head1 SYNOPSIS

  $o = new VBTK::Pop3 (
    Host           => 'pop3.nowhere.com',
    User           => 'myuser',
    Password       => 'mypass' );

  $o->addVBObj (
    VBObjName      => '.external.pop3.nowhere',
  );

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library provides the ability to do simple monitoring of a POP3
server.  It uses the Mail::POP3Client library (available from CPAN) to connect
to a POP server, check the connection status, and disconnect.  It measures
the elapsed time for this and stores it.  It can also retrieve messages from
the mailbox and determine the latency of the message delivery from the 
message headers.  If the connection attempt fails of takes longer than 
'Timeout' seconds, then the status of the corresponding VBObjects will be
set to the 'ErrorStatus' value.

Note that the 'new VBTK::Pop3' and '$o->addVBObj' lines just initialize and 
register the objects.  It's the &VBTK::runAll which starts the monitoring.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $s = new VBTK::Pop3 (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are as follows.

=over 4

=item Interval

The interval (in seconds) on which the POP3 retrieval should be attempted.  
(Defaults to 300)

    Interval => 300,

=item Host

A string containing the pop3 host to connect to.  (Required)

    Host => 'myhost',

=item Port

A number indicating the port to connect to.  (Defaults to 110)

    Port => 110,

=item User

A string containing the username to use when connecting.  (Required)

    User => 'me',

=item Password

A string containing the password to use when connecting.  (Required)

    Password => 'mypass',

=item RetrieveFilter

A string containing a perl pattern-matching expression.  If this is set, the
library will retrieve and delete messages in the pop3 account which have a
subject line matching this expression.  It will also attempt to calculate
the delivery latency of the retrieved messages.  

Note that if this string is specified, the monitoring process will not send
a status to the VB Server until a message matching the filter arrives.  It will
continue to connect to the POP3 server on the specified interval, but will
not transmit a status until a message arrives.  So if the process which is 
sending the messages dies, or some other problem prevents mail from being
delivered, then the VB Object for this process will probably expire.  This is
a good thing, if what you're trying to monitor is the full cycle of sending
an email, having it be delivered, and then retrieving it from the POP3 account.

This library is commonly used along with a L<VBTK::Smtp|VBTK::Smtp> process.
The VBTK::Smtp process sends mail every $Interval seconds, and the VBTK::Pop3
process gathers it every $Interval seconds.  If anything breaks in between
then the VBObject associated with this VBTK::Pop3 process will either get set
to 'Failed' or 'Expired', and either way you can be notified.

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.  (Defaults to the following)

     VBHeader => [ 
         'Time              Retrieval (sec) Round-trip (sec) Error',
         '----------------- --------------- ---------------- -----' ]

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.  Be sure to either use single-quotes or escape out the '$' vars
so that they don't get evaluated until later.  (Defaults to the following)

    VBDetail => [
        '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>> @>>>>>>>>>>>>>>> @>>>>',
        '$time,            $data[0],       $data[1],        $data[2]' ];

The following variables will be set just before these detail lines are evaluated:

=over 4

=item $time

A datestamp of the form YYYYMMDD-HH:MM:SS

=item @data

An array, which contains the retrieval time in seconds, the round-trip time in 
seconds, and an error count.  The round-trip time will always be 0 unless the 
'RetrieveFilter' parm is set.  

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.  

=back

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://vbserver:4712',

=item LogFile

A string containing the path to a file where a log file should be written.  
Leave blank if no log file is desired.  (Defaults to undef).

    LogFile => '/var/log/pop3.nowhere.log',

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
is an error while attempting to connect to the POP3 server.
(Defaults to Warning).

    ErrorStatus => 'Warning',

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  This method calls
VBTK::Parser::addVBObj after defaulting unspecified parameters to best
support monitoring a POP3 server.  For a detailed description
of the addVBObj parameters, see L<VBTK::Parser>.  The defaults are as follows.
If you like all the defaults then you don't have to pass in any parms,
except for the 'VBObjName' parm which is required.

=over 4

=item VBObjName

This is a required parm.

    VBObjName => ".myhost.pop3",

=item TextHistoryLimit

    TextHistoryLimit => 30,

=item ReverseText

Reverse the text, so that we see the most recently reported lines first.

    ReverseText => 1,

=item StatusHistoryLimit

Limit to storing the last 30 status changes

    StatusHistoryLimit => 30,

=item StatusUpgradeRules

    StatusUpgradeRules =>
        'Upgrade to Failed if Warning occurs 3 times in <Interval * 4> seconds',

=item ExpireAfter

    ExpireAfter => (<Interval> * 4) seconds

=item Description

    Description = qq(
        This object monitors the SMTP server <Host:Port>.  If will set the status
        to warning if it is unable to connect to the POP3 server or if response
        times become unacceptable. );

=item RrdColumns

Save the response time, round-trip time, and error count into the Rrd
database so that we can graph them.

    RrdColumns => [ '$data[0]', '$data[1]', '$data[3]' ],

=back

In addition to passing these defaults on in a call to VBTK::Parser::addVBObj,
this method captures the resulting VBTK::ClientObject pointer ($vbObj) and 
makes the following calls to '$vbObj->addGraphGroup':

  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    DataSourceList => ':0,:1',
    Labels         => 'retrieval time (sec),round-trip time (sec)',
    Title          => 'POP3 Svr <Host:Port>',
  );

  $vbObj->addGraphGroup (
    GroupNumber    => 2,
    DataSourceList => ':2',
    Labels         => 'errors',
    Title          => 'POP3 Svr <Host:Port>',
  );

This defines two graphGroups for the VBObject.  See L<VBTK::ClientObject> for
details on the 'addGraphGroup' method.

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

=over 4

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

=item Mail::POP3Client

=back

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

