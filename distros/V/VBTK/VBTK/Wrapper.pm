#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Wrapper.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library to simplify the encapsulation of the
#                       execution of other programs.
#
#          Description: This perl library provides the ability to encapsulate the
#                       execution of another program, capturing STDOUT and searching
#                       it for text patterns indicating success or failure.  It then
#                       can set the status of a vbserver object based on the
#                       results.
#
#           Directions:
#
#           Depends on: VBTK::Common.pm
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
#       $Log: Wrapper.pm,v $
#       Revision 1.9  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/19 19:12:06  bhenry
#       Changed to use unix time internally, to avoid DST problems
#
#       Revision 1.5  2002/02/13 07:38:51  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.4  2002/01/25 07:14:12  bhenry
#       Changed to make use of calcSleepTime
#
#       Revision 1.3  2002/01/23 20:27:52  bhenry
#       Changed to inherit from Parser and support inheritance
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#

package VBTK::Wrapper;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK;
use VBTK::Common;
use VBTK::Parser;
use VBTK::InputStream;
use Storable qw(dclone);

# Inherit methods from Parser class
our @ISA = qw(VBTK::Parser);

# Setup package constants
our $FILE_HANDLE_COUNT = 1;

# Setup global package variables.
our $VERBOSE=$ENV{VERBOSE};

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

    # For backward compatibility
    $self->{SourceList} = $self->{Execute} . " |"
        if (($self->{SourceList} eq '')&&($self->{Execute} ne ''));

    # Setup a hash of default parameters
    my $defaultParms = {
        Interval          => undef,
        Execute           => undef,
        SourceList        => $::REQUIRED,
        VBServerURI       => $::VBURI,
        VBHeader          => undef,
        VBDetail          => [ '$data' ],
        LogFile           => undef,
        LogHeader         => undef,
        LogDetail         => undef,
        RotateLogAt       => '12:00am',
        RotateLogOnEOF    => undef,
        PreProcessor      => undef,
        Split             => undef,
        Filter            => undef,
        Ignore            => undef,
        SkipLines         => undef,
        Timeout           => undef,
        TimeoutStatus     => $::TIMEOUT,
        Follow            => undef,
        FollowTimeout     => ((2 * $self->{Interval}) + 10),
        FollowHeartbeat   => undef,
        SetRunStatus      => undef,
        NonZeroExitStatus => $::FAILED,
        SuppressStdout    => 1,
        SuppressMessages  => 1,
        DebugHeader       => undef
    };

    # Run the validation, setting defaults if values are not already set
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Make sure the program specified is executable
    my $lastSource = $self->{SourceList};

    # If sourcelist is an array, then just look at the last entry
    $lastSource =  pop(@{[@{$self->{SourceList}}]})
        if (ref($self->{SourceList}) eq 'ARRAY');

    # Call the super-class Parser to initialize it.
    $self->SUPER::new;

    # Setup additional object attributes
    $self->{out} = [];          # Will store all output, used for vbobj message.
    $self->{cmd_out} = [];      # Will store output since the last retrieval
    $self->{cmd_open} = 0;      # Indicates whether the cmd is currently running.
    $self->{run_count} = 0;     # Counts number of times command has been run.

    # Create a file handle
    $self->{fhLabel} = "CMD" . $FILE_HANDLE_COUNT++;

    $self->{TimeoutStatus} = map_status($self->{TimeoutStatus});
    &fatal("Invalid Timeout Status specified") if ($self->{TimeoutStatus} eq '');

    $self->{NonZeroExitStatus} = map_status($self->{NonZeroExitStatus});
    &fatal("Invalid NonZeroExit Status specified") if ($self->{NonZeroExitStatus} eq '');

    &VBTK::register($self);
    ($self);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Execute the command associated with the object.
# Input Parms:  None
# Output Parms: Retvals: $::NOT_FINISHED (-1), $::FINISHED (0), $::ERROR (1), or retval
#               from process executed (0 - 255);
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;

    my $fhLabel         = $self->{fhLabel};
    my $cmd_open        = $self->{cmd_open};
    my $SetRunStatus    = $self->{SetRunStatus};
    my $Timeout         = $self->{Timeout};
    my $FollowTimeout   = $self->{FollowTimeout};
    my $FollowHeartbeat = $self->{FollowHeartbeat};
    my $TimeoutStatus   = $self->{TimeoutStatus};
    my $Interval        = $self->{Interval};
    my $Follow          = $self->{Follow};
    my $RotateLogOnEOF  = $self->{RotateLogOnEOF};
    my $header          = $self->{DebugHeader};
    my $out             = $self->{out};
    my $pid             = $self->{pid};

    my($retval,$tmp_status,$cmd_out,$msg,$ret_code,$sleepTime);

    $self->{DebugHeader} = $header = $fhLabel if ($header eq '');

    # Run the command if not already running.
    if(! $cmd_open)
    {
        ($sleepTime,$retval) = $self->openCmd;
        return ($sleepTime,$retval) if (($retval != $::NOT_FINISHED)||($sleepTime > 0));
    }

    $retval = $self->readRows;
    $cmd_out = $self->{cmd_out};

    # Dump rows retrieved into the $out array
    push(@{$out},@{$cmd_out});

    if($self->{ShowStdout})
    {
        foreach (@{$cmd_out})
        {
            print STDOUT "$header: " if($FILE_HANDLE_COUNT > 2);
            print STDOUT $_;
        }
    }

    $self->{rows_pending} = 1 if (@{$cmd_out} > 0);

    # Did the command complete yet?
    if($retval == $::FINISHED)
    {
        $self->{cmd_open} = 0;

        $ret_code = $self->{fh}->getRetVal();

        $msg = ($ret_code) ? "Command exited with return code '$ret_code'." : undef;

        # Convert any return codes > 255 or < 0 to 255 (Ksh only supports 0-255).
        $ret_code = 255 if (($ret_code > 255)||($ret_code < 0));

        $retval = $self->handleExit($ret_code,undef,$msg);

        # If the RotateLogOnEOF parm was specified, then rotate the log here.
        $self->rotate_log if ($RotateLogOnEOF);

        # If no interval was specified, then just return the exit code.
        return(0,$retval) if ($Interval eq '');
    }
    # Check to see if the command has passed the timeout value
    elsif(($Timeout > 0) && (($Timeout + $self->{startTime}) < time))
    {
        $self->{cmd_open} = 0;

        $msg = "Timed out waiting for '$header' to complete";
        $retval = $self->handleExit($ret_code,$TimeoutStatus,$msg);
        return(0,$retval) if ($Interval eq '');
    }
    # If Follow option wasn't specified, and SetRunStatus was specified, then
    # set status to Running once with no message
    elsif(($Follow eq '')&&($SetRunStatus)&&($self->{last_status_set}==0))
    {
        $self->parseData(undef,$::RUNNING);
        $self->{last_status_set} = time;
    }
    # If Follow option was specified, then if there is new output to be processed
    # and the status wasn't set in the last $Interval seconds, or the
    # FollowHeartbeat option was specified and no data has come through in the
    # last $Interval seconds, then pass the output to the Parser object to be
    # analyzed and transmitted to the vbserver process.
    elsif(($Follow)&&
          ((($self->{rows_pending} > 0)&&
            (($self->{last_status_set} + $Interval) <= time)) ||
          (($FollowHeartbeat)&&(($self->{last_data_read} + $Interval) < time))))
    {
        # Send updated message to vbserver with status of Running if 'SetRunStatus'
        # is true.  Otherwise, send the message with a status of Success and clear
        # the output.
        if ($SetRunStatus eq '')
        {
            $self->parseData($out,$::SUCCESS);
            @{$self->{out}} = ();
        }
        else
        {
            $self->parseData($out,$::RUNNING);
        }

        # Reset the counters
        $self->{last_status_set} += $Interval;
        $self->{last_data_read} = time;
        $self->{rows_pending} = 0;
    }
    # Check to see if the command has been inactive longer than the follow
    # timeout value.  If so then close the command and process a timeout 
    # status.
    elsif(($Follow)&&($FollowTimeout > 0)&&
          (($FollowTimeout + $self->{last_data_read}) < time))
    {
        $self->{cmd_open} = 0;

        $msg = "Timed out on '$header' waiting for data to arrive";
        $retval = $self->handleExit($ret_code,$TimeoutStatus,$msg);
        return(0,$retval) if ($Interval eq '');
    }

    (0,$::NOT_FINISHED);
}


#-------------------------------------------------------------------------------
# Function:     openCmd
# Description:  Check to see if it's time to run the command, and if it's already
#               been run.  If everything is ready, then run the command and link
#               the output to the corresponding file handle.
# Input Parms:  None
# Output Parms: retval ($::FINISHED,$::ERROR,$::NOT_FINISHED)
#-------------------------------------------------------------------------------
sub openCmd
{
    my $self = shift;

    my $fhLabel = $self->{fhLabel};
    my $SourceList = $self->{SourceList};
    my $Interval = $self->{Interval};
    my $cmd_open = $self->{cmd_open};
    my $run_count = $self->{run_count};
    my $Follow = $self->{Follow};
    my $header = $self->{DebugHeader};
    my $out = $self->{out};
    my $now = time;
    my ($sleepTime);

    return (0,$::NOT_FINISHED) if ($cmd_open);

    $header = $self->{DebugHeader} = $fhLabel if ($header eq '');

    # If no interval was specified, then only allow the command to be
    # run once.
    if($Interval eq '')
    {
        return (0,$::FINISHED) if ($run_count > 0);
    }
    # If interval was specified, check to see if enough time has elapsed.
    elsif(($sleepTime = $self->calcSleepTime()) > 0)
    {
        &log("Not time to run '$header' yet, wait $sleepTime seconds") if ($VERBOSE > 1);
        return ($sleepTime,$::NOT_FINISHED);
    }
    @{$self->{out}} = ();

    &log("Starting $header: $SourceList",$out,$self->{SuppressStdout},
        $self->{SuppressMessages});
    $self->{run_count}++;
    $self->{last_status_set} = 0;
    $self->{last_data_read} = time;
    $self->{rows_pending} = 0;
    $self->{startTime} = time;

    # Increment 'lastTime'
    $self->calcSleepTime(1);

    # Try to open the input stream
    my $fh = new VBTK::InputStream(SourceList => $SourceList,
                                   Follow     => $Follow);
    unless($fh)
    {
        $self->{fh} = undef;
        
        # If we failed the first exec, and an interval is specified, then just
        # unregister the object now, so that we don't try to run it again.
        if(($self->{run_count} == 1)&&($Interval))
        {
            &log("Disabling '$header' test");
            &VBTK::unRegister($self);
        }
            
        return (0,$::ERROR);
    }

    $self->{cmd_open} = 1;
    $self->{fh} = $fh;

    (0,$::NOT_FINISHED);
}

#-------------------------------------------------------------------------------
# Function:     readRows
# Description:  Read as many rows as are available to the file handle.  Timeout
#               and return after $timeout seconds have passed with no rows arriving
# Input Parms:  None
# Output Parms: Data
#-------------------------------------------------------------------------------
sub readRows
{
    my $self = shift;
    my $fh = $self->{fh};
    my $fhLabel = $self->{fhLabel};
    my $header = $self->{DebugHeader} || $fhLabel;
    my ($buf,$line,$rows,$eof,$num_rows,$timeleft,$found_eof,$leaveRows);
    my $start_time = time;

    &log("Reading data from '$header'") if ($VERBOSE > 1);

    # Read rows from the InputStream
    ($rows,$eof) = $fh->read;

    $self->{cmd_out} = $rows;

    if(@{$rows} > 0)
    {
        &log(scalar(@{$rows}) . " rows read from '$header'") if ($VERBOSE);

        # If the SkipLines parm starts with '-' then strip the rows off the front
        # until there are only abs(SkipLines) rows left.
        if(($self->{SkipLines} < 0)||($self->{SkipLines} =~ /^-/))
        {
            $leaveRows = abs($self->{SkipLines});
            while(@{$rows} > $leaveRows) { shift(@{$rows}) };
            $self->{SkipLines} = 0;
        }
        elsif($self->{SkipLines} > 0)
        {
            # Skip the number of rows specified by the SkipLines parm
            while(($self->{SkipLines}-- > 0)&&(@{$rows} > 0)) { shift(@{$rows}) };
        }
    }

    if ($eof)
    {
        ($::FINISHED);
    }
    else
    {
        ($::NOT_FINISHED);
    }
}

#-------------------------------------------------------------------------------
# Function:     handleSignal
# Description:  If the main program catches a signal, it will call this method
#               for each object.  If the object is currently running a process,
#               that process will be killed and marked as failed.
# Input Parms:  Message
# Output Parms: None
#-------------------------------------------------------------------------------
sub handleSignal
{
    my $self = shift;
    my $signal = shift;
    my $cmd_open = $self->{cmd_open};
    my $fh = $self->{fh};
    my $pid = $fh->getPid() if (defined $fh);
    my $Follow = $self->{Follow};
    my $SetRunStatus = $self->{SetRunStatus};
    my $error_msg;

    if ($cmd_open)
    {
        $error_msg = "Program caught signal SIG$signal";

        # If we're using the running status, then send a status of warning to
        # the object to indicate that it was killed.
        if($SetRunStatus)
        {
            &obj->handleExit(1,$::WARNING,$error_msg);
        }
        # Otherwise, just log an error and kill all sub-processes.
        else
        {
            &error("$error_msg");

            # Make sure process and child processes are dead if this is an abnormal
            # termination
            if ($pid)
            {
                &log("Killing child process '$pid'");
                kill 9, $pid;
            }
        }
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     handleExit
# Description:  Take care of parsing the output for required or error strings,
#               reviewing the process exit code, setting the status of the vbobject
#               and logging all important information
# Input Parms:  None
# Output Parms: Data
#-------------------------------------------------------------------------------
sub handleExit
{
    my $self = shift;
    my ($ret_code,$status,$error_msg) = @_;

    my $pid = $self->{fh}->getPid();
    my $header = $self->{DebugHeader};

    &error("$error_msg") if ($error_msg ne '');

    # If status isn't passed in, then set it based on the retcode passed in.
    if($status eq '')
    {
        $status = ($ret_code == 0) ? $::SUCCESS : $self->{NonZeroExitStatus};
    }

    # Make sure process and child processes are dead if this is an abnormal
    # termination
    if (($pid)&&($status ne $::SUCCESS))
    {
        &log("Killing child process '$pid'");
        kill 9, $pid;
    }

    &log("Finished $header",$self->{out},$self->{SuppressStdout},
     $self->{SuppressMessages});

    # Check for patterns in the output which might change the status
    $self->parseData($self->{out},$status,$error_msg);

    return ($ret_code) if ($ret_code > 0);
    return (0) if ($status eq $::SUCCESS);
    return (1);
}

1;
__END__

=head1 NAME

VBTK::Wrapper - Command line encapsulation and monitoring.

=head1 SYNOPSIS

  $t = new VBTK::Wrapper (
    Interval          => 60,
    Execute           => 'ping myhost',
    Split             => undef,
    Filter            => 'bytes from.*time=(\d+)',
    Ignore            => 'PING|^\s*$|^round-trip',
    SkipLines         => 1,
    VBServerURI       => 'http://myvbserver:4712',
    VBHeader          => undef,
    VBDetail          => [ '$time $data' ],
    LogFile           => '/var/log/ping.myhost.log'
    LogHeader         => undef,
    LogDetail         => [ '$time $data' ],
    RotateLogAt       => '12:00am',
    RotateLogOnEOF    => undef,
    Timeout           => undef,
    TimeoutStatus     => undef,
    Follow            => 1,
    FollowTimeout     => 150,
    FollowHeartbeat   => undef,
    SetRunStatus      => undef,
    NonZeroExitStatus => undef,
    DebugHeader       => 'ping myhost',
 );

=head1 DESCRIPTION

This perl library provides the ability to encapsulate the execution of a 
command-line program, capturing STDOUT, parsing and filtering it, and searching
it for text patterns indicating success or failure.  It then can set the status
of a vbserver object based on the results.

=head1 SUB-CLASSES

There are many values to setup when declaring a Wrapper object.  To 
simplify things, most of these values will default appropriately.  In
addition, several sub-classes are provided which have customized defaults
for specific uses.  The following sub-classes are provided:

=over 4

=item L<VBTK::Wrapper::Ping|VBTK::Wrapper::Ping>

Defaults for monitoring a list of hosts using 'ping'.

=item L<VBTK::Wrapper::DiskFree|VBTK::Wrapper::DiskFree>

Defaults for monitoring disk space using the 'df' command.

=item L<VBTK::Wrapper::Vmstat|VBTK::Wrapper::Vmstat>

Defaults for monitoring system performance using the 'vmstat'.

=item L<VBTK::Wrapper::PrtDiag|VBTK::Wrapper::PrtDiag>

Defaults for monitoring system hardware status using the 'prtdiag' command.
(This is a Sun-specific utility, I think).

=item L<VBTK::Wrapper::Metastat|VBTK::Wrapper::Metastat>

Defaults for monitoring DiskSuite volume status.  (Sun-specific)

=item L<VBTK::Wrapper::Vxprint|VBTK::Wrapper::Vxprint>

Defaults for monitoring Veritas Volume Manager disk volume status using
the 'vxprint' command.

=item L<VBTK::Wrapper::Log|VBTK::Wrapper::Log>

Defaults for monitoring a log file.

=back

Others are sure to follow.  If you're interested in adding your own sub-class,
just copy and modify some of the existing ones.  Eventually, I'll get around
to documenting this nicely.


=head1 METHODS

The following methods are supported

=over 4

=item $s = new VBTK::Wrapper (<parm1> => <val1>, <parm2> => <val2>, ...)

The allowed parameters are:

=over 4

=item Interval

The interval (in seconds) on which the command should be run.  If no interval
is specifed, then the command will only run once and then the process will 
exit.

    Interval => 60,

=item Execute

A string to be executed on the command line.

    Execute => 'ping myhost',

=item SourceList

This can be used in place of the 'Execute' parm if the thing you want to monitor
is a text file instead of the output of a command.  An example of this would be
a log file such as /var/adm/messages.  If specified, this overrides any value
in the 'Execute' paramter.  It can be a string, or a pointer to an array.

    SourceList => '/var/adm/messages',

=item Split

A Perl pattern expression indicating how to split the current line being 
processed into columns which will be placed in the @data array.  This is only
necessary if you're planning to use the @data variables in your VBDetail parm
or later in your rules.  The value will be passed in a call to 'split'.  If 
no 'Filter' is specified, then this will default to '\s+'.

    Split => '\s+',

=item Filter

A Perl pattern expression which will be used to filter through the incoming
data.  Only lines matching the pattern will be used.  If the pattern contains
parenthesis (), then the resulting $1, $2, etc will be used to populate the
@data array.  However, if a 'Split' pattern is specified, it will always 
override the data placed in @data.

    Filter => 'bytes from.*time=(\d+)',

=item Ignore

A Perl pattern expresssion used to filter out incoming data.  Lines matching
the pattern will be ignored.  The 'Ignore' parm will override the 'Filter'
parm.

    Ignore => '^\s*$',

=item SkipLines

A number indicating how many lines to skip at the start of the incoming data.
For example, the first 3 lines of the 'vmstat' command output should be
discarded.  A negative value will skip to the end of the first batch of 
incoming data, so for example a value of '-3' would ignore all but the last
3 rows of the first batch of data.  This is useful when tailing a log file
where you only want to look at new data being added to the log file.

    Skiplines => 3,

=item PreProcessor

A pointer to a subroutine to which incoming data should be passed for
pre-processing.  The subroutine will be passed a pointer to the @data array
as received by the Parser.  It will initially be a 1-dimensional array which
simply contains the output lines.  The subroutine can add/remove rows from the
array, alter data, or reformat the array into a 2-dimensional array.  If the
array is changed to a 2-dimensional array, then any 'Filter', 'Ignore', or
'Split' parms will be ignored, since the data will have already been split.
This is a fairly advanced function, so don't use it unless you know what
you're doing.

    # This has the same effect as using Split => '\s+'
    PreProcessor = sub {
        my($data) = @_;
        @{$data} = map { [ split('\s+',$_) ] } @{$data};
    }

=item VBServerURI

A URI which specifies which VB Server to report results to.  Defaults to the 
environment variable $VBURI.

    VBServerURI => 'http://myvbserver:4712',

=item VBHeader

An array containing strings to be used as header lines when transmitting results
to the VB Server process.

    VBHeader => [ 
        'Date             Response Time  Delta Response Time',
        '---------------- -------------- -------------------' ],

=item VBDetail

An array containing strings to be used to format the detail lines which will be
sent to the VB Server process.  These strings can make use of the Perl picture
format syntax.

    VBDetail => [
        '@<<<<<<<<<<<<<<< @>>>>>>>>>>>>> @>>>>>>>>>>>>>>>>>>',
        '$time            $data[0]       $delta[0]' ],

The following variables will be set just before these detail lines are evaluated:

=over 4

=item $time

The current datestamp in the form YYYYMMDD-HH:MM:SS

=item $data

The full text of the line currently being parsed.

=item @data

An array containing the split data.  See the Split, Filter, and Pre-Processor
Parms for details on how to split the data being parsed into columns.

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.  This is
very common in SNMP monitors.

=item @rate

An array containing the same data as in the @delta array, but divided by the
number of seconds since the last data retrieval.

=back

=item LogFile

A string containing the path to a file where a log file should be written.

    LogFile => '/var/log/ping.myhost.log',

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

    RotateLogAt => '12:00am',

=item RotateLogOnEOF

A boolean (1 or 0) value indicating whether the log should be rotated each 
time the command finishes or reaches EOF.  This is only really useful when
using SourceList to tail a log file in 'Follow' mode.

=item Timeout

A number indicating the max number of seconds which can elapse before the 
command being executed is killed and the status of any VBObjects set to
the status specified in 'TimeoutStatus'.  

    Timeout => 120,

=item TimeoutStatus

The status to which any associated VBObjects should be set if a timeout 
occurs.  Keep in mind that if you leave this set to Timeout, you'll need
to include status change actions for the 'Timeout' status when defining
your VBObjects.  (Defaults to 'Timeout')  

    TimeoutStatus => 'Warning',

=item Follow

A boolean (0 or 1) indicating whether the Wrapper engine should 'follow' the
output of the command being executed, reporting incoming data as it arrives.
This option is normally used when executing commands such as 'vmstat 60' which
would output stats every 60 seconds, but never terminate.  It's also used when
tailing a log file with the 'SourceList' parm.  (Defaults to 0).

    Follow => 1,

=item FollowTimeout

A number indicating how many seconds may pass without any incoming data before
the command is killed and the status is set to 'TimeoutStatus'.  This is used
to detect the hang-up or loss of connectivity to commands which are supposed
to output data every n seconds.  This value is only used if in 'Follow' mode.
(Defaults to 'undef')

    FollowTimeout => 150,

=item FollowHeartbeat

A boolean (0 or 1) indicating whether the Wrapper engine should force the
transmission of a status to the VBServer if 'Interval' seconds have passed
with no incoming data.  This is usually used when tailing log files, where
the stream of data is inconsistent, and although no new data has been appended
to the logs, you want the VBServer to know that the monitoring process is 
still running. (Defaults to 0).

    FollowHeartbeat => 1,

=item SetRunStatus

A boolean (0 or 1) indicating whether the status of the associated VBObjects
should be set to 'Running' during the period that the command is being 
executed.  This is really only used for monitoring long-running processes,
such as a nightly backup.  I don't use this very often.  (Defaults to 0).

    SetRunStatus => 1,

=item NonZeroExitStatus

A string specifying the status to which any associated VBObjects should be
set if the command being executed exits with a non-zero exit code.  Setting
this to 'Success' means that the non-zero exit code will be ignored, leaving
the status to be determined by the VBObject rules and requirements.  
Note that the code which reads in these status strings
only looks at the first character and is case-insensitive, so you could 
specify ('F','fail','Failure',etc.) and it would always interpret it as
'Failed'.  (Defaults to 'Failed')  

    NonZeroExitStatus => 'Warning',

=item DebugHeader

A string which will be printed to STDOUT as part of debug messages.
Four debug levels are available (1-4) by setting the 'VERBOSE' environment
variable.  This is helpful when trying to debug with several Wrapper objects 
running under a single unix process.

    DebugHeader => 'ping myhost',

=back

=item $o = $s->addVBObj(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addVBObj' is used to define VBObjects which will appear on the VBServer
to which status reports are transmitted.  See the 
L<VBTK::ClientObject|VBTK::ClientObject> class for a list of valid parms and
their descriptions.  

=back

=head1 SEE ALSO

=over 4

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::ClientObject|VBTK::ClientObject>

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK|VBTK>

=item L<VBTK::Wrapper::Ping|VBTK::Wrapper::Ping>

=item L<VBTK::Wrapper::DiskFree|VBTK::Wrapper::DiskFree>

=item L<VBTK::Wrapper::Vmstat|VBTK::Wrapper::Vmstat>

=item L<VBTK::Wrapper::PrtDiag|VBTK::Wrapper::PrtDiag>

=item L<VBTK::Wrapper::Metastat|VBTK::Wrapper::Metastat>

=item L<VBTK::Wrapper::Vxprint|VBTK::Wrapper::Vxprint>

=item L<VBTK::Wrapper::Log|VBTK::Wrapper::Log>

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







