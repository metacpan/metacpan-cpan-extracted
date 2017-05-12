#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects/UpgradeRules.pm,v $
#            $Revision: 1.6 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to manage VBObject upgrade rules.
#
#       Copyright (C) 1996 - 2002  Brent Henry
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of version 2 of the GNU General Public
#       License as published by the Free Software Foundation available at:
#       http://http://www.gnu.org/copyleft/gpl.html
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
#       $Log: UpgradeRules.pm,v $
#       Revision 1.6  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.4  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.3  2002/02/19 19:12:36  bhenry
#       Changed to use unix time internally, to avoid DST problems
#
#       Revision 1.2  2002/01/21 17:07:50  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Objects::UpgradeRules;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use Date::Manip;

our $VERBOSE=$ENV{'VERBOSE'};

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
# Output Parms: Pointer to class
#-------------------------------------------------------------------------------
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->set(@_);

    if($self->{RuleText} =~ 
        /^Upgrade\s+to\s+(\w+)\s+if\s+(\w+)\s+occurs\s+(\d+)\s+times\s+in\s+(.*)$/i)
    {
        $self->{NewStatus}  = $1;
        $self->{TestStatus} = $2;
        $self->{Occurs}     = $3;
        $self->{TimeWindow} = $4;
        delete $self->{RuleText};
    }
    elsif($self->{RuleText} ne undef)
    {
        &error("Invalid upgrade rule - $self->{RuleText}");
        return undef;
    }

    # Setup a hash of default parameters
    my $defaultParms = {
        NewStatus     => $::REQUIRED,
        TestStatus    => $::REQUIRED,
        Occurs        => $::REQUIRED,
        TimeWindow    => $::REQUIRED
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || return undef;

    my ($temp,$key);

    # Check the status text and map them.
    foreach $key ('NewStatus','TestStatus')
    {
        $temp = &map_status($self->{$key});
        if ($temp eq undef)
        {
            &error("Invalid status '$self->{$key}' in UpgradeStatusRules");
            return undef;
        }
        $self->{$key} = $temp;
    }

    # Check the other values


    $self;
}

#-------------------------------------------------------------------------------
# Function:     checkForUpgrade
# Description:  Step through the passed history object list, checking to see if
#               the status should be upgraded
# Input Parms:  History Object List
# Output Parms: New status
#-------------------------------------------------------------------------------
sub checkForUpgrade
{
    my $self = shift;
    my ($status,$historyObjList) = @_;

    my $TestStatus = $self->{TestStatus};

    # If the status does not equal the test status then there's no point in testing
    # this rule.
    return $status if ($TestStatus ne $status);

    my $Occurs     = $self->{Occurs};
    my $TimeWindow = $self->{TimeWindow};
    my $NewStatus  = $self->{NewStatus};

    my $timeWindowSec = &deltaSec($TimeWindow) || return $status;
    my $startTimestampSec = time - $timeWindowSec;

    my $count = 0;

    &log("Looking for $Occurs $TestStatus" . "'s since $startTimestampSec")
        if ($VERBOSE > 2);

    my($itemStatus,$itemTimestamp,$itemRepeat,$itemRawStatus,$itemRepeatStart);
    my($itemRepeatStartSec,$itemTimestampSec,$ratio,$inRangeCount,$histObj);

    # Step through each history item later than $start_timestamp
    foreach $histObj (@{$historyObjList})
    {
        $itemStatus      = $histObj->getStatus;
        $itemTimestamp   = $histObj->getTimestamp;
        $itemRepeat      = $histObj->getRepeated;
        $itemRawStatus   = $histObj->getRawStatus;
        $itemRepeatStart = $histObj->getRepeatStart;

        # We're done if the history entry is earlier than the start of the
        # time window.
        last if ($itemTimestamp < $startTimestampSec);
        &log("History entry $itemTimestamp, $itemRawStatus repeated $itemRepeat times")
            if ($VERBOSE > 3);

        # If this history item matches the test status, then try to estimate how
        # many of the 'repeated' count fell within the time window specified in
        # the rule.
        if ($itemRawStatus eq $TestStatus)
        {
            if($itemRepeatStart > $startTimestampSec)
            {
                $count += $itemRepeat;
                &log("Adding $itemRepeat to $TestStatus count") if ($VERBOSE > 3);
            }
            else
            {
                $ratio = (($itemTimestamp - $startTimestampSec) /
                          ($itemTimestamp - $itemRepeatStart ));
                $inRangeCount = int(($itemRepeat * $ratio) + 1);
                $count += $inRangeCount;
                &log("Adding $inRangeCount of $itemRepeat to $TestStatus count")
                    if ($VERBOSE > 3);
            }
        }
    }

    # Just return if there are less than $occurs occurances of the current status
    return $status if($count < $Occurs);

    # If we made it this far, then it's time to upgrade the status
    &log("$TestStatus occurred $count times since $startTimestampSec, " .
         "Upgrading status to '$NewStatus'") if ($VERBOSE > 2);

    # Add a header message to the most recent history object
    $historyObjList->[0]->addHeaderMsg("Upgraded status to '$NewStatus' because " .
        "status was set to $TestStatus $Occurs times in $TimeWindow\n");

    &find_higher_status($status,$NewStatus);
}

#-------------------------------------------------------------------------------
# Function:     getRuleText
# Description:  Construct text to describe the rule
# Input Parms:  
# Output Parms: Rule text
#-------------------------------------------------------------------------------
sub getRuleText
{
    my $self = shift;

    "Upgrade to '$self->{NewStatus}' if '$self->{TestStatus}' occurs " .
    "$self->{Occurs} times in $self->{TimeWindow}";
}

# Simple Get Methods
sub getTestStatus  { $_[0]->{TestStatus}; }
sub getNewStatus   { $_[0]->{NewStatus}; }
sub getOccurs      { $_[0]->{Occurs}; }
sub getTimeWindow  { $_[0]->{TimeWindow}; }

1;
__END__

=head1 NAME

VBTK::Objects::UpgradeRules - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle the definition
and handling of status upgrade rules.  Do not try to access this package 
directly.

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

=item L<VBTK::Objects|VBTK::Objects>

=item L<VBTK::Server|VBTK::Server>

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
