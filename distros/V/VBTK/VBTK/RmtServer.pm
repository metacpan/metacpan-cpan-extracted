#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/RmtServer.pm,v $
#            $Revision: 1.8 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to define a Remote VB server.
#
#          Description:
#
#           Directions:
#
#           Invoked by:
#
#           Depends on:
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
#       $Log: RmtServer.pm,v $
#       Revision 1.8  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.7  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.6  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.5  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/02/19 19:09:06  bhenry
#       Added getCount method
#
#       Revision 1.3  2002/02/13 07:39:44  bhenry
#       Disabled RrdLogRecovery and removed use of @log
#
#       Revision 1.2  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#

package VBTK::RmtServer;

use 5.6.0;
use strict;
use warnings;

use VBTK::Common;
use VBTK::Parser;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

our $VERBOSE=$ENV{'VERBOSE'};
our @RMTSERVERLIST;
our %QUICKLOOKUP;
our $REMOTE_GET_HTML_TIMEOUT=5;

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

    # Setup some defaults
    my $expireAfterSec = $self->{Interval} * 3;

    my $defaultParms = {
        HeartbeatObject      => ".$::HOST.hrtbt",
        LocalHeartbeatObject => ".$::HOST.hrtbt",
        Interval             => $::REQUIRED,
        RemoteURI            => $::REQUIRED,
        LocalURI             => $::REQUIRED,
        StatusChangeActions  => undef,
        StatusUpgradeRules   => [ 
            "Upgrade to Failed if Warning occurs 2 times in $expireAfterSec seconds" ],
        ExpireAfter          => "$expireAfterSec seconds",
        Description          => qq(
            The heartbeat objects track the ability of the VBServer to talk to another
            VBServer.  This object tracks the ability of the VBServer at
            '$self->{LocalURI}' to send a heartbeat signal to '$self->{RemoteURI}'. )
    };

    # Validate the passed parms
    $self->validateParms($defaultParms) || &fatal("Exiting");

    &log("Creating object for remote server '$self->{RemoteURI}'")
        if ($VERBOSE);


    # Setup parser objects to handle the local and remote heartbeat objects
    my $commonParserParms = {
        Interval          => $self->{Interval},
        VBHeader          => [ '        time       errors', 
                               '------------------ ------' ],
        VBDetail          => [ '@<<<<<<<<<<<<<<<<< @>>>>>',
                               '$time,$data[0]' ],
        LogDetail         => [ '$time $data[0]' ]
    };

    $self->{localObj} = new VBTK::Parser(
        VBServerURI       => $self->{LocalURI},
        %{$commonParserParms}
    );

    $self->{remoteObj} = new VBTK::Parser(
        VBServerURI       => $self->{RemoteURI},
        %{$commonParserParms}
    );


    # Now add VB objects to the two parser objects
    my $commonVBObjParms = {
        TextHistoryLimit    => 30,
        ReverseText         => 1,
        Rules               => { '$data[0] > 0' => 'Warning' },
        Requirements        => undef,
        StatusHistoryLimit  => 30,
        StatusChangeActions => $self->{StatusChangeActions},
        StatusUpgradeRules  => $self->{StatusUpgradeRules},
        ExpireAfter         => $self->{ExpireAfter},
        Description         => $self->{Description},
        RrdTimeCol          => undef,
        RrdColumns          => undef,
        RrdFilter           => undef,
        RrdMin              => undef,
        RrdMax              => undef,
        RrdXFF              => undef,
        RrdCF               => undef,
        RrdDST              => undef,
    };        

    # Setup the local object and graph
    my $localVBObj = $self->{localObj}->addVBObj(
        VBObjName           => $self->{LocalHeartbeatObject},
        %{$commonVBObjParms}
    );
    &fatal("Can't setup RmtServer vbObj") unless ($localVBObj);

    # Setup the remote object and graph
    my $remoteVBObj = $self->{remoteObj}->addVBObj(
        VBObjName           => $self->{HeartbeatObject},
        %{$commonVBObjParms}
    );
    &fatal("Can't setup RmtServer vbObj") unless ($remoteVBObj);

    push(@RMTSERVERLIST,$self);

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     sendHeartbeat
# Description:  Send the heartbeat to this remote server
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub sendHeartbeat
{
    my $self = shift;
    my $localObj = $self->{localObj};
    my $remoteObj = $self->{remoteObj};
    my $RemoteURI = $self->{RemoteURI};
    my $LocalURI = $self->{LocalURI};
    my ($result,$msg);

    # Pass an error count of '0' to the remote parser.
    $result = $remoteObj->parseData([[0]],$::SUCCESS);

    # If the set status fails, then set the error count to one for the local parser
    if($result)
    {
        $msg = "Error sending heartbeat status to '$RemoteURI'";
        &error($msg);
        $result = $localObj->parseData([[1]],$::WARNING,$msg);
    }
    # Otherwise, pass a 'Success' status to the local parser
    else
    {
        $result = $localObj->parseData([[0]],$::SUCCESS);
    }

    # If there is any error, then send a failed status to the remote vbserver.
    if($result)
    {
        $msg = "Error sending local heartbeat status to '$LocalURI'";
        &error($msg);
        $result = $remoteObj->parseData([[1]],$::WARNING,$msg);
        return 1;
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     sendHeartbeat
# Description:  Send the heartbeat to this remote server
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub sendAllHeartbeats
{
    my $result = 0;
    my $rmtServer;

    # Trigger all heartbeat objects
    foreach $rmtServer (@RMTSERVERLIST)
    {
        $result += $rmtServer->sendHeartbeat;
    }

    ($result);
}

#-------------------------------------------------------------------------------
# Function:     getCount
# Description:  Return the total number of configured Remote Servers
# Input Parms:  None
# Output Parms: Number of Remote Servers
#-------------------------------------------------------------------------------
sub getCount
{
    scalar(@RMTSERVERLIST);
}


1;
__END__

=head1 NAME

VBTK::RmtServer - Remote server class used by the VBTK::Server daemon

=head1 SYNOPSIS

Do not call this class directly.  Is is used by the L<VBTK::Server|VBTK::Server>
class.

  $r = new VBTK::RmtServer (
    HeartbeatObject      => '.$host.hrtbt',
    LocalHeartbeatObject => '.$host.hrtbt',
    Interval             => 60,
    RemoteURI            => 'http://myOtherServer:4712',
    LocalURI             => 'http://localServer:4712',
    StatusChangeActions  => {
        Failed   => 'pageMe,emailMe',
        Warning  => 'emailMe' },
    StatusUpgradeRules   => [
        'Upgrade to Failed if Warning occurs 2 times in 5 min',
    ExpireAfter          => 120,
    Description          => 'Heartbeat object'
 );

=head1 DESCRIPTION

The VBTK::RmtServer class is used by the L<VBTK::Server|VBTK::Server> class to
manage a list of remove VBTK::Server daemons with which it will maintain a
heartbeat and exchange information.  Do not call this class directly. 

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

