#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Parser.pm,v $
#            $Revision: 1.9 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to parse passed data,
#                       logging results to a log file, and setting VBServer
#                       objects based on a passed rule set.
#
#           Invoked by: VBTK::Oracle.pm, VBTK::Snmp.pm, VBTK::Wrapper.pm
#
#           Depends on: VBTK::Common.pm, VBTK::Client.pm
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
#       $Log: Parser.pm,v $
#       Revision 1.9  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.7  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.6  2002/02/19 19:07:56  bhenry
#       Changed 'lastTime' counter to 'lastRunTime' in calcSleepTime method, to
#       avoid conflict with another 'lastTime' counter recently added.
#
#       Revision 1.5  2002/02/13 07:40:12  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#

package VBTK::Parser;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Client;
use VBTK::ClientObject;
use VBTK::Objects::UpgradeRules;
use VBTK::Objects::ChangeActions;
use VBTK::Objects::Rrd;
use Date::Manip;
use FileHandle;
use POSIX ":sys_wait_h";

$SIG{INT} = 'fatal';

our $VERBOSE = $ENV{VERBOSE};

our $MAX_LOG_RECOVERY_INTERVAL = 1000;
our $FORK_SUPPORTED = 1;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members,
#               initializes a VBClient object, opens log files, and checks for
#               required name/value hash pairs.
# Input Parms:  VBTK::Parser name/value hash
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my ($type,$self);
    
    # If we're passed a hash, then it's probably from an inheriting class
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

        # Set any passed parms
        $self->set(@_);

        # Setup a hash of default parameters
        my $defaultParms = {
            Interval          => undef,
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
            Ignore            => undef
        };

        # Validate the passed parms against the default parms.
        $self->validateParms($defaultParms) || &fatal("Exiting");
    }

    # Allocate some internal structures
    $self->{vbObjects} = [];
    $self->{lastRows} = {};
    $self->{parseCount} = 0;

    # Default 'Split' to '\s+' unless Filter contains a '(' which means it will
    # be doing the splitting as part of the pattern match.
    $self->{Split} ||= '\s+' unless ($self->{Filter} =~ /\(/);

    # Create a VBClient object to be used for reporting status changes to the main
    # VBServer process.
    if($self->{VBServerURI} ne '')
    {
        &log("Setting up VBClient for $self->{VBServerURI}") if ($VERBOSE);
        $self->{vbClientObj} = new VBTK::Client(RemoteURI => $self->{VBServerURI});

        fatal("Can't setup vbclient object for '$self->{VBServerURI}") 
            if ($self->{vbClientObj} eq '');
    }

    # Set the logRecoveryDone flag if no log file is specified or if no log 
    # detail format is specified.
    $self->{logRecoveryDone} = 1 if (! defined $self->{LogFile});
    
    # This disables log recovery.  I'm going to yank this out at some point 
    # because it's too confusing.  I'll add a separate utility to do log
    # importing.  For now, this will disable it.
    $self->{logRecoveryDone} = 1;

    $self->openLog;

    $self;
}

#-------------------------------------------------------------------------------
# Function:     checkLogRotate
# Description:  Check to see if it's time to rotate the log.  If so, then
#               Close the log file and rename it if it's open.  Then open a new
#               log file.  If the log file name contains whitespace, then assume
#               it's actually a command to be executed.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkLogRotate
{
    my $self = shift;
    my $nextLogRotate = $self->{nextLogRotate};

    return (0) unless ($nextLogRotate);

    my $now = &datestamp();

    &log("Checking next=$nextLogRotate to decide if log" .
         " should be rotated") if ($VERBOSE > 1);

    $self->rotateLog if ($nextLogRotate le $now);

    (0);
}


#-------------------------------------------------------------------------------
# Function:     rotateLog
# Description:  Close the log file and rename it if it's open.  Then open a new
#               log file.  If the log file name contains whitespace, then assume
#               it's actually a command to be executed.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub rotateLog
{
    my $self = shift;
    my $LogFile = $self->{LogFile};
    my $LogHandle = $self->{LogHandle};

    &log("Rotating log '$LogFile'");

    # Close the log handle if it's open.
    $LogHandle->close() if ($LogHandle ne '');

    # Rename the log to append a date/timestamp
    if (-f $LogFile)
    {
        my $timestamp = &log_datestamp();
        rename($LogFile,"$LogFile.$timestamp") ||
            error("Unable to rename logfile to '$LogFile.$timestamp'");
    }

    $self->openLog;
}


#-------------------------------------------------------------------------------
# Function:     openLog
# Description:  Open a new log file.  If the log file name contains whitespace,
#               then assume it's actually a command to be executed.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub openLog
{
    my $self = shift;
    my $LogFile = $self->{LogFile};
    my $LogHeader = $self->{LogHeader};
    my $RotateLogAt = $self->{RotateLogAt};
    my ($cmdChar,$nextLogRotate,$tmp,$now,$header);

    return if ($LogFile eq '');

    # Make sure the standard perf directory exists for this host
    mkdir "$::VBHOME/perf", 0755 if(! -d "$::VBHOME/perf");
    mkdir "$::VBHOME/perf/$::HOST", 0755 if(! -d "$::VBHOME/perf/$::HOST");

    # If the LogFile name string begins with '|', then assume it's a stream and
    # don't append a '>>' to the front of it.
    $cmdChar = '>> ' if ($LogFile !~ /^\|/);

    my $handle = new FileHandle;
    $handle->open("$cmdChar$LogFile") ||
        fatal("Cannot open LogFile stream to '$cmdChar$LogFile'");
    $self->{LogHandle} = $handle;
    $handle->autoflush(1);

    if($RotateLogAt)
    {
        $now = &DateCalc("today","");

        # Calculate the difference between now and the RotateLogAt string
        $tmp = &DateCalc($now,$RotateLogAt);

        # If it's a time of day which has already passed, then add 1 day to it
        $tmp = &DateCalc($tmp,"+ 1 day") if ($tmp =~ /^\-/);

        # If it comes out as relative (starts with a +) then add it to $now.
        $tmp = &DateCalc($now,$tmp) if ($tmp =~ /^\+/);
        $self->{nextLogRotate} = $tmp;
        &log("Log was scheduled to be rotated at '$RotateLogAt', $tmp")
            if ($VERBOSE);
    }

    if ($LogHeader ne '')
    {
        $header = swrite($LogHeader);
        print $handle $header;
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     addVBObj
# Description:  Read from a passed name/value hash a VBServer object name
#               and associated rules for determining how to set the status of
#               that object.
# Input Parms:  Name/Value hash
# Output Parms: None
#-------------------------------------------------------------------------------
sub addVBObj
{
    my $self = shift;
    my $vbObjects = $self->{vbObjects};
    my $LogFile   = $self->{LogFile};

    &fatal("VBTK::Parser::addRules: Must specify VBServerURI before calling addVBObj")
        if ($self->{vbClientObj} eq '');

    my %args = @_;    

    # Retrieve the VBServer object name
    my $VBObjName = $args{VBObjName};

    # Do validations related to graphing
    &fatal("VBTK::Parser::addVBObj: Can't use Rrd/Graphing functionality without " .
           "specifying 'VBDetail' for '$VBObjName'")
        if((($args{RrdColumns} ne '')||($args{RrdTimeCol} ne ''))&&
           ($self->{VBDetail} eq ''));

    # Now create a corresponding VBTK::ClientObject
    my $vbObj = new VBTK::ClientObject (
        VBClientObj => $self->{vbClientObj},
        Interval    => $self->{Interval},
        LogFile     => $self->{LogFile},
        %args
    );

    # Now store the new object in an array    
    push(@{$vbObjects},$vbObj);

    ($vbObj);
}

#-------------------------------------------------------------------------------
# Function:     addGraphGroup
# Description:  Call 'addGraphGroup' for each VBObject associated with this parser,
#               passing in the passed parms.
# Input Parms:  Graph Group Parms
# Output Parms: None
#-------------------------------------------------------------------------------
sub addGraphGroup
{
    my $self = shift;
    my $vbObjects = $self->{vbObjects};

    foreach my $vbObj (@{$vbObjects})
    {
        $vbObj->addGraphGroup(@_);
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     parseData
# Description:  Parse a 2 dimensional array of values.  If a pre-processor
#               subroutine is defined, then call it.  For each row in the
#               2D array, call the parse_row method.  At the end, call the
#               setVBObjects method.
# Input Parms:  Pointer to 2D array, override status, and override message.
# Output Parms: None
#-------------------------------------------------------------------------------
sub parseData
{
    my $self = shift;
    my $PreProcessor = $self->{PreProcessor};
    my $logRecoveryDone = $self->{logRecoveryDone};
    my $lastTime = $self->{lastTime};
    my ($dataPtr,$status,$msg) = @_;
    my ($pos,$retval,$currTime,$timeDelta);

    my $time = &log_datestamp();
    
    # Check to see if the log needs to be rotated
    $self->checkLogRotate();
    
    # Try to read all existing logs for this wrapper object to catch up on
    # missing log data.
    $self->recoverGraphDataFromLog($time) if (! $logRecoveryDone);

    # If a pre-processor subroutine is defined, then make a copy of the
    # dataPtr array and pass it to the pre-processor.
    if(($PreProcessor)&&(defined $dataPtr))
    {
        &log("Passing " . (@{$dataPtr} + 0) . " rows to PreProcessor") if ($VERBOSE > 2);
        $dataPtr = [ @{$dataPtr} ];
        &$PreProcessor($dataPtr);
        &log("PreProcessor returned " . (@{$dataPtr} + 0) . " rows") if ($VERBOSE > 2);
    }

    if(defined $dataPtr)
    {
        log("Parsing " . (@{$dataPtr} + 0) . " rows") if ($VERBOSE > 2);

        $currTime = time;
        $timeDelta = $currTime - $lastTime if ($lastTime);
        foreach $pos (0..(@{$dataPtr}-1))
        {
            $retval += $self->parseRow($dataPtr->[$pos],$time,$pos,$timeDelta);
        }
        $self->{lastTime} = $currTime;
    }

    $self->setVBObjects($status,$msg,$time);
}

#-------------------------------------------------------------------------------
# Function:     parseRow
# Description:  Parse a row of values.  Calculate the delta between the current
#               rows values and the previous rows values if the delta keyword
#               is used in any of the clauses or the format statements.  Format
#               the VBServer messages and Log message.  Step through rules for
#               each VBServer object, setting statuses appropriately.
# Input Parms:  Pointer to array, timestamp value
# Output Parms: Return value
#-------------------------------------------------------------------------------
sub parseRow
{
    my $self = shift;
    my ($row,$time,$rowPos,$timeDelta) = @_;
    my $deltaKey        = $rowPos;
    my $vbObjects       = $self->{vbObjects};
    my $VBDetail        = $self->{VBDetail};
    my $LogDetail       = $self->{LogDetail};
    my $LogHandle       = $self->{LogHandle};
    my $lastRow         = $self->{lastRows}->{$deltaKey};

    my ($pos,$line,@data,@delta,@rate,$prevValue,$delta,$vbMessage,$logMessage,$vbObj);

    # If we were passed a reference to an array, then the line has already been
    # split, so just copy the data into @data.
    if (ref($row) eq 'ARRAY')
    {
        @data = @{$row};
        $row = join(' ',@data);
    }
    # Otherwise if it's a scalar, then run it through the filter and splitter.
    elsif (ref($row) eq '')
    {
        # Strip the whitespace off the end of the fulltext line
        $row =~ s/\s+$//g;

        &log("Processing row: $row") if ($VERBOSE > 3);

        # Run this row through the filters and skip it if it doesn't pass
        @data = &filterString($row,$self->{Filter},$self->{Ignore},$self->{Split});
        return 0 if (@data == 0);
    }
    else
    {
        &fatal("Invalid reference " . ref($row) . " passed to parseRow");
    }

    # Save the data for comparison on the next round
    $self->{lastRows}->{$deltaKey} = [ @data ];

    # Calculate the delta and rate for each column
    foreach $pos (0..$#data)
    {
        $prevValue = $lastRow->[$pos];
        $delta = ($prevValue =~ /^\d+$/) ? $data[$pos] - $prevValue : undef;
        $delta[$pos] = $delta;
        $rate[$pos] = ($timeDelta > 0) ? $delta/$timeDelta : undef;
    }
    
    &log("Parsing row: " . join(':',@data)) if ($VERBOSE > 2);

    # Format the VBServer object message and the Log message
    $vbMessage = swrite($VBDetail,$time,$row,\@data,\@delta,\@rate) if ($VBDetail ne '');
    $logMessage = swrite($LogDetail,$time,$row,\@data,\@delta,\@rate) if ($LogDetail ne '');
    print $LogHandle $logMessage if ($LogHandle ne '');
    &log("Extracting graph data from row - $logMessage") if ($VERBOSE > 3);

    # For each VBServer object, process the data for graphing, using the log message
    # as the input.  We parse the log output as input for the graph data, so that we
    # can read backwards and catch-up on data which was missed for some reason.  Also
    # test the objects rule clauses, setting statuses as specified
    foreach $vbObj (@{$vbObjects})
    {
        $vbObj->processText($time,$row,\@data,\@delta,\@rate,$vbMessage);
        $vbObj->processGraphData($time,$row,\@data,\@delta,\@rate);
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     recoverGraphDataFromLog
# Description:  If the graphing option is enabled for the object, try to read 
#               back over the existing log files to recover any data which has
#               not yet made it to the VBServer graph database.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub recoverGraphDataFromLog
{
    my $self = shift;
    my $time = shift;
    my $LogFile        = $self->{LogFile};
    my $vbObjects      = $self->{vbObjects};
    my $logRecoveryPid = $self->{logRecoveryPid};

    # Just return if we've already processed the logs
    if(($self->{logRecoveryDone})||(! defined $LogFile))
    {
        $self->{logRecoveryDone} = 1;
        return undef;
    }

    my ($fh,$file,$timestamp,$unixTimestamp,$reapedPid,$pid);
    my $startTime = time;

    # Check to see if we've already forked off the recovery process and if so,
    # check to see if the pid has completed.
    if (defined $logRecoveryPid)
    {
        &log("Checking to see if log recovery pid '$logRecoveryPid' has finished")
            if ($VERBOSE);
        $reapedPid = waitpid($logRecoveryPid,&WNOHANG);

        if(($reapedPid == $logRecoveryPid)||($reapedPid == -1))
        {
            &log("Log recovery process has completed") if ($VERBOSE);
            $self->{logRecoveryPid} = undef;
            $self->{logRecoveryDone} = 1;
        }
        return undef;
    }

    &log("Attempting to recover graphing data from past logs") if ($VERBOSE);

    my $earliestTimestamp = $self->getEarliestLastGraphDbTimestamp($time);

    # Don't bother to continue if we can't at least talk to the VB server.
    if (! defined $earliestTimestamp)
    {
        $self->{logRecoveryDone} = 1;
        return undef;
    }

    # If we've made it this far, then if forking is allowed, fork off a process 
    # to handle the log recovery.
    if ($FORK_SUPPORTED)
    {
        if ($pid = fork)
        {
            &log("Forked off log recovery process, pid = $pid") if ($VERBOSE);
            $self->{logRecoveryPid} = $pid;
            return undef;
        }
        elsif(! defined $pid)
        {
            &fatal("Could not fork log recovery process");
        }
    }

    # If we've made it this far, then mark the logRecoveryProcess as done.
    $self->{logRecoveryDone} = 1;

    # Make a list of all log files
    my @pastLogFiles = sort <$LogFile.[0-9]*>;

    # Now read them in one-by-one in order of oldest to newest, ending with the
    # current logfile itself.
    foreach $file (@pastLogFiles, $LogFile)
    {
        &log("Reading logfile '$file'") if ($VERBOSE > 1);

        if($file =~ /^$LogFile.([\d:-]+)$/)
        {
            $timestamp=$1;
            $unixTimestamp = &unixdate($timestamp);
        }
        elsif($file eq $LogFile)
        {
            $unixTimestamp = time;
        }
        else
        {
            &error("Invalid logfile '$file'");
            next;
        }

        &log("Comparing timestamp '$unixTimestamp' with Rrd last timestamp " .
             "$earliestTimestamp") if ($VERBOSE > 3);

        # Now compare the file timestamp with the last entered timestamp
        next if ($unixTimestamp < $earliestTimestamp);

        # Read in all data from the file and process it, adding it to the
        # graph data queue.
        $fh = new FileHandle "< $file";

        # Make sure the open worked
        unless($fh)
        {
            &error("Can't read from log file '$file'");
            next;
        }

        # Process each row in the log
        &log("Reading data from '$file'") if ($VERBOSE > 2);
        while (<$fh>)
        {
            foreach my $vbObj (@{$vbObjects})
            {
                $vbObj->processGraphData($_);
            }
        }
        $fh->close;

        $self->setVBObjects($::SUCCESS,"Loading graph data from logs");
    }

    # If we made it this far, and 'fork' is supported then we're the child 
    # process, so just exit.
    exit 0 if ($FORK_SUPPORTED);

    (0);
}

#-------------------------------------------------------------------------------
# Function:     getEarliestLastGraphDbTimestamp
# Description:  Request the last graphDb timestamp for each of the VBObjects 
#               associated with this parser object.  Determine the earliest
#               one and return it back.
# Input Parms:  None
# Output Parms: Earliest Last Graph Db Timestamp
#-------------------------------------------------------------------------------
sub getEarliestLastGraphDbTimestamp
{
    my $self = shift;
    my $time = shift;
    my $vbObjects   = $self->{vbObjects};
    my ($vbObj,$lastTimestamp);

    &log("Attempting to recover graphing data from past logs") if ($VERBOSE);

    my $earliestTimestamp = time;

    # Step through each vbObj requesting the last timestamp
    foreach $vbObj (@{$vbObjects})
    {
        $lastTimestamp = $vbObj->getLastGraphDbTimestamp($time);

        $earliestTimestamp = $lastTimestamp 
            if(($lastTimestamp > 0)&&($lastTimestamp < $earliestTimestamp));
    }

    &log("Earliest timestamp was $earliestTimestamp") if ($VERBOSE > 2);    
    ($earliestTimestamp);
}

#-------------------------------------------------------------------------------
# Function:     getLastRows
# Description:  Request the pointer to the 'lastRows' element which contains a 
#               two-dimensional matrix of the last rows processed by the parser.
# Input Parms:  None
# Output Parms: Pointer to two-dimensional matrix of last rows
#-------------------------------------------------------------------------------
sub getLastRows
{
    my $self = shift;
    my $lastRows = $self->{lastRows};

    # See if there are any non-numeric keys
    my @nonNumericKeys = grep(/[^\d]/, keys %{$lastRows});

    # Sort the key list based on whether it contains non-numeric keys
    my @keyList = (@nonNumericKeys > 0) ? 
        sort keys %{$lastRows} : sort byNum keys %{$lastRows};

    # Now return the values in order        
    [ map { $lastRows->{$_} } @keyList ];
}
sub byNum { $a <=> $b };


#-------------------------------------------------------------------------------
# Function:     setVBObjects
# Description:  Step through all VBServer objects, sending their statuses
#               and messages to the VBServer.  Override with the passed master
#               status and message if specified.
# Input Parms:  Master status, Master message
# Output Parms: None
#-------------------------------------------------------------------------------
sub setVBObjects
{
    my $self = shift;
    my ($masterStatus,$masterMsg,$time) = @_;
    my $vbObjects = $self->{vbObjects};
    my $VBHeader = $self->{VBHeader};
    my $errors = 0;

    return 0 if (! $self->{logRecoveryDone});

    # Generate the header string
    my $header = swrite($VBHeader,$time);

    # Step through each unique vbobject name specified
    foreach my $vbObj (@{$vbObjects})
    {
        $vbObj->sendStatus($masterStatus,$masterMsg,$header) || $errors++;
    }

    ($errors);
}


#-------------------------------------------------------------------------------
# Function:     swrite
# Description:  Read an array of format lines and return the resulting string
# Input Parms:  Pointer to array of format strings, Time value, Pointer to
#               data aray, Pointer to delta array.
# Output Parms: None
#-------------------------------------------------------------------------------
sub swrite
{
    my ($ptr,$time,$data,$dataPtr,$deltaPtr,$ratePtr) = @_;
    my ($str,$line,$pos,$numlines,$cmd);

    return undef if ($ptr eq '');

    # Copy the @data, @delta, and @rate arrays locally so that they can be used
    # in the formline calls.
    my @data = ($dataPtr) ? @{$dataPtr} : ();
    my @delta = ($deltaPtr) ? @{$deltaPtr} : ();
    my @rate = ($ratePtr) ? @{$ratePtr} : ();

    $numlines = @{$ptr};

    # Step through each format string
    for($pos = 0; $pos < $numlines; $pos++)
    {
        $line = $ptr->[$pos];

        # If the line contains an '@', then assume that it is a format
        # line and that the following line is the variable line
        if($line =~ /\@/)
        {
            $cmd = "formline '$line', $ptr->[$pos+1]";
            eval($cmd);
            &fatal("swrite: Can't eval: $cmd: $@") if ($@ ne '');
            $str .= "$^A\n";
            $^A = '';
            $pos++;
        }
        # Otherwise, just interpret the line.
        else
        {
            $cmd = "\$str .= \"$line\n\"";
            eval($cmd);
            &fatal("swrite: Can't eval: $cmd: $@") if ($@ ne '');
        }
    }
    ($str);
}


#-------------------------------------------------------------------------------
# Function:     filterString
# Description:  Process the passed string.  If the string matches the ignore
#               pattern, then return undef.  If it matches the filter pattern,
#               then if there are () in it, use them to construct an array of
#               $1, $2, etc.  If the split pattern is specified, then override
#               any () and just split the text apart.  Return the resulting 
#               array.
# Input Parms:  String, Filter Pattern, Ignore Pattern, Split Pattern
# Output Parms: Array of resulting values
#-------------------------------------------------------------------------------
sub filterString
{
    my ($string,$filterPattern,$ignorePattern,$splitPattern) = @_;
    my (@data);

    &log("Running filter on string - $string") if ($VERBOSE > 3);

    # Look for rows to ignore, if an Ignore filter was specified
    if(defined $ignorePattern)
    {
        if ($string =~ /$ignorePattern/)
        {
            &log("Ignoring row") if ($VERBOSE > 3);
            return ();
        }
    }

    if(defined $filterPattern)
    {
        # If there are any () in the filter, then create the data array
        # using the values of $1, $2, $3, etc.  Otherwise, just place the
        # whole row in $data[0];

        &log("Checking against filter '$filterPattern'") if ($VERBOSE > 3);
        @data = ($string =~ /$filterPattern/);
        return () if ((@data == 0)||((@data == 1)&&($data[0] eq '')));

        &log("Row matched filter") if ($VERBOSE > 3);
        $data[0] = $string if($1 eq '');
    }
    else
    {
        $data[0] = $string;
        $data[0] =~ s/\n$//;
    }

    # If a split pattern was specified, it overrides everything.  If the split
    # returns nothing (ie: a blank line), then throw an undef into the array so
    # that it has at least one element.
    if(defined $splitPattern)
    {
        @data = split(/$splitPattern/, $string);
        @data = (undef) if (@data == 0);
    }

    (@data);
}

#-------------------------------------------------------------------------------
# Function:     calcSleepTime
# Description:  Calculate when the cycle should next be run, and how long to 
#               sleep before that time arrives.  If the increment flag is passed,
#               then increment the lastTime value by the Interval * the increment
#               value.
# Input Parms:  Increment value
# Output Parms: Sleep time
#-------------------------------------------------------------------------------
sub calcSleepTime
{
    my $self = shift;
    my $incBy = shift;
    my $Interval = $self->{Interval};
    my $now = time;

    if($incBy > 0)
    {
        # Increment 'lastTime' accordingly.  If this is the first time it's being
        # set, then add a random factor to the lastTime, so that the objects 
        # don't all report in at the same time.
        if(! defined $self->{lastRunTime}) {
            $self->{lastRunTime} = $now + int((rand() - 0.5) * ($Interval * $incBy));
        } else  {  
            $self->{lastRunTime} += ($Interval * $incBy); 

            # If we get more than 3 Intervals behind, then start skipping to
            # catch up.
            while($self->{lastRunTime} < ($now - ($Interval * 3)))
            {
                $self->{lastRunTime} += $Interval;
            }
        }
    }

    # Calculate how many seconds until it needs to be run again.
    my $sleepTime = ($self->{lastRunTime} + $Interval) - $now;
    $sleepTime = 0 if ($sleepTime < 0);

    ($sleepTime);
}

# Put in a stub for handleSignal
sub handleSignal  { (0); }

1;
__END__

=head1 NAME

VBTK::Parser - Class for handling parsing and processing of incoming data

=head1 SYNOPSIS

Do not access this class directly.  It is called by the major data-gathering
classes (Wrapper, Snmp, Dbi, Http, Tcp, Smtp, Pop3, etc.) to handle the parsing
of data and client-side processing of VBObjects.

  # Associate a VBObject with a data-gathering object
  $vbObj = $obj->addVBObj(
    VBObjName           => ".myhost.cpu",
    TextHistoryLimit    => 50,
    ReverseText         => 1,
    Rules               => {
      '($data[1] > 3)'   => 'Warn',
      '($data[1] > 6)'   => 'Fail',
      '($data[22] <= 0)' => 'Warn' },
    StatusHistoryLimit  => 30,
    StatusChangeActions => undef,
    StatusUpgradeRules  => 'Upgrade to Failed if Warning occurs 2 times in 6 min',
    ExpireAfter         => '10 min',
    Description         => 'This object monitors CPU utilization on myhost',
    RrdColumns          => [ '$data[19]', '$data[20]', '$data[0]', '$data[11]' ],
  );

  # Add a graph group to the VBObject
  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    DataSourceList => undef,
    Labels         => 'user,system,runQueue,scanRate',
    Title          => "myhost cpu",
  );


=head1 DESCRIPTION

This perl library is used by the data-gathering classes ( 
L<VBTK::Wrapper|VBTK::Wrapper>, L<VBTK::Snmp|VBTK::Snmp>,
L<VBTK::Tcp|VBTK::Tcp>, L<VBTK::Http|VBTK::Http>, and L<VBTK::DBI|VBTK::DBI>)
to handle the definition and client-side processing of VBObjects.  Do
not attempt to call this class directly unless you are developing a new 
data-gathering class.  Instead, use the 'addVBObj' method of the 
corresponding data-gathering class.

See L<VBTK::ClientObject> for details on how to define graph groups
for these VB objects.

=head1 PUBLIC METHODS

The following methods are available to the common user:

=over 4

=item $vbObj = $obj->addVBObj (<parm1> => <val1>, <parm2> => <val2>, ...)

This initializes and returns a pointer to a 
L<VBTK::ClientObject|VBTK::ClientObject> object which will
be used by the corresponding data-gathering class to report data to the 
VBServer.  You should call this on the data-gathering class, not directly
on the VBTK::Parser class.  The allowed parameters are listed below.

Once the L<VBTK::ClientObject|VBTK::ClientObject> object has been defined, 
you will probably want to add graph groups to it so that graphs will be 
displayed in the VBServer web interface.  For details on how to define
graphs, see the 'L<addGraphGroup|VBTK::ClientObject/public methods>' method
description in the L<VBTK::ClientObject>.

=over 4

=item VBObjName

A string containing a name which uniquely identifies this data.  All 
corresponding data will appear on the VBServer web interface under this name.
Should be of the form 'a.b.c ...'.  The segments of the name make up the
hierarchy under which is it stored in the VBServer.  The web interface
grid can show three levels of name segments at a time.  Lower levels are 
rolled up into groups with the worst status being shown in the group.  This
allows the user to see the status of all objects at a glance, while still being
able to drill down through the hierarchy to view details of individual objects.

For example, if you have two objects named 'sfo.myhost.cpu.idle' and 
'sfo.myhost.cpu.user', they would both be grouped together as
'sfo.myhost.cpu' when looking at the top level of the web interface.  Clicking
on 'sfo.myhost.cpu', would then drill down and show you the 'idle' and 'user'
sub objects.  This can continue for 'n' levels.

Typically, a good naming scheme is: <location>.<host>.<service>[.optional].  If
you name all your objects this way, then each matrix will represent a location,
with the hosts as rows, and services as columns.  You'll have to experiment 
with naming your objects to get the layout you want.

Note that if you leave the first segment off and start your object name with '.',
then the VBServer will prepend it's 'ObjectPrefix' string to the object name.
This is very nice if you have a common script which you run on machines in 
different locations.  (Required)

    VBObjName => '.myhost.cpu.idle' 

=item Filter

A string containing a Perl expression involving the '$data', '@data', '@delta',
or '@rate' variables, which, if specified must evaluate to true or the row will
be ignored by the VBObject.  See the 'Rules' parm for more details on these
variables.  (Defaults to none.)

    # Ignore all rows unless $data[1] > 0
    Filter => '$data[1] > 0',

=item TextHistoryLimit

A number indicating how many lines of Ascii text to preserve from previously
reported data when transmitting a VBObject to the VBServer.  This is useful
when monitoring CPU time or tailling log files since it allows you to see the
most recent (n) number of lines of output together.  If not specified, then
only the newly-arrived data is shown.  (Defaults to undef).

    TextHistoryLimit => 50,

=item ReverseText

A boolean (0 or 1) indicating whether rows should be displayed in reverse
order.  This is typically used together with the 'TextHistoryLimit' option
so that as multiple rows accumulate, the most recent rows are shown at the
top of the web interface.  (Defaults to 0).

    ReverseText => 1,

=item Rules

A pointer to a hash containing pairs of perl expressions and statuses.  The
expressions can make use of '$data', '@data', '@delta', or '@rate'.  If the
expression evaluates to true, then the object will be set to the specified 
status.  If multiple rules are specified, they will all be evaluated, with
the object being set to the highest (worst) status.  For example:

    Rules => {
        # Set to Failed if the line of text contains 'error' or 'fail'
        '$data =~ /error|fail/i' => 'Failed',
        # Set to Warning if column 0 is > 120
        '$data[0] > 120'         => 'Warn',
        # Set to Warning if column 4 is > 55
        '$delta[4] > 55'         => 'Warn' },

The allowed variables are as follows.  (Defaults to none)

=over 4

=item $data

The full text of the line currently being parsed.

=item @data

An array containing the split data.  See the Split, Filter, and Pre-Processor
Parms of the corresponding data-gathering class for details on how the data
will be split.

=item @delta

An array containing the delta's calculated between the current @data and the
previous @data.  In multi-row output, the row number is used to match up 
multiple @data arrays with their previous @data values to calulate the deltas.
These deltas are most useful when monitoring the change in counters.  This is
very common in SNMP monitors.

=item @rate

An array containing the same data as in the @delta array, but divided by the
number of seconds since the last data retrieval.

=item $time

The current timestamp in the format YYYYMMDD-HH:MM:SS

=back

=item Requirements

A pointer to a hash containing perl expressions and statuses.  This is similar
to the 'Rules' parm, except that the specified status will only be assigned
to the VBObject if NO row in the current result set results in the expression
being true.  The same variables '$data', '@data', '@delta', and '@rate' are
available to use in the expressions.  For example:

    Requirements => {
        '$data =~ /Success/' => 'Warning' },

In this example, the requirement is that at least one row of the current 
result set passed from the data-gatherer class must have the word 'Success'
in it.  If no matching row is found, then the status will be set to 'Warning'.
(Defaults to none)

=item StatusHistoryLimit

A number indicating how many entries to maintain in the status history list
for the web interface.  (Defaults to 20) 

    StatusHistoryLimit => 30,

=item StatusChangeActions

A pointer to a hash containing pairs of statuses and action names.  When a 
object's status changes, this hash is checked for the new status and all
corresponding actions are triggered.  Since actions are defined in the
VBServer config, it's usually easier to use templates on the VBServer to
setup this list rather than do it on the client.  See the L<VBTK::Server>
for more details.  (Defaults to none)

    StatusChangeActions => {
        Failed   => 'emailme,pageme',
        Warning  => 'emailme' },

=item StatusUpgradeRules

A string or a pointer to an array of strings containing upgrade rule 
definitions.  Upgrade rules are used to upgrade the status if a lower
status occurs some number of times in a specified time period.  This 
is useful for ignoring sporadic errors, such as a ping packet getting
lost.  The string should have a format as shown below.  (Defaults to none)

    Upgrade to <New Status> if <Test Status> occurs <Count> times in <Time Expression>

For example:

    StatusUpgradeRules => 'Upgrade to Fail if Warn occurs 3 times in 10 min',

=item ExpireAfter

A string containing a time expression which indicates how long the VBServer
should wait from the last status report before setting the status to 'Expired'.
This is used to keep track of all monitoring processes and ensure that they
are running.  It's usually a good idea to set the expire time to 3 times the
interval or more.  Actions can be assigned to the 'Expired' status using the
'StatusChangeActions' parm.  (Defaults to none)

    ExpireAfter => '20 min',

=item Description

A string containing a description of this VBObject.  This description will
be shown on the web interface under the 'Info' tab.  This is a good place to
put instructions and notes about what to do if this object's status get's 
set to a non-Success status.  (Defaults to none)

=item BaselineDiffStatus

A string containing a status to set the VBObject to if there is a difference
between the reported text and the baseline text.  If this status is specified,
then a link will appear on the web interface which allows the user to select
a history entry and set it as the baseline.  All subsequent batches of data
sent to the VBServer will be compared against this baseline with 'diff' and if
any differences are found, the status will be set to the 'BaselineDiffStatus'.
This is useful for monitoring the output of commands which should not change,
such as machine hardware status (prtdiag) or disk volume layouts.  Another
use is in monitoring a web server where you want to be sure that not only 
can you connect, but also that the HTML is the same as when you last assigned
the baseline.  That way you'll know if your web site get's hacked, or someone
breaks the home page, etc.  (Defaults to none)

=item RrdColumns

A pointer to an array of strings containing perl expressions to be evaluated
with the resulting values being stored in an associated Rrd library.  If 
specified, then this will cause the VBServer to maintain an Rrd library for 
this object which is updated with every passed batch of data.  The perl 
expressions can only make use of the '$time', '$data', '@data', '@delta',
or '@rate' variables.  See the 'Rules' parm for more details on theses
variables.  (Defaults to none.)

    RrdColumns => [ '$data[0]', 'int($data[1]/100)' ],

Note that if you change the number of columns in this list, you will
have to rebuild the Rrd library.  This is done by deleting the existing 
library in the vbobj directory on the VBServer and then restarting the client
process.  In doing this, you will lose all historical data in the Rrd library.

=item RrdTimeCol

A string containing a perl expression to be used as the 'time' value in calls
to 'rrd update'.  If the 'RrdColumns' parms is set, then the
VBServer will maintain an Rrd database which can be used to generate graphs.
(Defaults to '$time', which is the current timestamp in a format of
YYYYMMDD-HH:MM:SS)

    RrdTimeCol => '$time',

Note that this parm is limited to using just the '$time', '$data', and '@data'
variables.  (Defaults to none)

=item RrdFilter

A string containing a Perl expression involving the '$data', '@data', '@delta',
or '@rate' variables, which, if specified must evaluate to true or the row will
not be added to the Rrd library. This is completely independent from the
'Filter' parm described above, so usually if you set one, you'll want to set 
the other the same.  Otherwise you wouldn't see the same data in the text 
and in the Rrd graphs.  See the 'Rules' parm above for more details on these
variables.  (Defaults to none.)

    # Ignore all rows unless $data[1] > 0
    Filter => '$data[1] > 0',

=item RrdMin

A number indicating the MIN value to be passed to the Rrd library.  Any values
passed to the Rrd library which are lower than this will be ignored.
(Defaults to 0)

    RrdMin => 0,

=item RrdMax

A number indicating the MAX value to be passed to the Rrd library.  Any values
passed to the Rrd library which are higher than this will be ignored.
(Defaults to none)

    RrdMax => 100,

=item RrdXFF

A number indicating the XFF to be used for the Rrd library.  See the Rrd man
page for details.  (Defaults to 0.5)

    RrdXFF => 0.5,

=item RrdCF

A string indicating which consolidation function should be used for the Rrd
library.  See the Rrd man page for details.  (Defaults to 'AVERAGE')

=item RrdDST

A string indicating which DST option to use for the Rrd library. See the 
Rrd man page for details.  (Defaults to 'GAUGE')

=back

=back

=head1 PRIVATE METHODS

The following private methods are used internally.  Do not try to use them
unless you know what you are doing.

To be documented...

=head1 SEE ALSO

=over 4

=item L<VBTK::Wrapper|VBTK::Wrapper>

=item L<VBTK::Snmp|VBTK::Snmp>

=item L<VBTK::Tcp|VBTK::Tcp>

=item L<VBTK::Http|VBTK::Http>

=item L<VBTK::DBI|VBTK::DBI>

=item L<VBTK::ClientObject|VBTK::ClientObject>

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

