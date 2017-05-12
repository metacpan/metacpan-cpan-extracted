#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Actions.pm,v $
#            $Revision: 1.7 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to define and trigger actions
#                       based on pmserver object statuses
#
#          Description: This perl library is used by the pmserver process to
#                       define and trigger actions based on the status of objects
#           defined on the pmserver process.
#
#           Directions:
#
#           Invoked by: pmserver
#
#           Depends on: VBTK::Common.pm, Date::Manip
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
#       $Log: Actions.pm,v $
#       Revision 1.7  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/03/04 16:49:08  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.5  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.4  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.3  2002/02/19 19:01:19  bhenry
#       Rewrote Actions to make use of inheritance
#

package VBTK::Actions;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use Date::Manip;
use POSIX qw(waitpid WNOHANG);

our $VERSION = '0.01';

our %PENDING_QUEUE;
our @LOG_ACTION_LIST;
our %ACTION_LIST;
our $VERBOSE=$ENV{VERBOSE};
our $LAST_HANDLER_PID;

#-------------------------------------------------------------------------------
# Function:     new
# Description:  Object constructor.  Allocates memory for all class members
# Input Parms:  Configuration filename
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
            Name          => $::REQUIRED,
            Execute       => undef,
            SendUrl       => 1,
            LimitToEvery  => '2 min',
            SubActionList => undef,
            LogActionFlag => undef,
        };

        # Validate the passed parms against the default parms.
        $self->validateParms($defaultParms) || &fatal("Exiting");
    }

    # Convert the SubActionList to an array if it's not already one.
    my $SubActionList = $self->{SubActionList};
    $self->{SubActionList} = [ split(/,/,$SubActionList) ]
        unless (ref($SubActionList));

    # Create a per-action queue of pending messages
    $self->{messages} = [];
    
    # Calculate 'LimitToEvery' in seconds
    $self->{limitToEverySec} = &deltaSec($self->{LimitToEvery}) ||
        &fatal("Invalid 'LimitToEvery' setting in action '$self->{Name}'");

    &log("Creating new action '$self->{Name}'") if ($VERBOSE);

    # Store myself in the global hash
    $ACTION_LIST{$self->{Name}} = $self;

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Run the action.  Override this class when subclassing to create
#               a different action.  Note that the triggerAll method has already
#               forked a separate process at this point, so there's no need to
#               worry about doing a fork here to avoid blocking the engine if the
#               action takes a while to run.  Also, this method must return a
#               1 or the action won't be cleared from the queue.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $message = shift;
    my $Execute = $self->{Execute};
    
    # If nothing was passed in for the execute, then just return.
    return 1 unless ($Execute);
    
    &log("Executing '$Execute'");
    unless(open(EXEC, "| $Execute")) 
    { 
        &error("Cannot exec '$Execute'"); 
        return 0; 
    };
    print EXEC $message;
    close(EXEC);

    # An error code can appear in either the lower or the higher byte of $?.
    # By or-ing the lower byte with the upper byte, we get an accurate error code.
    my $ret_code = ($? & 0xFF) | ($? >> 8);

    &log("Command exited with return code '$ret_code'.") if ($ret_code);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     getAction
# Description:  Retrieve the action object associated with the specified name
# Input Parms:  Action name
# Output Parms: Object
#-------------------------------------------------------------------------------
sub getAction
{
    my $name = shift;

    $ACTION_LIST{$name};
}

#-------------------------------------------------------------------------------
# Function:     add_message
# Description:  Add a message to an action to be executed at a later time
# Input Parms:  Object name, status, object text
# Output Parms: None
#-------------------------------------------------------------------------------
sub add_message
{
    my $self = shift;

    my ($fullName,$status,$url) = @_;
    my $SendUrl       = $self->{SendUrl};
    my $Execute       = $self->{Execute};
    my $SubActionList = $self->{SubActionList};
    my $Name          = $self->{Name};
    my $LogActionFlag = $self->{LogActionFlag};
    my $messages      = $self->{messages};
    my ($message,$subActionName,$subActionObj);

    # Forming message to be sent
    $message = "$fullName - $status";

    # Only include the URL in the message if the SendURL option was specified
    $message .= ($SendUrl) ? "\n$url\n" : ", ";
    &log("Adding message '$message' to action '$Name'") if ($VERBOSE > 1);

    # Add the message to the queue of messages to be sent out the next time the
    # action is triggered.
    push(@{$messages},$message);

    # Step through each sub-action, passing along the parameters.
    foreach $subActionName (@{$SubActionList})
    {
        # Log an error if the action name is invalid
        unless($subActionObj = &getAction($subActionName))
        {
            &error("Invalid action name '$subActionName' specified");
            next;
        }
        $subActionObj->add_message($fullName,$status,$url);
    }

    # If the LogAction parm was specified, then add it to the action log.
    if ($LogActionFlag)
    {
        VBTK::LogActionList::add($fullName,$status,$url,$self);
    }

    # Mark this action as pending execution
    $PENDING_QUEUE{$self} = $self;
    (0);
}

#-------------------------------------------------------------------------------
# Function:     triggerAll
# Description:  Attempt to trigger all pending actions.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub triggerAll
{
    my($actionObj,$actionKey,$pid);
    my @pendingActions = keys %PENDING_QUEUE;
    
    return unless(@pendingActions > 0);

#    # Make sure the previous action handler isn't still running
#    if(($LAST_HANDLER_PID) && (waitpid($LAST_HANDLER_PID,&WNOHANG) == 0))
#    {
#        &error("Previous action handler is still running.  Will try again later");
#        return 1;
#    }
#    
#    # Parent process
#    if($pid = fork)
#    {
#        &log("Forked off action handler - pid $pid");
#        $LAST_HANDLER_PID = $pid;
#    }
#    # Child process
#    elsif(defined $pid)
#    {
        &log("Checking for pending requests") if ($VERBOSE > 1);
        foreach $actionKey (@pendingActions)
        {
            $actionObj = $PENDING_QUEUE{$actionKey};
            $actionObj->trigger();
        }
#        exit(0);
#    }
#    else
#    {
#        &error("Can't fork action handler!  Will try again later");
#    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     trigger
# Description:  Check the time window and frequency limits and if okay, fork off
#               a process to execute the specified action.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub trigger
{
    my $self = shift;
    my $Name = $self->{Name};

    &log("Checking action '$Name' for messages") if ($VERBOSE > 1);

    # Check for messages.  If none, then just return
    my $message = join('',@{$self->{messages}});
    return 0 if ($message eq '');

    my $limitToEverySec       = $self->{LimitToEverySec};
    my $nextAllowedOccurrence = $self->{nextAllowedOccurrence};

    my ($pid,$ret_code,$now);

    &log("Checking occurence limit for action '$Name'") if ($VERBOSE > 1);
    $now = time;

    if(($nextAllowedOccurrence)&&($now < $nextAllowedOccurrence))
    {
        &log("Ignoring trigger of action '$Name'") if ($VERBOSE > 1);
        &log("Next occurrence allowed at '$nextAllowedOccurrence'")
            if ($VERBOSE > 1);
        return 0;
    }

    $self->{nextAllowedOccurrence} = $now + $limitToEverySec;

    &log("Triggering action '$Name'") if ($VERBOSE > 1);

    # Run the trigger action.  The 'run' method must return a positive value
    # or we won't clear out the messages queue.
    $self->run($message) || return 0;

    &log("Clearing all messages out of action '$Name'") if ($VERBOSE > 1);
    @{$self->{messages}} = ();

    # Remove object from the pending queue
    delete $PENDING_QUEUE{$self};

    (0);
}




1;
__END__

=head1 NAME

VBTK::Actions - Action definitions used by the VBTK::Server daemon

=head1 SYNOPSIS

  # Action to run a script on the command line
  $t = new VBTK::Actions (
    Name         => 'runScript',
    Execute      => '/usr/local/bin/myscript',
    LimitToEvery => '10 min',
    SendUrl      => 1,
  );

  # Group action, triggers other actions 
  $s = new VBTK::Actions (
    Name          => 'group1',
    SubActionList => 'runScript,emailMe',
  );

=head1 DESCRIPTION

The VBTK::Actions class is used to define actions to be taken by the 
L<VBTK::Server|VBTK::Server> daemon.  It can be used to Execute commands on 
the command line or to create a grouping of sub-actions.   To add new action
types, just sub-class off this class, overriding the 'run' method.  See the
L<VBTK::Actions::Email|VBTK::Actions::Email> class for an example of this.

=head1 METHODS

The following methods are supported

=over 4

=item $s = new VBTK::Actions (<parm1> => <val1>, <parm2> => <val2>, ...)

The allows parameters are:

=over 4

=item Name

A unique string identifying this action.  This still will be used in lists
of 'StatusChangeActions' passed to the L<VBTK::Server|VBTK::Server> daemon.
See L<VBTK::Server/item_StatusChangeActions> and
L<VBTK::Parser/item_StatusChangeActions> for details on where you'll be 
specifying these names.

    Name => 'runScript',

=item Execute

A string to be executed on the command line when the action is triggered.
A message will be passed in to the script on STDIN containing details about
which objects caused the action to be triggered.

    Execute => '/usr/local/bin/myscript'

=item LimitToEvery

A time expression used to limit the number of times the action can be
triggered within a window of time.  The expression will be evaluated by the
L<Date::Manip|Date::Manip> class, so it can be just about any recognizable
time or date expression.  For example: '10 min' or '1 day'.  (Defaults to
'2 min').

    LimitToEvery => '2 min',

=item SendUrl

A boolean value (0 or 1) indicating whether a one-click URL should be passed in
the action message which will allow the user to jump directly to the object
history entry which caused the action to be triggered.  Typically you would
always leave this on, unless you're sending messages to a pager or some 
other device where you wanted to keep the messages as short as possible.

    SendUrl => 1,

=item SubActionList

A string containing a comma-separated list of action names which should be 
triggered whenever this action is triggered.  This allows the creation of 
action groups which both send email, and also trigger other actions. 

    SubActionList => 'emailBob,pageDave,killPete',

=item LogActionFlag

A boolean value (0 or 1) indicating whether triggering this action should 
cause an entry to be added to the system action log.  (Not yet implemented).

    LogActionFlag => 0,

=back

=back

=head1 SUB-CLASSES

The following sub-classes were created to provide common defaults in the use
of VBTK::Actions objects.

=over 4

=item L<VBTK::Actions::Email|VBTK::Actions::Email>

Sending an email as an action.

=item L<VBTK::Actions::Email::Page|VBTK::Actions::Email::Page>

Sending an email to a pager as an action

=back

Others are sure to follow.  If you're interested in adding your own sub-class,
just copy and modify some of the existing ones.  Eventually, I'll get around
to documenting this better.

=head1 SEE ALSO

=over 4

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Parser|VBTK::Parser>

=item L<VBTK::Actions::Email|VBTK::Actions::Email>

=item L<VBTK::Actions::Email::Page|VBTK::Actions::Email::Page>

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
