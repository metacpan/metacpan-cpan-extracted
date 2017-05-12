#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Http.pm,v $
#            $Revision: 1.7 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library to test web URL's
#
#          Description: This perl library provides the ability to monitor a
#                       series of URL's for content.
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
#       $Log: Http.pm,v $
#       Revision 1.7  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.5  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.4  2002/02/13 07:38:52  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.3  2002/01/25 07:15:11  bhenry
#       Changed to inherit from Parser
#
#

package VBTK::Http;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use LWP::UserAgent;
use HTTP::Cookies;

# Inherit methods from Parser class
our @ISA = qw(VBTK::Parser);

# Setup global package variables.
our $VERBOSE=$ENV{VERBOSE};
our $DEFAULT_TIMEOUT = 15;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
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
    my $stdHeader   = [ 'Time              Resp Time (sec) Errors',
                        '----------------- --------------- ------' ];
    my $stdDetail   = [ '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>> @>>>>>',
                        '$time,            $data[0],       $data[1]' ];

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => 60,
        URL               => $::REQUIRED,
        CheckImages       => undef,
        VBServerURI       => $::VBURI,
        VBHeader          => $stdHeader,
        VBDetail          => $stdDetail,
        LogFile           => undef,
        LogHeader         => $stdHeader,
        LogDetail         => $stdDetail,
        RotateLogAt       => '12:00am',
        PreProcessor      => undef,
        Split             => undef,
        Filter            => undef,
        Ignore            => undef,
        Timeout           => $DEFAULT_TIMEOUT,
        ErrorStatus       => $::WARNING,
        DebugHeader       => 'URL $self->{URL}',
        AllowCookies      => 1,
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Create a parser object to handle the response times.
    $self->{Parser} = new VBTK::Parser(
        Interval          => $self->{Interval},
        VBServerURI       => $self->{VBServerURI},
        VBHeader          => $self->{VBHeader},
        VBDetail          => $self->{VBDetail},
        LogFile           => $self->{LogFile},
        LogHeader         => $self->{LogHeader},
        LogDetail         => $self->{LogDetail},
        RotateLogAt       => $self->{RotateLogAt},
        RotateLogOnEOF    => $self->{RotateLogOnEOF},
        Split             => undef,
        Filter            => undef,
        Ignore            => undef,
    );

    # Create a second parser object to handle the comparison to a baseline.
    # This one will not get all the parms passed in.
    $self->{BaselineParser} = new VBTK::Parser(
        Interval          => $self->{Interval},
        VBServerURI       => $self->{VBServerURI},
        VBHeader          => undef,
        VBDetail          => [ '$data' ],
        LogFile           => undef,
        LogHeader         => undef,
        LogDetail         => undef,
        RotateLogAt       => undef,
        RotateLogOnEOF    => undef,
        PreProcessor      => $self->{PreProcessor},
        Split             => $self->{Split},
        Filter            => $self->{Filter},
        Ignore            => $self->{Ignore}
    );

    # Setup a useragent object
    my $ua = new LWP::UserAgent;
    $ua->agent("VBTK::Http" . $ua->agent);
    $ua->timeout($self->{Timeout});
    $self->{ua} = $ua;

    # Setup a request object, but don't submit it yet
    my $req = new HTTP::Request GET => "$self->{URL}";
    $self->{req} = $req; 

    $self->{ErrorStatus} = map_status($self->{ErrorStatus});
    &fatal("Invalid Error Status specified") if ($self->{ErrorStatus} eq '');

    # Setup a cookie jar
    $self->{cookieJar} = HTTP::Cookies->new();

    &VBTK::register($self);
    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Calls the VBTK::Parser add_rules method for the current object.
# Input Parms:  Parser Name Pairs Hash
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $Parser         = $self->{Parser};
    my $BaselineParser = $self->{BaselineParser};
    my $Interval       = $self->{Interval};
    my $URL            = $self->{URL};
    my %args = @_;

    # Setup some reasonable thresholds        
    my $expireAfterSec = int($Interval * 3);
    my $description = qq( 
        This object monitors the URL '$URL'.  It will set the status to 'Warning'
        if it is unable to retrieve the URL or if response times become unacceptable.
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
            "Upgrade to Failed if Warning occurs 2 times in $expireAfterSec sec" ],
        ExpireAfter          => "$expireAfterSec seconds",
        Description          => $description,
        RrdTimeCol           => '$time',
        RrdColumns           => [ '$data[0]' ],
        RrdFilter            => undef,
        RrdMin               => 0,
        RrdMax               => undef,
        RrdXFF               => undef,
        RrdCF                => undef,
        RrdDST               => undef,

        # These parms will be used with the BaselineParser object
        BaselineVBObjName    => undef,
        BaselineDiffStatus   => 'Warn',
        BaselineRules        => undef,
        BaselineRequirements => undef
    };

    # Run the validation    
    &validateParms(\%args,$defaultRules) || &fatal("Exiting");

    # Setup the VB object for response time parser.
    my $vbObj = $Parser->addVBObj(
        VBObjName           => $args{VBObjName},
        TextHistoryLimit    => $args{TextHistoryLimit},
        ReverseText         => $args{ReverseText},
        Rules               => $args{Rules},
        Requirements        => $args{Requirements},
        StatusHistoryLimit  => $args{StatusHistoryLimit},
        StatusChangeActions => $args{StatusChangeActions}, 
        StatusUpgradeRules  => $args{StatusUpgradeRules},
        ExpireAfter         => $args{ExpireAfter},
        Description         => $args{Description},
        BaselineDiffStatus  => undef,
        RrdTimeCol          => $args{RrdTimeCol},
        RrdColumns          => $args{RrdColumns},
        RrdFilter           => $args{RrdFilter},
        RrdMin              => $args{RrdMin},
        RrdMax              => $args{RrdMax},
        RrdXFF              => $args{RrdXFF},
        RrdCF               => $args{RrdCF},
        RrdDST              => $args{RrdDST},
    );

    return undef if (! defined $vbObj);

    # Now define what graphs to show on this object's page, but only if 
    # a value was specified for 'RrdColumns'
    if($args{RrdColumns})
    {
        $vbObj->addGraphGroup (
            GroupNumber    => 1,
            DataSourceList => undef,
            Labels         => 'resp time (sec)',
            Title          => "URL $URL",
            CF             => undef,
        );
    }

    # If a BaselineVBObjName parm was specified, then setup the VB object
    # for the baseline parser
    my $baselineVbObj;
    if (defined $args{BaselineVBObjName})
    {
        $baselineVbObj = $BaselineParser->addVBObj(
            VBObjName           => $args{BaselineVBObjName},
            Rules               => $args{BaselineRules},
            Requirements        => $args{BaselineRequirements},
            StatusHistoryLimit  => $args{StatusHistoryLimit},
            StatusChangeActions => $args{StatusChangeActions}, 
            StatusUpgradeRules  => $args{StatusUpgradeRules},
            ExpireAfter         => $args{ExpireAfter},
            Description         => $args{Description},
            BaselineDiffStatus  => $args{BaselineDiffStatus}
        );

        return undef if (! defined $baselineVbObj);
    }

    ($vbObj,$baselineVbObj);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Execute the command associated with the object.
# Input Parms:  None
# Output Parms: Retvals: $::NOT_FINISHED (-1), $::FINISHED (0), $::ERROR (1)
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;

    my $ErrorStatus     = $self->{ErrorStatus};
    my $Interval        = $self->{Interval};
    my $Parser          = $self->{Parser};
    my $BaselineParser  = $self->{BaselineParser};
    my $header          = $self->{DebugHeader};
    my $ua              = $self->{ua};
    my $req             = $self->{req};
    my $URL             = $self->{URL};
    my $lastTime        = $self->{lastTime};
    my $AllowCookies    = $self->{AllowCookies};
    my $cookieJar       = $self->{cookieJar};

    my $now = time;
    my ($sleepTime);

    # If it's not time to run yet, then return
    if(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to check '$URL', wait $sleepTime seconds")
            if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }

    # Make the HTTP request
    &log("Requesting HTML from '$URL'") if ($VERBOSE > 1);

    # Add in any cookies if we're allowing cookies
    $cookieJar->add_cookie_header($req) if ($AllowCookies);

    my $res = $ua->request($req);
    my $code = $res->code;    
    my $content = $res->content;
    my $elapsedTime = time - $now;

    # Check the reply
    if($res->is_success)
    {
        # Call the response time parser, with the elapsed time
        $Parser->parseData([[$elapsedTime,0]],$::SUCCESS);

        # Split the content into separate lines
        my @lines = split(/\n/,$content);
        # Add CR back onto the end
        grep(s/$/\n/,@lines);

        # Escape out HTML control characters
        grep(s/</\&lt;/g && s/>/\&gt;/g, @lines);

        # Call the baseline parser with the actual HTML text
        $BaselineParser->parseData(\@lines,$::SUCCESS);

        # Store any returned cookies
        $cookieJar->extract_cookies($res) if ($AllowCookies);

        &log($cookieJar->as_string) if ($VERBOSE > 2);
    }
    else
    {
        my $msg = "Error retrieving URL: '$URL' - Code $code";
        $Parser->parseData([[0,1]],$ErrorStatus,$msg);
        $BaselineParser->parseData(undef,$ErrorStatus,$msg);
    }

    $sleepTime = $self->calcSleepTime(1);

    ($sleepTime,$::NOT_FINISHED);
}

# Simple calls to pass on to the parser
sub getLastRows   { shift->{Parser}->getLastRows; }
sub addGraphGroup { shift->{Parser}->addGraphGroup(@_); }

# Put in a stub for handleSignal
sub handleSignal  { (0); }

1;
__END__

=head1 NAME

VBTK::Http - Web server monitoring

=head1 SYNOPSIS

  $t = new VBTK::Http ( 
    URL => 'http://www.testhost.com');

  $t->addVBObj (
    VBObjName         => '.external.http.testhost.resp',
    BaselineVBObjName => '.external.http.testhost.baseline' );

  &VBTK::runAll;

=head1 DESCRIPTION

This perl library provides the ability to do simple monitoring of a web page.
This data-gatherer class is a little different in that it is setup to make use
of two separate VBObjects by default.

The primary VBObject records response time and success 
of retrieval.  A second BaselineVBObjName can be specified which gathers the 
actual HTML from the URL and compares it to a previously stored baseline.  This 
allows the detection of undesired content changes or error pages.

Note that the 'new VBTK::Http' and '$t->addVBObj' lines just initialize and 
register the objects.  It's the &VBTK::runAll which starts the monitoring.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $s = new VBTK::Http (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are as follows.  Note that some of these parms affect
the response time VBObject, while others affect the BaselineVBObject.

=over 4

=item Interval

The interval (in seconds) on which a connection attempt should be made to the 
specified URL.  (Defaults to 60)

    Interval => 60,

=item URL

A string containing a URL to connect to.  (Required)

    URL => 'http://www.testhost.com',

=item CheckImages

A boolean (0 or 1) which determines if images in the retrieved page should also
be retrieved and their checksum calculated.  (Not Yet Implemented)

    CheckImages => 0,

=item Filter

A Perl pattern expression which will be used to filter through the retrieved
HTML.  Only lines matching the pattern will be included in the baseline object.
You must specify a 'BaselineVBObjName' in order for this to have any affect.

    Filter => '<img',

=item Ignore

A Perl pattern expresssion used to filter out lines of HTML.  Lines matching
the pattern will be ignored.  The 'Ignore' parm will override the 'Filter'
parm.  This only affects the object specified in 'BaselineVBObjName'.

    Ignore => '^\s*$',

=item PreProcessor

A pointer to a subroutine to which incoming data should be passed for
pre-processing.  The subroutine will be passed a pointer to the @data array
as received by the Parser which will contain lines of HTML as retrieved 
from the specified URL.  The PreProcessor subroutine can then alter the 
data as necessary.  A common use for this is in hiding data which changes
with every request, such as a 'jsession=' session id, so that the baseline
diff does not show the HTML as having changed since the last request.

    # Hide changing jsession values so the baseline will be consistent
    PreProcessor = sub {
        my($data) = @_;
        @{$data} = grep(s/jsessionid=\w+/jsessionid=-removed-;/g,@{$data});
    }

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.  This only affects the response time VBObject in this
case.  Defaults to the following:

    VBHeader => [ 'Time              Resp Time (sec)',
                  '----------------- ---------------' ];

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.  This only affects the response time VBObject in this case.  The
only useful variable here is '$data[0]' which get the response time in seconds.
Defaults to:

    VBDetail => [ '@<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>',
                  '$time,            $data[0]' ],

=item LogFile

A string containing the path to a file where a log file should be written.  
Leave blank if no log file is desired.  (Defaults to undef).

    LogFile => '/var/log/http.testhost.log',

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

=item Timeout

A number indicating the max number of seconds which can elapse before the 
connection attempt is killed and the status of any VBObjects set to
the status specified in 'ErrorStatus'.  (Defaults to 15).

    Timeout => 15,

=item ErrorStatus

The status to which any associated VBObjects should be set if the HTTP
request fails or times out.  (Defaults to 'Warning')  

    ErrorStatus => 'Warning',

=item DebugHeader

A string which will be printed to STDOUT as part of debug messages.
Four debug levels are available (1-4) by setting the 'VERBOSE' environment
variable.  This is helpful when trying to debug with several Http objects 
running under a single unix process.  (Defaults to the URL)

    DebugHeader => 'URL1',

=item AllowCookies

A boolean value (0 or 1) indicating whether the client should make use of
cookies when requesting URL's.  The cookies are only stored in memory, so
restarting the client causes them to be cleared out, but it helps if you're
monitoring a web site which would otherwise allocate you a new session with
every request.  (Defaults to 1).

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  See L<VBTK::Parser> for a detailed
description of the main parameters.  This class is special, however in that it
makes use of two VBObjects by default.  The usual parameters correspond to the
response time VBObject.  These are described in L<VBTK::Parser>.  An additional
4 parameters are used by the baseline VBObject as follows:

=over 4

=item BaselineVBObjName

Same as 'VBObjName' but for the Baseline VBObject.  This is required to make
use of any of the baseline functionality.  (Defaults to none).

    BaselineVBObjName => '.external.http.rmthost.baseline',

=item BaselineDiffStatus

A string containing a status to which the baseline VBObject should be set if
there are differences between the retrieved text and the baseline.  If this is
not set, then no baseline comparison will be done.  (Defaults to none).

    BaselineDiffStatus => 'Warning',

=item BaselineRules

Same as 'Rules' (See L<VBTK::Parser>) but for the Baseline VBObject.  
No splitting is done on the 
data coming into the baseline VBObject, so the only really useful variable
which you can use in 'BaselineRules' is '$data', which is the full text of the 
current line of HTML.  This is useful for looking for error messages or other 
unwanted text in the HTML.

    BaselineRules => [
        '$data =~ /error|warn/i' => 'Warning' ],

=item BaselineRequirements

Same as 'Requirements' (See L<VBTK::Parser>), but for the baseline VBObject.
No splitting is done on 
the data coming into the baseline VBObject, so the only really useful variable
which you can use in 'BaselineRequirements' is '$data', which is the full text
of the current line of HTML.  This is useful for ensuring that the retrieved
HTML contains certain text which you know should be there every time.

    BaselineRequirements => [
        '$data =~ /success/i' => 'Warning' ],

=back

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

VBTK::Wrapper
VBTK::ClientObject

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
