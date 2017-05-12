#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/ClientObject.pm,v $
#            $Revision: 1.11 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to define the client side
#                       of a VB object.
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
#       $Log: ClientObject.pm,v $
#       Revision 1.11  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.10  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.9  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.8  2002/02/19 19:05:33  bhenry
#       Changed to pass baseline with first status submission if not already set
#
#       Revision 1.7  2002/02/13 07:41:35  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#

package VBTK::ClientObject;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Parser;
use VBTK::Client;
use Date::Manip;
use VBTK::Objects::UpgradeRules;
use VBTK::Objects::ChangeActions;
use VBTK::Objects::Graph;
use VBTK::Objects::Rrd;
use FileHandle;
use File::Basename;
use Algorithm::Diff qw(diff);
use Storable qw(freeze thaw);

our $VERBOSE = $ENV{VERBOSE};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->set(@_);

    # Setup a hash of rules to be returned
    my $defaultParms = {
        VBClientObj         => $::REQUIRED,
        Interval            => $::REQUIRED,
        VBObjName           => $::REQUIRED,
        Filter              => undef,
        TextHistoryLimit    => undef,
        ReverseText         => undef,
        Rules               => { },
        Requirements        => { },
        StatusHistoryLimit  => 20,
        StatusChangeActions => undef,
        StatusUpgradeRules  => undef,
        ExpireAfter         => undef,
        Description         => undef,
        BaselineDiffStatus  => undef,
        LogFile             => undef,
        RrdTimeCol          => '$time',
        RrdColumns          => undef,
        RrdFilter           => undef,
        RrdMin              => undef,
        RrdMax              => undef,
        RrdXFF              => undef,
        RrdCF               => undef,
        RrdDST              => undef,
    };

    # Run the validation    
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Retrieve the VBServer object name
    my $VBObjName = $self->{VBObjName};

    # Check for proper usage
    if (($self->{ReverseText}||$self->{TextHistoryLimit}) && 
        ($self->{BaselineDiffStatus} ne ''))
    {
        &fatal("Can't use 'BaselineDiffStatus' option with the 'TextHistoryLimit' or " .
               "'ReverseText' options in the same rule - $VBObjName");
    }   

    if(($self->{RrdLogRecovery})&&(! defined $self->{RrdTimeCol}))
    {
        &fatal("VBTK::ClientObject::new: Can't use 'RrdLogRecovery' without ".
               "specifying 'RrdTimeCol'.");
    }

    # Check for required name/value pairs
    &log("Creating client object for $VBObjName") if ($VERBOSE);

    # Initialize member values
    $self->{status}              = $::SUCCESS;
    $self->{reqFound}            = {};
    $self->{graphDataQueue}      = [];
    $self->{graphGroupList}      = {};

    my ($ruleReqPtr,$clause,$cmd,$newStatus,$inputStatus,$dummy);
    my (@data,$data,@delta);

    # Now step through each rule and requirement
    foreach $ruleReqPtr ($self->{Rules},$self->{Requirements})
    {
        foreach $clause (keys %{$ruleReqPtr})
        {
            $inputStatus = $ruleReqPtr->{$clause};

            &log("Checking '$clause' => '$inputStatus'") if ($VERBOSE > 1);

            # Mark the DeltaUsed flag if the clause contains the word 'delta'
            $self->{DeltaUsed} = 1 if ($clause =~ /delta/);

            # Make sure the status specified is a valid status
            $newStatus = $ruleReqPtr->{$clause} = map_status($inputStatus);
            &fatal("VBTK::ClientObject::new: Invalid status '$inputStatus' specified")
                if (($newStatus eq '')&&($inputStatus !~ /^Ignore/i));

            # Generate a dummy eval command to test the clause
            $cmd = '$dummy = 1 if ' . $clause;
            eval($cmd);
            fatal("VBTK::ClientObject::new: Error executing '$cmd': '$@'") if($@ ne '');
        }
    }

    my ($upgradeStr,$upgradeRuleObj,$status,$action,$changeActionObj,$test);

    # Check the upgrade rules
    if(defined $self->{StatusUpgradeRules})
    {
        # If the upgrade rule is just a string, then make it an array
        $self->{StatusUpgradeRules} = [ $self->{StatusUpgradeRules} ]
            unless(ref($self->{StatusUpgradeRules}));

        # Step through each status upgrade rule
        foreach $upgradeStr (@{$self->{StatusUpgradeRules}})
        {
            $upgradeRuleObj = new VBTK::Objects::UpgradeRules(
                RuleText => $upgradeStr);

            &fatal("Exiting") if (! defined $upgradeRuleObj);

            # Allocate an array if there isn't already one.
            $self->{upgradeRuleObjList} = [] 
                if (! defined $self->{upgradeRuleObjList});

            push(@{$self->{upgradeRuleObjList}},$upgradeRuleObj);
        }
    }

    # Check the status change actions
    if(defined $self->{StatusChangeActions})
    {
        &fatal("StatusChangeActions parm must be a hash")
            unless (ref($self->{StatusChangeActions}) eq 'HASH');

        # Step through each status change action
        while(($status,$action) = each %{$self->{StatusChangeActions}})
        {
            $changeActionObj = new VBTK::Objects::ChangeActions(
                TestStatus => $status,
                ActionList => $action);

            &fatal("Exiting") if (! defined $changeActionObj);

            # Allocate an array if there isn't already one.
            $self->{changeActionObjList} = [] 
                if (! defined $self->{changeActionObjList});

            push(@{$self->{changeActionObjList}},$changeActionObj);
        }
    }

    # Check the 'ExpireAfter' key for a valid date string
    if(defined $self->{ExpireAfter})
    {
        $test = &DateCalc("today",$self->{ExpireAfter});
        &fatal("Invalid ExpireAfter string '$self->{ExpireAfter}' specified " .
            "for object '$self->{VBObjName}'") if ($test eq '');
    }

    # Check the 'LimitHistoryTo' key for a valid date string
    if((defined $self->{LimitHistoryTo})&&($self->{LimitHistoryTo} !~ /^\d+$/))
    {
        $test = &DateCalc("today",$self->{LimitHistoryTo});
        &fatal("Invalid LimitHistoryTo string '$self->{LimitHistoryTo}' specified " .
            "for object '$self->{VBObjName}'") if ($test eq '');
    }

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     addGraphGroup
# Description:  Add a graph grouping to this object
# Input Parms:  Parms
# Output Parms: None
#-------------------------------------------------------------------------------
sub addGraphGroup
{
    my $self = shift;
    my $VBObjName      = $self->{VBObjName};
    my $graphGroupList = $self->{graphGroupList};
    my %args = (@_);

    # Setup some default parms
    my $defaultParms = {
         GroupNumber    => 1,
         DataSourceList => undef,
         Labels         => $::REQUIRED,
         LineWidth      => undef,
         Colors         => undef,
         VLabel         => undef,
         Title          => undef,
         TimeWindowList => '1day,1week,1month,1year',
         CF             => undef,
         XSize          => undef,
         YSize          => undef,
         Target         => {
             XSize => 800,
             YSize => 300 }
    };

    # Run a validation, using the defaults
    &validateParms(\%args,$defaultParms) || fatal("Exiting");

    my @timeWindowList = split(/,/,$args{TimeWindowList});
    delete $args{TimeWindowList};

    my $groupNumber = $args{GroupNumber};
    delete $args{GroupNumber};

    my ($graphObj,$graphGroup,@retList);

    # Iterate through each time window entry, creating a graph object
    foreach my $timeWindow (@timeWindowList)
    {
        $graphObj = new VBTK::Objects::Graph ( 
            TimeWindow => $timeWindow,
            %args );

        push(@retList,$graphObj) if (defined $graphObj);
    }

    # Retrieve the array for this graph group
    $graphGroup = $graphGroupList->{$groupNumber};

    # If the array doesn't exist, then allocate one
    $graphGroup = $graphGroupList->{$groupNumber} = []
        if (! defined $graphGroup);

    # Now add the current graph definition into the specified graph group array   
    push(@{$graphGroup},@retList);

    (@retList);
}

#-------------------------------------------------------------------------------
# Function:     processText
# Description:  Process one row of data from the parser
# Input Parms:  
# Output Parms: Return value
#-------------------------------------------------------------------------------
sub processText
{
    my $self = shift;
    my $VBObjName = $self->{VBObjName};

    my ($time,$data,$dataPtr,$deltaPtr,$ratePtr,$vbMessage) = @_;

    # Setup variables to be used in the eval clause below
    my @data = @{$dataPtr};
    my @delta = @{$deltaPtr};
    my @rate = @{$ratePtr};

    my $rulePtr     = $self->{Rules};
    my $reqPtr      = $self->{Requirements};
    my $reqfoundPtr = $self->{reqFound};
    my $Filter      = $self->{Filter};
    my $rowStatus   = $::SUCCESS;
    my $tmpMessage  = undef;
    my $reqfound    = 0;

    my ($ruleReqPtr,$clause,$flag,$cmd,$newStatus,$msg);

    # Test to see if line should have an object-specific grep applied.
    if($Filter ne '')
    {
        $flag = 1;
        $cmd = '$flag = 0 if ' . $Filter;
        eval($cmd);
        return 1 if $flag;
    }

    # Step through each clause for all rules and requirements
    foreach $ruleReqPtr ($rulePtr,$reqPtr)
    {
        foreach $clause (keys %{$ruleReqPtr})
        {
            $flag = 0;

            &log("Checking clause '$clause'") if ($VERBOSE > 2);

            # Generate the eval command to test the clause
            $cmd = '$flag = 1 if ' . $clause;
            eval($cmd);
            fatal("Error executing '$clause': '$@'") if($@ ne '');

            # If clause tests true and this is a rule, then change to the status
            # specified by the rule
            if(($flag) and ($ruleReqPtr eq $rulePtr))
            {
                $newStatus = $rulePtr->{$clause};
                my $msg = "Setting '$VBObjName' to '$newStatus' because $clause";
                &log($msg);
                $rowStatus = find_higher_status($rowStatus,$newStatus);

                if   ($newStatus eq $::FAILED)
                    { $self->{statusLine} .= red("$msg\n"); }
                elsif($newStatus eq $::WARNING)
                    { $self->{statusLine} .= yellow("$msg\n"); }
                else
                    { $self->{statusLine} .= "$msg\n"; }
            }
            # If clause tests true and this is a requirements, then just mark the
            # requirement as being fulfilled.
            elsif(($flag) and ($ruleReqPtr eq $reqPtr))
            {
                $reqfoundPtr->{$clause} = 1;
                $reqfound = 1;
            }
        }
    }

    # Color the message using the HTML font tag based on the status
    if   ($rowStatus eq $::FAILED)
          { $vbMessage = red($vbMessage); }
    elsif($rowStatus eq $::WARNING)
          { $vbMessage = yellow($vbMessage); }
    # If a requirement was fulfilled, then mark the line green
    elsif($reqfound)
          { $vbMessage = green($vbMessage); }

    # Add the new row at the top if the 'ReverseText' parm was set
    # otherwise, add it to the bottom.
    if   ($self->{ReverseText})
          { $self->{Message} = $vbMessage . $self->{Message}; }
    else
          { $self->{Message} .= $vbMessage; }

    # Most Severe status always takes precedence
    $self->{status} = find_higher_status($self->{status},$rowStatus);

    (0);
}

#-------------------------------------------------------------------------------
# Function:     processGraphData
# Description:  Read through the passed logfile string and process data to be
#               passed to the vbServer process for graphing.
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub processGraphData
{
    my $self = shift;
    my ($time,$data,$dataPtr,$deltaPtr,$ratePtr) = @_;

    # Setup variables to be used in the eval clause below
    my @data = @{$dataPtr};
    my @delta = @{$deltaPtr};
    my @rate = @{$ratePtr};

    my $VBObjName            = $self->{VBObjName};
    my $RrdTimeCol           = $self->{RrdTimeCol};
    my $RrdColumns           = $self->{RrdColumns};
    my $RrdFilter            = $self->{RrdFilter};
    my $graphDataQueue       = $self->{graphDataQueue};
    my $lastGraphDbTimestamp = $self->{lastGraphDbTimestamp};

    # Just return if there's nothing in @data, or if RrdColumns or RrdTimeCol
    # isn't setup right.
    return 0 if (! defined $data[0] || ! defined $RrdTimeCol || 
                 ! defined $RrdColumns || @{$RrdColumns} < 1);

    my ($expr,$val,@exprVals,@vals,$timeValUnix,$timeValStr,$newEntry);
    my ($flag,$cmd);

    &log("Processing graph data for '$VBObjName'") if ($VERBOSE > 3);

    # Test to see if line should have an object-specific grep applied.
    if($RrdFilter ne '')
    {
        $flag = 1;
        $cmd = '$flag = 0 if ' . $RrdFilter;
        eval($cmd);
        return 1 if $flag;
    }


    # Step through each of the column expressions, evaluating them and storing
    # their resulting values.
    foreach $expr ($RrdTimeCol,@{$RrdColumns})
    {
        if (! defined $expr)
        {
            &error("Empty expression passed in RrdColumns for '$VBObjName', no update will be made");
            return 0;
        }
        $cmd = "\$val = $expr";
        eval ($cmd);
        fatal("VBTK::ClientObject::processGraphData: Error evaluating '$expr': '$@'") 
            if($@ ne '');
        $val = 'U' if (! defined $val);
        push(@exprVals, $val);
    }

    ($timeValStr,@vals) = @exprVals;

    # Make sure the time string is valid
    if($timeValStr =~ /[^\d:\s-]/)
    {
        &log("Skipping log entry, can't understand timestamp '$timeValStr'")
            if ($VERBOSE > 1);
        return 0;
    }

    # Make sure the values are all numeric!
    if(grep(/[^\d\.]/ && ! /^U$/,@vals))
    {
        &log("Skipping log entry, data is not numeric: @vals") if ($VERBOSE > 1);
        return 0;
    }

    # Translate the timeValStr to unix time
    $timeValUnix = &unixdate($timeValStr);

    if ($timeValUnix <= $lastGraphDbTimestamp)
    {
        &log("Skipping log entry, timestamp '$timeValUnix' is <= last graph " .
             "db timestamp of '$lastGraphDbTimestamp'") if ($VERBOSE > 3);
        return 0;
    }

    # Store the last timestamp for later use.
    $self->{lastGraphDbTimestamp} = $timeValUnix;

    # Store the values into a queue for later processing
    $newEntry = join(':', $timeValUnix,@vals);
    &log("Adding '$newEntry' to graphDataQueue") if ($VERBOSE > 3);
    push(@{$graphDataQueue}, $newEntry);

    (0);
}

#-------------------------------------------------------------------------------
# Function:     getEarliestLastGraphDbTimestamp
# Description:  Request the last graphDb timestamp for this object from the VBServer.
# Input Parms:  None
# Output Parms: Earliest Last Graph Db Timestamp
#-------------------------------------------------------------------------------
sub getLastGraphDbTimestamp
{
    my $self = shift;
    my $time = shift;
    my $VBObjName        = $self->{VBObjName};
    my $VBClientObj      = $self->{VBClientObj};
    my $RrdLogRecovery = $self->{RrdLogRecovery};

    my ($lastTimestamp);

    if($RrdLogRecovery)
    {
        # Get the most recent timestamp from the Rrd database on the main vbserver
        &log("Requesting last GraphDB timestamp for '$VBObjName' from VB Server")
            if ($VERBOSE > 1);
        $lastTimestamp = $VBClientObj->getGraphDbLastTimestamp($VBObjName);

        # If there's an error, then just return undef
        if(! defined $lastTimestamp)
        {
            &error("Can't retrieve lastTimestamp for '$VBObjName'");
        }
        else
        {
            &log("Last timestamp was $lastTimestamp") if ($VERBOSE > 2);
        }
    }

    # If we can't determine a valid last timestamp, then just set it to one
    # second before the current loop's timestamp. 
    $lastTimestamp = ($time - 1) if (! defined $lastTimestamp);

    # Store the last timestamp value in the object
    $self->{lastGraphDbTimestamp} = $lastTimestamp;

    ($lastTimestamp);
}

#-------------------------------------------------------------------------------
# Function:     sendStatus
# Description:  Send the status and messages of this VB object to the VB server.
#               Override with the passed master status and message if specified.
# Input Parms:  Master status, Master message
# Output Parms: None
#-------------------------------------------------------------------------------
sub sendStatus
{
    my $self = shift;
    my ($masterStatus,$masterMsg,$header) = @_;

    my $VBClientObj = $self->{VBClientObj};
    my $baseline    = $self->{baseline};

    # Skip if the VBClient object wasn't initialized
    return 1 if ($VBClientObj eq '');

    my ($sel,$vbPtr,$VBObjName,$vbmsg,$status,$statusLine);
    my ($newStatus,@messageLines,$message,$numRows,$graphStruct,$retval,@oneTimeParms);

    $status    = $self->{status};
    $VBObjName = $self->{VBObjName};

    $status = find_higher_status($status,$masterStatus)
        if ($masterStatus ne '');

    if ($masterStatus eq $::RUNNING)
    {
        $status = $masterStatus;
    }
    else
    {
        # Check for requirement rules
        $newStatus = $self->checkRequirements;
        $status = &find_higher_status($newStatus,$status);

        # Check the baseline if specified
        if($self->checkBaseline)
        {
            $newStatus = $self->{BaselineDiffStatus};
            $newStatus = $::FAILED if ($newStatus eq '');
            $status = &find_higher_status($newStatus,$status);
        }
    }

    # Check the statusLine variable, and add a carriage return if 
    # it's not empty
    $statusLine  = $self->{statusLine};
    $statusLine .= "\n" if ($statusLine ne '');
    $masterMsg  .= "\n" if ($masterMsg ne '');

    # If the TextHistoryLimit option is specified, then split the message
    # apart and then re-assemble just the first $TextHistoryLimit lines.
    if($self->{TextHistoryLimit})
    {
        @messageLines = split(/\n/,$self->{Message});
        $numRows = @messageLines;
        $numRows = $self->{TextHistoryLimit} if ($self->{TextHistoryLimit} < $numRows);
        $self->{Message} = join("\n",@messageLines[0..$numRows]);
    }

    $message = $self->{Message};
    $message = "No new data reported\n" if($message eq '');

    # If this the first time we're submitting a status to the VB server, then
    # pass along these additional values.
    @oneTimeParms = ();
    $graphStruct  = undef;

    # Setup values to be passed only the first time we connect
    if ($self->{sendCount} < 1)
    {
        @oneTimeParms = (
            StatusHistoryLimit  => $self->{StatusHistoryLimit},
            ChangeActionObjList => $self->{changeActionObjList},
            UpgradeRuleObjList  => $self->{upgradeRuleObjList},
            ExpireAfter         => $self->{ExpireAfter},
            Description         => $self->{Description},
            GraphGroupList      => $self->{graphGroupList},
            BaselineDiffStatus  => $self->{BaselineDiffStatus},
            LogFile             => $self->{LogFile},
            Interval            => $self->{Interval},
            RunningFrom         => $::HOST,
            ScriptName          => &basename($0)
        );

        $graphStruct = {
            Interval       => $self->{Interval},
            Min            => $self->{RrdMin},
            Max            => $self->{RrdMax},
            XFF            => $self->{RrdXFF},
            CF             => $self->{RrdCF},
            DST            => $self->{RrdDST},
            DataQueue      => $self->{graphDataQueue}
        };
    }
    # Otherwise, if there's data to be passed, then just include the dataqueue
    elsif(@{$self->{graphDataQueue}} > 0)
    {
        $graphStruct = {
            DataQueue      => $self->{graphDataQueue}
        };
    }

    # Build the final obj structure to be passed to the VB server.
    my $objStruct = {
        Name        => $VBObjName,
        Status      => $status,
        Text        => $message,
        HeaderMsg   => $masterMsg . $statusLine . $header,
        FooterMsg   => undef,
        GraphStruct => $graphStruct,
        @oneTimeParms
    };
    
    # If the 'setBaselineFlag' was set, then pass it along to the server and
    # then reset it.
    if($self->{setBaselineFlag})
    {
        $objStruct->{SetBaselineFlag} = 1;
        $self->{setBaselineFlag} = undef;
    }

    &log("Setting status of '$VBObjName' to '$status'") if ($VERBOSE > 1); 
    $retval = $VBClientObj->setStatus(objStruct => &freeze($objStruct));

    # Only clear out the graph data queue if the transmit was successful.
    if($retval eq 0)
    {
        $self->{graphDataQueue} = [];
        $self->{sendCount}++;
    }

    # Reset status to Success and clear out messages for the next round
    $self->{status} = $::SUCCESS;
    $self->{statusLine} = '';

    # Clear out the 'Requirements Found' indicator for the next round.
    $self->{reqFound} = {};

    # Clear out the Message unless the TextHistoryLimit option is specified
    $self->{Message} = '' unless ($self->{TextHistoryLimit});

    return undef if ($retval ne 0);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     checkRequirements
# Description:  Check to make sure all of the requirements rules were satisfied.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkRequirements
{
    my $self = shift;
    my $status = $::SUCCESS;

    my $reqPtr      = $self->{Requirements};
    my $reqFoundPtr = $self->{reqFound};
    my ($newStatus,$row_status,$msg,$clause);

    # Just return if there aren't any requirements
    return $status if ($reqPtr eq '');

    foreach $clause (keys %{$reqPtr})
    {
        unless($reqFoundPtr->{$clause})
        {
            $newStatus = $reqPtr->{$clause};
            $msg = "Required clause '$clause' not true, setting to '$newStatus'";
            &log($msg);
            if($newStatus eq $::FAILED)     { $msg = red($msg); }
            elsif($newStatus eq $::WARNING) { $msg = yellow($msg); }
            $self->{statusLine} .= "$msg\n";
            $status = find_higher_status($status,$newStatus);
        }
    }
    ($status);
}

#-------------------------------------------------------------------------------
# Function:     checkBaseline
# Description:  Compare the output from the command to a pre-specified baseline
#               file.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkBaseline
{
    my $self = shift;

    return 0 if (! defined $self->{BaselineDiffStatus});

    my $VBClientObj = $self->{VBClientObj};
    my $VBObjName   = $self->{VBObjName};
    my $baselineText = $VBClientObj->getBaseline($VBObjName);
    my $messageText = $self->{Message};

    # If we don't get anything back from the baseline request, then try to set
    # it once.  If we can't set it, or if we've already tried this before, then
    # just report the error.
    if (! $baselineText)
    {
        if(! $self->{baselineSetOnce})
        {
            &log("Marking flag to set baseline for $VBObjName");
            $self->{setBaselineFlag} = 1;
            $self->{baselineSetOnce} = 1;
            return 0;
        }

        $self->{statusLine} .= "Error: Cannot compare baseline because it cannot " .
            "be retrieved or has not been set\n";
        return -1;
    }
    
    my ($chunk,$line,$diffText,$sign,$lineno,$text);

    my @messageLines = split(/\n/,$messageText);
    my @baselineLines = split(/\n/,$baselineText);

    my $diffList = diff(\@baselineLines, \@messageLines);

    foreach $chunk (@$diffList) 
    {
        foreach $line (@$chunk) 
        {
            ($sign, $lineno, $text) = @$line;
            $diffText .= sprintf "%4d$sign %s\n", $lineno+1, $text;
        }
        $diffText .= "--------\n";
    }

    if(defined $diffText)
    {
        $self->{statusLine} .= "Error: Differences found with baseline\n$diffText";
        return -1;
    }

    (0);
}

1;
__END__

=head1 NAME

VBTK::ClientObject - Class for handling client-side processing of VBObjects.

=head1 SYNOPSIS

  # Add a graph group to the VBObject
  $vbObj->addGraphGroup (
    GroupNumber    => 1,
    DataSourceList => undef,
    Labels         => 'user,system,runQueue,scanRate',
    Title          => "myhost cpu",
  );


=head1 DESCRIPTION

This perl library is used by the L<VBTK::Parser|VBTK::Parser> class to 
handle the client-side processing of VB Objects.  Do not attempt to call
this class directly.  The one exception is the 'addGraphGroup' method
which you will commonly call to define graph groups for your VB objects.

=head1 PUBLIC METHODS

The following methods are supported

=over 4

=item $vbObj->addGraphGroup(<parm1> => <val1>, <parm2> => <val2>, ...)

The addGraphGroup method is used to add graph group definitions to a VBObject.
The graphs will be shown in the web interface under the 'GraphsX' tabs where
X is the group number.  Graphs are generated using the data stored in the
Rrd library, so an Rrd library must have been defined.  See the 
'L<Rrd...|VBTK::Parser/item_rrdcolumns>' parms
in L<VBTK::Parser> for more details.  The following parms are allowed:

=over 4

=item GroupNumber

A number indicating which graph group to add graphs to.  The group number 
determines which 'GraphsX' tab the graphs will be displayed undef.
(Defaults to 1).

    GroupNumber => 1,

=item Labels

A string containing a comma-separated list of labels to display for each data
source to be graphed.  These must correspond one-to-one with the 
'DataSourceList'.  (Required)

    Labels => 'cpu-time,run-queue',    

=item DataSourceList

A string containing a comma-separated list of data source specifications
of the form 'vbobject-name:rrdlib-column'.  These should correspond one-to-one
with the list of labels specified with the 'Labels' parm.  The data source 
list vbobject-name defaults to the current VBObject if not specified.  The
'rrd-lib-column' defaults to it's position in the list if not specified.  So,
for example, if there are two labels in the 'Labels' list, and the object is
named '.myhost.cpu', then the DataSource list would default to:

    DataSourceList => '.myhost.cpu:0,.myhost.cpu:1',

Note that you can specify any VBObject name and Rrd lib column, so you can 
create graphs made up from any Rrd library hosted on the VBServer.  So for
example, if you wanted to graph just the cpu-time but from two hosts
'myhost1' and 'myhost2', and you knew that cpu-time was stored in column
0 of the rrdlib for those objects, then you would use the following setting:

    Labels         => 'cpu myhost1','cpu myhost2',
    DataSourceList => '.myhost1.cpu:0,.myhost2.cpu:0',

=item LineWidth

A number indicating the linewidth to be passed to the Rrd lib tool when
generating the graph.  (Defaults to 1)

    LineWidth => 2,

=item Colors

A string containing a comma-separated list of color specifications to be used
when drawing the lines on the graph.  These should correspond one-to-one with 
the list of 'Labels'.  (Defaults to a list of standard colors)

    Colors => '#00FF00,#FF0000',

=item VLabel

A string containing a label to be placed on the vertical axis of the graph.
(Defaults to none)

    VLabel => 'myhost1 cpu utilization',

=item Title

A string containing a title to be displayed at the top of the graph.  If the 
graph is less than 100 pixels high, then this title will be moved down into 
the legend to make better use of space.  (Defaults to none)

    Title => 'CPU utilization for myhost1',

=item TimeWindowList

A string containing a comma-separated list of time expressions.  For each
time expression, a graph will be displayed which shows the data in the Rrd
library over the specified time window.  Note that n time window expressions
will result in n separate graphs being displayed, one below the other.
(Defaults to '1day,1week,1month,1year')

    TimeWindowList => '1day,1week',

=item CF

A string containing the CF specifier to be passed to the Rrd tool when
generating the graph.  See the Rrd man page for more details.
(Defaults to 'AVERAGE').

    CF => 'MAX',

=item XSize

A number indicating the X-axis size of the graph to be generated.  
(Defaults to 600)

    XSize => 600,

=item YSize

A number indicating the Y-axis size of the graph to be generated.
(Defaults to 60)

    YSize => 60,

=item Target

A pointer to a hash containing name value pairs which describe what to do when
a user clicks on the graph itself.  The 'target' graph will inherit it's values
from the initial graph, with the specified overrides being applied.  The
following overrides are allowed:

=over 4

=item XSize, YSize

If XSize and YSize overrides are specified, then clicking on the graph will
cause an identical graph to be displayed, but sized with the new sizes.  This
is useful for zooming in on a graph.

    Target => {
        XSize => 800,
        YSize => 600 },

=item VBObjName, GroupNumber

If the VBObjName and/or GroupNumber overrides are specified, then clicking on 
the graph will jump to the specified VBObject and GroupNumber.  This is 
usefull for jumping to a different arrangement of graphs, perhaps which show
more detail or show data grouped in a different way.

    Target => {
        VBObjName   => '.myhost2.cpu',
        GroupNumber => 2 },

=back

If no Target is specified, then it will default to:

        Target => { XSize => 800, YSize => 300 }

=back

=back

=head1 PRIVATE METHODS

Haven't gotten around to documenting these yet, but you shouldn't be messing
with them anyway.

=head1 SEE ALSO

VBTK::Wrapper::
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
