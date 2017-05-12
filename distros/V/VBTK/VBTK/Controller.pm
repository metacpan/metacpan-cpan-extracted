#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/Controller.pm,v $
#            $Revision: 1.12 $
#                $Date: 2002/03/04 20:53:06 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: A common perl library used to start and stop the vb
#                       monitoring processes.
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
#       $Log: Controller.pm,v $
#       Revision 1.12  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.11  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.10  2002/03/02 00:53:54  bhenry
#       Documentation updates
#
#       Revision 1.9  2002/02/13 07:38:15  bhenry
#       Moved write_pid_file functionality from Common into Controller
#
#       Revision 1.8  2002/02/09 08:47:14  bhenry
#       Major overhaul to better support syncing
#
#       Revision 1.7  2002/02/08 02:16:04  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/01/26 06:15:59  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/01/25 07:18:22  bhenry
#       Added call to checkDateManipTZ
#

package VBTK::Controller;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::Client;
use VBTK::File;
use POSIX "sys_wait_h";
use FileHandle;
use Getopt::Std;

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

    &log("Creating new controller") if ($VERBOSE);

    # Store all passed input name pairs in the object
    $self->set(@_);

    # Setup a hash of default parameters
    my $defaultParms = {
        MasterVBServer  => $::REQUIRED,
        SlaveVBServers  => undef,
        LogDir          => $::VBLOGS,
    };

    # Run a validation on the passed parms, using the default parms        
    $self->validateParms($defaultParms) || &fatal("Exiting");
    
    # Setup a place to store VBServerURI's
    $self->{VBServerURIHash} = {};
    
    # Setup an index of SlaveVBServers after splitting the SlaveVBServers value
    # into an array if it isn't already one.
    my $slaveList = $self->{SlaveVBServers};
    $slaveList = [ split(/[\s,]+/,$slaveList) ] if (ref($slaveList) ne 'ARRAY');
    $self->{slaveVBServerIdx} = { map { $_ => 1 }  @{$slaveList} };
    $self->{isSlave} = $self->{slaveVBServerIdx}->{$::HOST};

    $self;
}

#-------------------------------------------------------------------------------
# Function:     addHostGroup
# Description:  Add a group of hosts which share the same VBServer.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub addHostGroup
{
    my $self = shift;
    my $VBServerURIHash = $self->{VBServerURIHash};
    my %args = @_;
    
    my $defaultParms = {
        VBServerURI => $::REQUIRED,
        HostList    => $::REQUIRED,
    };
    
    # Run a validation on the passed parms, using the default parms.
    &validateParms(\%args,$defaultParms) || &fatal("Exiting");

    my $HostList = $args{HostList};
    my $VBServerURI = $args{VBServerURI};
    my ($host,$progList);

    # Make sure hostlist is a reference to a hash
    if (ref($HostList) ne 'HASH')
    {
        &fatal("HostList parm must be a reference to a HASH");
    }

    foreach $host (keys %{$HostList})
    {
        # Check to see if this host was already defined somewhere else
        if ($VBServerURIHash->{$host})
        {
            &fatal("Host '$host' cannot be listed twice in the Controller config!");
        }
        
        # Store the VBServerURI to use for this host
        $VBServerURIHash->{$host} = $VBServerURI;

        # Just skip to the next one if we're not on this host.
        next unless ($host eq $::HOST);
        
        # Set the VBURI variable based on the VBServerURI
        $self->{vbServerURI} = $VBServerURI;        

        # If the progList isn't already an array, then make it one using split
        $progList = $HostList->{$host};
        $progList = [ split(/[\s,]+/,$progList) ] if (ref($progList) ne 'ARRAY');
        $self->{progList} = $progList;

        # Mark each specified program as being configured to run on this host
        $self->{canRun} = { map { $_ => 1 } @{$progList} };        
    }
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Start/stop the specified programs
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my $LogDir      = $self->{LogDir};
    my $canRun      = $self->{canRun};
    my $progList    = $self->{progList};
    my ($alias,$cmd,$prog);

    # Make sure that fork works
    &testFork || die "Unable to 'fork', can't continue";

    # Get the basename of the name this program was started with
    $0 =~ /([^\/]+)$/;
    $alias = $1;

    # If program was called as anything other than 'pmc' (for example as a
    # symbolic link named 'start') then assume the name is a command.
    $cmd = $alias if (($alias ne '')&&($alias =~ /^(start|stop|restart|sync)$/));

    # If program was not called with a different name, then use the first
    # command line argument as the command
    $cmd ||= shift(@ARGV);

    # If no command was specified, then die, showing the usage
    &show_usage if(!$cmd);

    # Switch to the VBCONF directory
    chdir "$::VBCONF" or die "Can't cd to $::VBCONF: $!\n";

    # Create a log dir if it doesn't exist
    mkdir $LogDir, 0755 unless (-d $LogDir);

    # If there are still entries on the command line, then override the default
    # program list
    if (@ARGV > 0)
    {
        # Make sure everything listed on the command line is configured to
        # run on this host.
        foreach $prog (@ARGV)
        {
            &fatal("$prog is not configured to run on $::HOST") 
                if (! $canRun->{$prog});
        }

        # Now store it back in the object
        $self->{progList} = [ @ARGV ];
    }

    if    ($cmd eq 'start')    { $self->doStart; }
    elsif ($cmd eq 'stop')     { $self->doStop; }
    elsif ($cmd eq 'restart')  { $self->doStop; $self->doStart; }
    elsif ($cmd eq 'sync')     { $self->doSync; }
    else                       { &show_usage; }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     show_usage
# Description:  Show the program usage statement
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub show_usage
{
    print STDOUT "Usage: $0 <start|stop|restart|sync>\n";
    exit 1;
}

#-------------------------------------------------------------------------------
# Function:     doStop
# Description:  For each program specified, search for a corresponding '.pid' 
#               file and kill all processes specified there which correspond
#               to the current server.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub doStop
{
    my $self = shift;
    my $progList = $self->{progList};
    my $LogDir = $self->{LogDir};
    my ($pidFile,@pidList,$prog);

    # Step through each configured program
    foreach $prog (@{$progList})
    {
        $pidFile = "$LogDir/$prog.$::HOST.pid";

        if (-f $pidFile )
        {
            # Read in a list of pids to kill
            open(PID,"< $pidFile") or 
                &fatal("Cant read '$pidFile'");
            @pidList = grep(s/\s*//g || 1,<PID>);
            close(PID);

            # Make sure we don't kill ourself            
            my $mypid = $$;
            @pidList = grep(! /^$mypid$/, @pidList);

            print STDOUT "Stopping $prog - pid @pidList\n";
            kill 15, @pidList;
            unlink($pidFile);
        }
    }
}

#-------------------------------------------------------------------------------
# Function:     doStart
# Description:  For each program specified startup the program.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub doStart
{
    my $self = shift;
    my $progList    = $self->{progList};
    my $vbServerURI = $self->{vbServerURI};
    my $LogDir      = $self->{LogDir};
    my ($logFile,$prog,$timestamp,$pid,$pidFileObj);

    # For each of the startable programs
    foreach $prog (@{$progList})
    {
        # Check to see if there is already a '.pid' file, indicating that either the
        # program is still running, or it terminated abnormally.
        if (-f "$LogDir/$prog.$::HOST.pid")
        {
            print STDOUT "\nSome '$prog' processes may still be running\n";
            print STDOUT "Use 'stop' to clear all processes first\n";
            next;
        }

        $logFile = "$LogDir/$prog.$::HOST.log";
        $pidFileObj = new VBTK::File("$LogDir/$prog.$::HOST.pid");
        $timestamp = &log_datestamp;
        $timestamp =~ s/:/-/g;

        print STDOUT "\n";

        if (-f "$logFile")
        {
            &log("Renaming $logFile to $logFile.$timestamp");
            rename $logFile, "$logFile.$timestamp";
        }

        &fatal("Can't read '$::VBCONF/$prog'") unless (-f "$::VBCONF/$prog");

        # Parent process
        if($pid = fork)
        {
            &log("Started '$::VBCONF/$prog' - pid $pid");
        }
        # Child process
        elsif(defined $pid)
        {
            # Insulate this process from the vbc controller process
            setpgrp(0,$$);

            # Write the current pid out to the pid file
            $pidFileObj->put("$$\n") || &fatal("Exiting");
            
            # Set the VBURI environment variable
            $ENV{VBURI} = $vbServerURI if ($vbServerURI);

            # Close STDOUT and STDIN and make a copy of STDERR            
            open(OLDSTDERR, ">&STDERR");
            STDOUT->close();
            STDIN->close();

            # Redirect stdout to the logfile and setup autoflush
            open(STDOUT, '>', "$logFile") || 
                die("Can't write to logFile '$logFile'");
            open(STDERR, ">&STDOUT")      || 
                die("Can't redirect STDERR to '$logFile'");
            STDOUT->autoflush(1);
            STDERR->autoflush(1);

            # Close the old STDERR            
            OLDSTDERR->close();

            # Execute the program
            exec "$^X", "$::VBCONF/$prog" ||
                &fatal("Can't run '$^X $::VBCONF/$prog' - $!");
#            do $::VBCONF/$prog || &error("Can't run '$::VBCONF/$prog' - $!$@");
        }
        else
        {
            &fatal("Can't fork!");
        }
    }
}

#-------------------------------------------------------------------------------
# Function:     doSync
# Description:  Sync files from the VB Server
# Input Parms:  None
# Output Parms: Number of files updated
#-------------------------------------------------------------------------------
sub doSync
{
    my $VBServerURI;

    # If we're passed a reference, then it's an object
    if(ref($_[0]))
    {
        my $self = shift;
        my $VBServerURIHash = $self->{VBServerURIHash};
        my $MasterVBServer  = $self->{MasterVBServer};
        my $isSlave         = $self->{isSlave};
        $VBServerURI = $VBServerURIHash->{$::HOST} || $::VBURI;

        # If this is a slave server, then ignore the setting for the VBServerURI
        # and instead use the URI of the MasterVBServer, since that's where we 
        # should be syncing files from.
        $VBServerURI = $VBServerURIHash->{$MasterVBServer} if ($isSlave);

        # If we're on the master VBServer, then there's no point in syncing onto
        # ourself.
        if($MasterVBServer eq $::HOST)
        {
            &fatal("Can't use 'sync' command on Master Server");
        }    
    }
    # Otherwise, they're probably passing in a URI to sync from
    else
    {
        $VBServerURI = shift;
    }

    # Skip the sync if we weren't able to determine a remote URI
    if(! $VBServerURI)
    {
        &log("Can't determine VBServerURI, skipping sync");
        return undef;
    }
    
    # Try to connect to the VBServer    
    &log("Setting up VBClient connection to $VBServerURI") if ($VERBOSE);
    my $vbClientObj = new VBTK::Client(RemoteURI => $VBServerURI);

    if (! $vbClientObj)
    {
        &error("Can't setup VBClient connection to $VBServerURI");
        return undef;
    }

    # Get a list of file objects to sync.    
    my ($rmtVBHome,@syncList) = $vbClientObj->getSyncList();

    if (@syncList < 1)
    {
        &error("Can't retrieve sync list from $VBServerURI, skipping sync");
        return undef;
    }
    
    # Step through the sync list, comparing files and syncing the ones which are 
    # out of sync.
    my $filesChangedCount = 0;
    my($fileObj,$fileName,$origFileName,$fullFileObj);
    foreach $fileObj (@syncList)
    {
        # Adjust the base path if VBHOME is different on this machine
        $fileObj->changeBasePath($::VBHOME);
        $fileName = $fileObj->getFileName();
        
        # Skip to the next file unless there are differences
        next unless ($fileObj->hasChanged());
        
        # See if the local file is newer and if so, then skip it
        if($fileObj->isNewer())
        {
            &log("Warning, local file '$fileName' is newer than on VBServer, skipping sync");
            next;
        }
        
        &log("Updating file '$fileName' from VBServer at '$VBServerURI'");
        $origFileName = $fileObj->getOrigFileName();
        $fullFileObj = $vbClientObj->getSyncFileObj($origFileName);
        
        if(! $fullFileObj)
        {
            &error("Can't retrieve '$origFileName' from VBServer");
            next;
        }
        
        $fullFileObj->changeBasePath($::VBHOME);
        $fullFileObj->sync();
        $filesChangedCount++;
    }
    
    ($filesChangedCount);
}

1;
__END__

=head1 NAME

VBTK::Controller - VBTK Master Controller Package

=head1 SYNOPSIS

  use VBTK::Controller;

  # Define some global settings for the controller
  $obj = new VBTK::Controller (
      MasterVBServer => 'myhost1',
      SlaveVBServers => 'myhost3'
  );

  # Define a host group and which RemoteURI they should report to.
  $obj->addHostGroup(
      VBServerURI => "http://myhost1:$::VBPORT",
      HostList    => {
          myhost1 => 'vbserver,vbcommon',
          myhost2 => 'vbcommon,vbping,vbhttp',
      },
  );

  # Define a host group and which RemoteURI they should report to.
  $obj->addHostGroup(
      VBServerURI => "http://myhost3:$::VBPORT",
      HostList    => {
          myhost3 => 'vbserver,vbcommon',
          myhost4 => 'vbcommon,vbtcp',
      },
  );

  $obj->run;

=head1 DESCRIPTION

This package is used to define the MasterVBServer, any SlaveVBServers and which
VB monitoring scripts should be run on each host.

=head1 PUBLIC METHODS

=over 4

=item $obj = new VBTK::Controller (<parm1> => <val1>, <parm2> => <val2>, ...)

The constructor for this class accepts the following parameters which indicate
which host is the master VBServer and which hosts are slave VBServers.  All config
file changes should be made on the master.  Changes can then be manually
replicated out to the slave servers and then to the clients by using the 'vbc sync' 
command on those hosts.

=over 4

=item MasterVBServer

This is used to define the hostname where the master VBServer will run.  This
entry is used only during sync of the slave servers.

=item SlaveVBServers

A comma-separated list of hosts on which slave VBServer process will be run.
When the 'vbc sync' command is run on a host specified in the 'SlaveVBServers'
list, the vbc script will ignore the 'VBServerURI' param specified for the
host and will instead use the 'VBServerURI' param specified for the host which
runs the master VBServer process.  

=back

=item $obj->addHostGroup(<parm1> => <val1>, <parm2> => <val2>, ...)

The 'addHostGroup' method is used to define a group of hosts along with the 
VBServerURI they should sync from and report to.  It also defines which 
monitoring scripts will run on each host.

=over 4

=item VBServerURI

This is the URI from which config files will be replicated and to which all 
client processes running in this host group will report statuses.  Hosts
defined as slave servers will ignore this entry when syncing and will instead
use the VBServerURI of the host specified as the master VBServer.

   VBServerURI => "http://myhost1:4712",

=item HostList

A pointer to a hash which matches up host names to comma-separated lists of
vb scripts.   The vb scripts must be names of real perl scripts in the 
$VBCONF directory.

  HostList => {
    myhost1 => 'vbserver1,vbcommon',
    myhost2 => 'vbserver2,vbcommon' },

=back

=back

=head1 SEE ALSO

=over 4

=item L<VBTK|VBTK>

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
