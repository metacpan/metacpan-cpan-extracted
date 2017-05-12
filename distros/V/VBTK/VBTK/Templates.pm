#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Templates.pm,v $
#            $Revision: 1.5 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library to handle the definition of
#           vbserver object templates.
#
#          Description: This perl library contains methods to handle the
#           definition of vbserver object templates.  The
#           templates are used to define object attributes
#           such as actions related to status changes,
#           descriptions of the objects, etc.
#
#           Directions:
#
#           Invoked by: vbserver
#
#           Depends on: VBTK::Common.pm, Date::Manip.pm
#
#       Copyright (C) 1996-2002 Brent Henry
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
#       $Log: Templates.pm,v $
#       Revision 1.5  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.3  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#
#

package VBTK::Templates;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Objects::UpgradeRules;
use VBTK::Objects::ChangeActions;
use Date::Manip;
use CGI qw(:html3 :standard);

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

    # Store all passed input name pairs in the object
    $self->set(@_);

    # Setup a hash of rules to be returned
    my $defaultParms = {
        Pattern             => $::REQUIRED,
        StatusHistoryLimit  => undef,
        StatusChangeActions => undef,
        StatusUpgradeRules  => undef,
        ExpireAfter         => undef,
        Description         => undef
    };

    # Run the validation    
    $self->validateParms($defaultParms) || &fatal("Exiting");

    &log("Creating new object template '$self->{Pattern}'") if ($VERBOSE);

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

            $changeActionObj->validateActionNames || &fatal("Exiting");

            push(@{$self->{changeActionObjList}},$changeActionObj);
        }
    }

    # Check the 'ExpireAfter' key for a valid date string
    if(defined $self->{ExpireAfter})
    {
        $test = &DateCalc("today",$self->{ExpireAfter});
        &fatal("Invalid ExpireAfter string '$self->{ExpireAfter}' specified " .
            "for template '$self->{Pattern}'") if ($test eq '');
    }

    # Check the 'LimitHistoryTo' key for a valid date string
    if((defined $self->{LimitHistoryTo})&&($self->{LimitHistoryTo} !~ /^\d+$/))
    {
        $test = &DateCalc("today",$self->{LimitHistoryTo});
        &fatal("Invalid LimitHistoryTo string '$self->{LimitHistoryTo}' specified " .
            "for template '$self->{Pattern}'") if ($test eq '');
    }

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     getUpgradeRuleObjText
# Description:  Retrieve an array of text describing the upgrade rules
# Input Parms:  None
# Output Parms: Array of text describing the upgrade rules for this object
#-------------------------------------------------------------------------------
sub getUpgradeRuleObjText  
{ 
    my $self = shift;
    my $upgradeRuleObjList = $self->{upgradeRuleObjList};
    return () if (! defined $upgradeRuleObjList);

    map { $_->getRuleText } @{$upgradeRuleObjList};
}

#-------------------------------------------------------------------------------
# Function:     getChangeActionObjText
# Description:  Retrieve an array of text describing the change actions
# Input Parms:  None
# Output Parms: Array of text describing the change actions for this object
#-------------------------------------------------------------------------------
sub getChangeActionObjText
{ 
    my $self = shift;
    my $changeActionObjList = $self->{changeActionObjList};
    return () if (! defined $changeActionObjList);

    map { $_->getRuleText } @{$changeActionObjList};
}

# Simple Get Methods
sub getDescription         { $_[0]->{Description}; }
sub getPattern             { $_[0]->{Pattern}; }
sub getExpireAfter         { $_[0]->{ExpireAfter}; }
sub getUpgradeRuleObjList  { $_[0]->{upgradeRuleObjList}; }
sub getChangeActionObjList { $_[0]->{changeActionObjList}; }

1;
__END__

=head1 NAME

VBTK::Templates - Template definitions used by the L<VBTK::Server|VBTK::Server>
daemon

=head1 SYNOPSIS

Do not call this class directly.  Is is used by the L<VBTK::Server|VBTK::Server>
class.

  $t = new VBTK::Templates (
    Pattern             => '.*',
    StatusHistoryLimit  => 100,
    StatusChangeActions => {
        Failed  => 'pageMe,emailMe',
        Warning => 'emailMe' },
    StatusUpgradeRules  => [
        'Upgrade to Failed if Warning occurs 3 times in 10 min' ],
    ExpireAfter         => '30 min',
    Description         => 'Default Template'
 );

=head1 DESCRIPTION

The VBTK::Templates class is used by the L<VBTK::Server|VBTK::Server>
class to store templates used to set VBTK object values.  Do not call
this class directly. 

=head1 SEE ALSO

=over 4

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

