#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Objects/ChangeActions.pm,v $
#            $Revision: 1.5 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to manage VBObject status
#                       change actions.
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
#       $Log: ChangeActions.pm,v $
#       Revision 1.5  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/03/04 16:49:10  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.3  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.2  2002/01/21 17:07:50  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::Objects::ChangeActions;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;

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

    # Setup a hash of default parameters
    my $defaultParms = {
        TestStatus    => $::REQUIRED,
        ActionList    => $::REQUIRED
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || return undef;

    my ($temp,$key);

    # Check the status text and map it
    foreach $key ('TestStatus')
    {
        $temp = &map_status($self->{$key});
        if ($temp eq undef)
        {
            &error("Invalid status '$self->{$key}' in StatusChangeActions");
            return undef;
        }
        $self->{$key} = $temp;
    }

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     validateActionNames
# Description:  Check to see if the passed action names are valid action objects.
# Input Parms:  None
# Output Parms: True | False
#-------------------------------------------------------------------------------
sub validateActionNames
{
    my $self = shift;
    my $ActionList    = $self->{ActionList};
    my $validatedFlag = $self->{validatedFlag};

    return 1 if ($validatedFlag);

    my ($actionName,$actionObj);

    # Split up the actionlist string
    my @actionNameList = split(/,/,$ActionList);

    # Check each action
    foreach $actionName (@actionNameList)
    {
        $actionObj = &VBTK::Actions::getAction($actionName);

        if ($actionObj eq undef)
        {
            &error("Invalid status change action '$actionName'");
            return undef;
        }
    }

    # If we made it this far, then all the action names are valid
    $self->{validatedFlag} = 1;

    (1);
}

#-------------------------------------------------------------------------------
# Function:     checkForActions
# Description:  Check to see if the passed status matches the test status on this
#               object and if so, then trigger it.
# Input Parms:  New status
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkForActions
{
    my $self = shift;
    my ($status,$name,$msgText) = @_;

    my $TestStatus = $self->{TestStatus};
    my $ActionList = $self->{ActionList};

    # If the status does not equal the test status then we're done.
    return 0 if ($TestStatus ne $status);

    my @actionList = split(/,/,$ActionList);
    my ($actionObj,$actionName);

    foreach $actionName (@actionList)
    {
        $actionObj = &VBTK::Actions::getAction($actionName);

        if($actionObj eq undef)
        {
            &error("Invalid action '$actionName' specified for object '$name'");
            next;
        }

        $actionObj->add_message($name,$status,$msgText);
    }
    (0);
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

    "If status changes to '$self->{TestStatus}' then execute '$self->{ActionList}'";
}

# Simple Get Methods
sub getTestStatus  { $_[0]->{TestStatus}; }
sub getActionList  { $_[0]->{ActionList}; }

1;
__END__

=head1 NAME

VBTK::Objects::ChangeActions - Internal module of VBTK

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This is an internal module of the VB tool kit used to handle status change
actions.  Do not try to access this package directly.

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
