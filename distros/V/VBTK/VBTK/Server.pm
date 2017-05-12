#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Server.pm,v $
#            $Revision: 1.10 $
#                $Date: 2002/03/02 00:53:55 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A perl library used to define a VB server.
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
#       $Log: Server.pm,v $
#       Revision 1.10  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.9  2002/02/20 19:25:18  bhenry
#       *** empty log message ***
#
#       Revision 1.8  2002/02/19 19:10:15  bhenry
#       Added ability to pass email-related parms in constructor
#
#       Revision 1.7  2002/02/13 07:39:28  bhenry
#       Moved write_pid_file functionality from Common into Controller
#
#       Revision 1.6  2002/02/08 02:16:04  bhenry
#       *** empty log message ***
#
#

package VBTK::Server;

use 5.004;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Actions;
use VBTK::Actions::Email;
use VBTK::Actions::Email::Page;
use VBTK::Templates;
use VBTK::Objects;
use VBTK::Client;
use VBTK::RmtServer;
use VBTK::DynPod2Html;
use VBTK::AdminLog;
use File::Find;

use POSIX;

use Date::Manip;

use VBTK::PHtml;
use VBTK::PHttpd;

our $VERBOSE=$ENV{'VERBOSE'};
our @CHILD_PIDS;
our $SIGNAL_CAUGHT;
our $CURR_SERVER;

# Make sure Date::Manip knows the timezone
&VBTK::Common::checkDateManipTZ();

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

    my $defaultParms = {
        LocalPort            => $::VBPORT,
        LocalAddr            => undef,
        ObjectDir            => "$::VBHOME/vbobj",
        DocRoot              => "$::VBHOME/web",
        ObjectPrefix         => 'local',
        ExternalURL          => "$::VBURI/status.phtml",
        SmtpHost             => 'localhost',
        EmailFrom            => 'vbtk@settomydomain.com',
        CompanyName          => undef,
        AdminEmail           => undef,
        Redirects            => undef,
        IndexNames           => 'index.html,index.htm,index.phtml,matrix.phtml',
        HousekeepingInterval => 60,
        UseWatchDog          => undef,
        ForkRrdUpdate        => 0,
        SyncDirs             => 'conf,examples,web,bin,etc',
        SyncExclude          => '/conf/\.|/CVS/|/pod2htm.*~~',
    };

    # Validate the passed parameters
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Check for a valid docRoot directory
    &fatal("Can't find DocRoot directory '$self->{DocRoot}'") 
        unless (-d $self->{DocRoot});

    # Check for a valid object dir, if not found, try to create it.
    if (! -d $self->{ObjectDir})
    {
        mkdir $self->{ObjectDir} ||
            fatal("Can't create ObjectDir directory '$self->{ObjectDir}'");
    }

    # Make a list of urls which change data in the engine.  These should be
    # processed without forking
    # my $dontForkList = [ 'setStatusRaw.phtml' ];

    # Changed to not do any forking, since it doesn't appear to be any faster.
    my $dontForkList = [ '.*' ];

    # Pass most of the parameters on to create a PHttpd object    
    $self->{phttpd} = new VBTK::PHttpd(
        LocalPort    => $self->{LocalPort},
        LocalAddr    => $self->{LocalAddr},
        DocRoot      => $self->{DocRoot},
        Handlers     => $self->{Handlers},
        IndexNames   => $self->{IndexNames},
        Redirects    => $self->{Redirects},
        DontForkList => $dontForkList 
    );

    &fatal("Exiting") unless ($self->{phttpd});

    # Now create the top-level node in the VBTK::Objects hierarchy.
    &log("Setting up object hierarchy");
    $self->{vbObj} = new VBTK::Objects(
        Name          => $::MASTER_NODE,
        SegmentName   => $::MASTER_NODE,
        ObjectDir     => $self->{ObjectDir},
        ExternalURL   => $self->{ExternalURL},
        DefaultPrefix => $self->{ObjectPrefix},
        ForkRrdUpdate => $self->{ForkRrdUpdate},
    );
 
    # Setup some global values for the Sendmail module
    $Mail::Sendmail::mailcfg{smtp} = [ $self->{SmtpHost} ] if ($self->{SmtpHost});
    $Mail::Sendmail::mailcfg{from} = $self->{EmailFrom} if ($self->{EmailFrom});
    
    # Setup an array to store a list of remote servers to show locally.
    $self->{showRemoteServerMatrixList} = [];

    return $self;
}

#-------------------------------------------------------------------------------
# Function:     addRemoteServer
# Description:  Setup the connection to any remote VB servers
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub addRemoteServer
{
    my $self = shift;
    my $LocalPort = $self->{LocalPort};
    my $LocalAddr = $self->{LocalAddr};
    my $Interval  = $self->{HousekeepingInterval};
    my $showRemoteServerMatrixList = $self->{showRemoteServerMatrixList};
    my $localURI = ($LocalAddr) ? "http://$LocalAddr:$LocalPort" :
        "http://$::HOST:$LocalPort";
        
    my %args = @_;

    # If the 'ShowMatrixLocally' parm was specified, then add the server URI to
    # the list of matrices to show on the local instance.
    push(@{$showRemoteServerMatrixList},$args{RemoteURI}) 
        unless ($args{DontShowMatrix});
    delete $args{DontShowMatrix};

    # Pass along the passed parameters to the RmtServer class        
    my $rmtServer = new VBTK::RmtServer(
        LocalURI => $localURI,
        Interval => $Interval,
        %args,
    );

    (0);
}

#-------------------------------------------------------------------------------
# Function:     addTemplate
# Description:  Add a template to the template list.
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub addTemplate
{
    my $self = shift;
    my $vbObj = $self->{vbObj};

    my $template = new VBTK::Templates(@_);
    $vbObj->addObjectTemplate($template);

    ($template);
}


#-------------------------------------------------------------------------------
# Function:     addAction
# Description:  Add an action to the template list.
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub addAction
{
    my $self = shift;
    my $vbObj = $self->{vbObj};
    my $action = $vbObj->addAction(@_);

    ($action);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Begin listening for and handling requests
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $returnAfter = shift;
    my $sock        = $self->{sock};
    my $Interval    = $self->{HousekeepingInterval};
    my $UseWatchDog = $self->{UseWatchDog};
    my $vbObj       = $self->{vbObj};
    my $phttpd      = $self->{phttpd};
    my ($pid);

    my ($status,$htmlStruct,$now,$alarmTime,$maxWaitTime,$subReturnAfter,$timeLeft);

    # Add a default template.  We always have to match at least one.
    $self->addTemplate (
        Pattern            => '.*',
        ExpireAfter        => undef,
        StatusHistoryLimit => '50',
        Description        => qq( No matching template - Using defaults ) );

    # Setup signal handlers
    $SIG{INT} = \&catchSignal;
    $SIG{TERM} = \&catchSignal;

    # If the watchdog option was specified, then fork a child process to handle
    # the VBTK::Server duties and re-start it if it dies.
    if($UseWatchDog)
    {
        # Loop forever, restarting the server process as needed
        while($pid = fork)
        {
            # This is the parent, so just wait for the child to die.
            # @CHILD_PIDS = ($pid);
            waitpid($pid,0);
            &error("VBTK::Server process exited abnormally - watchdog will restart");
            sleep 5;
        }

        &fatal("Can't fork - $!") if(! defined $pid);
    }

    # Import all objects from the VBTKObj directory
    $vbObj->importObjects();

    &log("Accepting connections");
    my $lastHousekeepingTime = time;

    # Calculate when to return from this routine, if the 'returnAfter' value
    # was set.
    my $returnTime = time + $returnAfter;

    # Send the heartbeat first.
    $self->forkHeartbeat;
    
    # Store the current server object in a global variable
    $CURR_SERVER = $self;

    # Accept and process connections
    for(;;)
    {
        # Calculate how much time left before we have to return to caller
        $timeLeft = $returnTime - time if ($returnAfter);

        # Calculate how long to let the phttpd daemon handle requests before
        # returning to this loop.
        $subReturnAfter = $Interval - (time - $lastHousekeepingTime);

        # Don't set the subReturnAfter be larger than timeLeft
        $subReturnAfter = $timeLeft if (($returnAfter) && ($timeLeft < $subReturnAfter));
        $phttpd->run($subReturnAfter);

        # Check for any signals previously caught
        &catchSignal($SIGNAL_CAUGHT) if (defined $SIGNAL_CAUGHT);

        &log("Doing housekeeping") if ($VERBOSE > 1);

        $lastHousekeepingTime = time;

        # Do housekeeping
        $vbObj->checkForExpiration();
        &VBTK::Actions::triggerAll();

        # Check for any signals previously caught
        &catchSignal($SIGNAL_CAUGHT) if (defined $SIGNAL_CAUGHT);

        # Cleanup zombies
        while(($pid = waitpid(-1,&WNOHANG)) > 0)
        {
            &log("VBTK::Server - Reaping pid $pid") if ($VERBOSE > 1);
        }
        
        # If we've exceeded our time limit then return
        if(($returnAfter)&&(time >= $returnTime))
        {
            &log("VBTK::Server::run, time to return") if ($VERBOSE > 1);
            undef $CURR_SERVER;
            return 0;
        }
    }
}

#-------------------------------------------------------------------------------
# Function:     getSyncList
# Description:  Build a list of file objects for all files specified in the
#               SyncInclude and SyncExclude strings.
# Input Parms:  None
# Output Parms: Reference to an array of file objects to be syncronized, VBHOME
#-------------------------------------------------------------------------------
sub getSyncList
{
    my $self = shift;
    
    # If no reference was passed then use the value in the global variable 
    # $CURR_SERVER.
    if((! defined $self) || (! ref($self)))
    {
        $self = $CURR_SERVER || return undef;
    }
    
    my $SyncDirs    = $self->{SyncDirs};
    my $SyncExclude = $self->{SyncExclude};
    my $currSyncListIndex = $self->{currSyncListIndex} = {};
    my ($fileObj,$fileName,@fileObjList);

    # Make sure a valid list of directories was passed.
    if(! $SyncDirs)
    {
        &error("SyncDirs parm must be set before calling 'buildSyncList'");
        return undef;
    }

    # If an array ref was passed for SyncDirs, then just use it.  If it's a string,
    # then split it at ','.
    my @syncDirs = (ref($SyncDirs) eq 'ARRAY') ? @{$SyncDirs} : split(/,/,$SyncDirs);
    
    # Also, add VBHOME onto the front of each directory.
    grep(s/^/$::VBHOME\// , @syncDirs);

    &log("Building list of dirs to sync from @syncDirs") if ($VERBOSE > 1);
    
    # Setup a subroutine for the call to 'find'.
    my $filter = sub {
        # Skip if not a file, or if a symlink, or if matches the exclude pattern
        return if (! -f or -l or (defined $SyncExclude && /$SyncExclude/));

        # Create a file object for this file and load it's 'stat' info
        if($fileObj = new VBTK::File ($_))
        {
            push(@fileObjList,$fileObj);
            $fileName = $fileObj->getFileName();
            $currSyncListIndex->{$fileName} = 1;
            $fileObj->loadStat();
            &log("Including file $fileName") if ($VERBOSE > 2);
        }
        (0);
    };

    # Run the find command
    &find({ wanted => $filter, no_chdir => 1},@syncDirs);

    # Return a list of file objects to sync
    (@fileObjList);
}

#-------------------------------------------------------------------------------
# Function:     getSyncFileObj
# Description:  Retrieve the specified file after making sure that it's in the 
#               allowed Sync list.
# Input Parms:  None
# Output Parms: Reference to an array of file objects to be syncronized, VBHOME
#-------------------------------------------------------------------------------
sub getSyncFileObj
{
    my $self = shift;
    my $fileName = shift;
    # If nothing was passed in, then just return
    return undef unless ($self);
    
    # If no reference was passed then use the value in the global variable 
    # $CURR_SERVER and load the first passed value into filename.
    if(! ref($self))
    {
        $fileName = $self;
        $self = $CURR_SERVER || return undef;
    }
    
    # If we couldn't determine the requested filename, then just return undef
    return undef unless ($fileName);
    
    # Now see if the file really exists and cause an error if not.
    if(! -f $fileName)
    {
        &error("Can't find requested file '$fileName' in call to getSyncFile");
        return undef;
    }
    
    my $currSyncListIndex = $self->{currSyncListIndex};

    # See if the file is in the sync list, if not then error out.
    if(! $currSyncListIndex->{$fileName})
    {
        &error("Requested file '$fileName' is not in allowed sync list");
        return undef;
    }
    
    # If we've made it this far, then let's load up the object.
    my $fileObj = new VBTK::File ($fileName);
    $fileObj->load() || return undef;

    ($fileObj);
}

#-------------------------------------------------------------------------------
# Function:     forkHeartbeat
# Description:  Fork off a child process to transmit any heartbeat messages
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub forkHeartbeat
{
    my $self = shift;
    my $Interval    = $self->{HousekeepingInterval};

    # See how many remote servers were configured and if none, then don't
    # fork the heartbeat process.
    my $RemoteServerCount = &VBTK::RmtServer::getCount();
    return unless ($RemoteServerCount > 0);

    my($pid,$nextHeartbeat,$sleepTime);

    # Parent process
    if ($pid = fork)
    {
        &log("Forked heartbeat process - pid $pid") if ($VERBOSE > 1);
        # push(@CHILD_PIDS,$pid);
    }
    # Child process
    elsif (defined $pid)
    {
        # Set signal handlers back to defaults
        $SIG{INT} = 'DEFAULT';
        $SIG{TERM} = 'DEFAULT';

        for(;;)
        {
            $nextHeartbeat = time + $Interval;
            &VBTK::RmtServer::sendAllHeartbeats;
            $sleepTime = $nextHeartbeat-time;
            sleep $sleepTime if ($sleepTime > 0);
        }
        exit 0;
    }
    else
    {
        &fatal("Can't fork heartbeat process - $!")
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     catchSignal
# Description:  Handle any INT or TERM signals.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub catchSignal
{
    my ($signal) = @_;
    my ($pgrp); 

    print STDOUT "Caught signal $signal\n";

    # Ignore all but TERM and INT signals
    if($signal =~ /^TERM|^INT/)
    {
        # If signal was caught once already, then kill all child procs and
        # exit immediately
        if($SIGNAL_CAUGHT eq $signal)
        {
            # Now kill anything else in the process group before we exit
            $SIG{'TERM'} = 'IGNORE';

            # Run 'getpgrp' in an eval, just in case it's not supported
            eval { $pgrp = getpgrp; };

            if ($pgrp > 0)
            {
                print STDOUT "Killing pgrp $pgrp\n";
                kill 15, -$pgrp;
            }

            exit(1);
        }
        # Otherwise, just mark the signal as caught, so that the main program
        # can exit when it's convenient.
        else
        {
            $SIGNAL_CAUGHT = $signal;
        }
    }
}

# Simple Get Methods
sub getCompanyName { my $self = shift || $CURR_SERVER; $self->{CompanyName}; }
sub getAdminEmail  { my $self = shift || $CURR_SERVER; $self->{AdminEmail}; }
sub getShowRemoteServerMatrixList { 
    my $self = shift || $CURR_SERVER; @{$self->{showRemoteServerMatrixList}} };

1;
__END__

=head1 NAME

VBTK::Server - Main server process for the VBTK toolkit

=head1 SYNOPSIS

Note that defining a VBTK::Server makes use of several modules.  A typical 
configuration would look something like this:

  use VBTK::Server
  use VBTK::Actions::Email
  use VBTK::Actions::Email::Page

  # Setup email actions
  new VBTK::Actions::Email ( Name => 'emailMe',  To => 'me@mydomain.com' );
  new VBTK::Actions::Email ( Name => 'emailBob', To => 'bob@mydomain.com' );

  # Setup paging actions
  new VBTK::Actions::Email::Page ( Name => 'pageMe',  To => 'page.me@mydomain.com');
  new VBTK::Actions::Email::Page ( Name => 'pageBob', To => 'page.bob@mydomain.com');

  # Setup some action groups
  new VBTK::Actions ( Name => 'emailSA', SubActionList => 'emailMe,emailBob' );
  new VBTK::Actions ( Name => 'pageSA',  SubActionList => 'pageMe,pageBob,emailSA' );

  # Initialize a server object.
  $server = new VBTK::Server (
    ObjectPrefix => 'sfo',
    SmtpHost     => 'mysmtphost',
    MailFrom     => 'vbtk@settomydomain.com',
    CompanyName  => 'My Company',
    AdminEmail   => 'sysop@settomydomain.com',
  );

  # Point to another VB server with which we will exchange heartbeats
  # and relay requests
  $server->addRemoteServer(
    RemoteURI      => 'http://myotherserver:4712' );

  # Create templates to match up status change actions with objects

  # Critical objects, page and email
  $server->addTemplate (
    Pattern        => 'nyc.*http|mainserver.*ping',
    StatusChangeActions => { 
      Failed  => 'pageSA',
      Expired => 'pageSA',
      Warning => 'emailSA' } );

  # Everything else, just email
  $server->addTemplate (
    Pattern         => '.*',
    StatusChangeActions => { 
      Failed  => 'emailSA',
      Expired => 'emailSA',
      Warning => 'emailSA' } );

  # Start the server listening and handling requests.
  $server->run;

=head1 DESCRIPTION

VBTK::Server is the central process for the VBTK toolkit.  It is used to define
and start a vbserver daemon which gathers together, evaluates, and displays all
the statuses, test data, and graphs of the various test programs.  It uses the
L<HTTP::Daemon|HTTP::Daemon> module to provide an HTTP/1.1 server which is the
access point for client processes to submit data and for users to view data.

The server process makes use of the L<VBTK::PHttpd|VBTK::PHttpd> and 
L<VBTK::PHtml|VBTK::PHtml> modules.
The entire user interface is written in PHTML (something I whipped up), and so
can be easily customized by anyone who is familiar with HTML and PERL.

=head1 METHODS

The following methods are supported

=over 4

=item $s = new VBTK::Server (<parm1> => <val1>, <parm2> => <val2>, ...)

The constructor passes many of it's parameters on in a call to VBTK::PHttpd.  All of 
these parms will default to a useable value if not specified.  This call initializes
the daemon, but does not start it listening yet.  The allowed parameters are:

=over 4

=item LocalPort

The TCP port number on which the VBServer will start it's web server listening for
requests.  See L<VBTK::PHttpd>.  Defaults to the environment variable 
$VBPORT as explained in the L<VBTK|VBTK> manpage.

=item LocalAddr

The IP address to which the VBServer's web server will bind itself.  If unspecified,
it will bind itself to '*'.  See L<VBTK::PHttpd/item_LocalAddr>.  (Defaults to undef)

=item ObjectDir

The directory in which object state is stored.  (Defaults to $VBOBJ, see the 
L<VBTK|VBTK> manpage for more details)

=item DocRoot

The docRoot directory for the VBServer web server.  (Defaults to $VBHOME/web)

=item ObjectPrefix

VBObject names which start with a '.' will have this pre-pended to it.  This allows
the use of the identical vb scripts in different zones.  (Defaults to 'local').  It
is strongly recommended that you specify an object prefix of your own.  Do not use
the same prefix on two different VBTK::Server instances or things will get very 
confusing.

=item ExternalUrl

When VBServer sends notification emails, it will use this value to
form the URL which allows one-click access to the object.  (Defaults to 
'$VBURI/status.phtml'.  See the L<VBTK|VBTK> manpage for more details)

=item HousekeepingInterval

Number of seconds between housekeeping runs.  Housekeeping includes executing
pending actions, checking object expiration times, etc.  (Defaults to 60)

=item SmtpHost

A string containing the hostname or IP to direct email to when triggering actions.
This value is passed directly to the Mail::Sendmail package.

=item EmailFrom

A string used as the 'From' address when triggering actions which send email.

=item CompanyName

A string which will be shown in the web interface as the company name.

=item AdminEmail

A string containing an email address which will be shown in the footer of 
each page of the web interface as the vbtk admin.

=item UseWatchDog

A boolean (0 or 1) indicating whether to use a watchdog process to start the
real server process.  The watchdog process will re-start the server process
if it dies for any reason.  I haven't ever seen it just die, so I've never
really used this, but it's there just in case.  (Defaults to 0).

=back

=item $s->addRemoteServer(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addRemoteServer' method is used to define additional VB servers with which
the local VB server should maintain a heartbeat.  The allowed parameters are:

=over 4

=item HeartbeatObject

Defines the name of the VB object which will store the status of the heartbeat
transmission on the remote server.  (Defaults to '.<hostname>.hrtbt')

=item LocalHeartbeatObject

Defines the name of the VB object which will store the status of the heartbeat
transmission on the local server.   (Defaults to '.<hostname>.hrtbt')  

=item RemoteURI

The URI of the remote VB server.  (ie: 'http://remoteserver:4712')  (Required)

=item DontShowMatrix

A boolean value (0 or 1) indicating whether the matrix from this remote server
should be pulled and shown with the local server's matrix.  A value of 1 means
that it will not be shown.  This is nice for pulling together all the statuses
from all your slave servers into a single web page.  (Defaults to 0)

=back

=item $s->addTemplate(<parm1> => <val1>, <parm2> => <val2>, ...)

Templates are used to assign properties to VB objects based on patterns.  This
allows the assignment of expiration periods, status change actions, etc., based
on how the objects are named.  Template settings are
only used if the corresponding values were not specified directly in the 
client-side object definition itself.  The allowed paramters are:

=over 4

=item Pattern

A string containing a perl pattern which will be used to match this template to
a VBTK::Server object name.  New objects are compared to each pattern
sequentially, in the order that the templates were added.  Once a match is 
found, the object will inherit the template settings.  

    Pattern => '.*http.*',

=item ExpireAfter

A string containing a date or time expression used to indicate how long
the server should allow the object to be idle before changing the status to
'Expired'.  The expression will be passed to the L<Date::Manip|Date::Manip>
library for evaluation, so you can put in almost any recognizable date or
time expression.  (ie: 1 day, 3 weeks, etc.)

    ExpireAfter => '10 min',

=item StatusHistoryLimit

A number indicating how many status change events to maintain in the history
for this object.  You can view history entries under the 'History' tab in the
VBTK::Server web interface.

    StatusHistoryLimit => '20',

=item StatusChangeActions

A pointer to a hash, containing 'Status' => 'ActionList' pairs.  These pairs
will be used to determine which actions to trigger when the object changes
to the specified status.  For example:

    StatusChangeAction => {
        Failed  => 'pageMe,emailMe',
        Warning => 'emailMe' }

See the legend on the VBTK::Server web page for a list of valid statuses.

=item StatusUpgradeRules

A pointer to an array of strings containing expressions which define rules for
upgrading the status based on repetition of a lower level status within a 
specified timeframe.  The expression must be of the form:

Upgrade to <newStatus> if <testStatus> occurs <count> times in <time expression>

For example:

    StatusUpgradeRules => [
      'Upgrade to Failed if Warning occurs 2 times in 6 min' ]

=item Description

A text description which will be displayed for this object under the 'Info'
tab in the VBTK::Server web interface.

    Description => qw( This object monitors the web server ),

=back

=item $s->run(<returnAfter>)

This method starts up the server process.  It will handle requests to the web
interface for <returnAfter> seconds or forever if no <returnAfter> is
specified.  Don't specify a <returnAfter> value unless you have your own outer
loop you need to run through periodically.  Call it as the very last step in
setting up your server.

=back

=head1 CUSTOMIZING THE WEB INTERFACE

The document root for the built-in web server is in $VBHOME/web.  There you
will find '.phtml' and images files which make up the web interface.  PHTML
is an extension of standard HTML which makes use of <!--#perl tags to create
dynamic HTML.  See L<VBTK::PHtml> for more details.

Customizing the web interface is quite simple if you know a little HTML and 
perl.  Just look through the comments and code in the '.phtml' files and
make changes as needed.

=head1 SEE ALSO

=over 4

=item L<VBTK::Actions|VBTK::Actions>

=item L<VBTK::Controller|VBTK::Controller>

=item L<VBTK::PHttpd|VBTK::PHttpd>

=item L<VBTK::PHtml|VBTK::PHtml>

=item L<HTTP::Daemon|HTTP::Daemon>

=item L<Mail::Sendmail|Mail::Sendmail>

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
