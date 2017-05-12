#! /bin/perl
#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK.pm,v $
#            $Revision: 1.29 $
#                $Date: 2002/03/04 20:54:25 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: This module is a placeholder for documentation for 
#                       the VB Toolkit
#
#       Copyright (C) 1996-2002  Brent Henry
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
#       $Log: VBTK.pm,v $
#       Revision 1.29  2002/03/04 20:54:25  bhenry
#       *** empty log message ***
#
#       Revision 1.28  2002/03/04 20:53:06  bhenry
#       *** empty log message ***
#
#       Revision 1.27  2002/03/04 16:49:08  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.26  2002/03/04 16:46:38  bhenry
#       *** empty log message ***
#
#       Revision 1.25  2002/03/02 01:01:22  bhenry
#       Documentation Updates
#
#

package VBTK;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::File;
use Exporter;
use ExtUtils::MakeMaker;
use File::Find;
use VBTK::Controller;

# Setup things to be exported
our $VERSION = '0.20';

our @ALL_VBTK_OBJECTS = ();
our $SIGNAL_CAUGHT = '';
our $VERBOSE=$ENV{VERBOSE};

our @ISA = qw(Exporter);
our @EXPORT = qw(install);

&VBTK::Common::checkDateManipTZ();

#-------------------------------------------------------------------------------
# Function:     runAll
# Description:  Loop through all registered VBTK objects, calling their 'run' method.
#               Continuously loop through the registered objects until either they
#               all return 'FINISHED' or we exceed the passed time limit.  Not that 
#               some VBTK objects will never return 'FINISHED'.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub runAll
{
    my $self = shift;
    my ($obj,$lowestSleepTime,$sleepfor,$retval,$returnAfter,@passedObjList);
    my ($highestExitValue,$sleepTime,$allFinished,$timeLeft,@objList);
    my $minSleepTime = 1;

    # If the first argument is a Wrapper object, then put that on the list.
    # Otherwise, the first argument is the 'returnAfter' time.
    if (ref($self) =~ /^VBTK::/)
    {
        @passedObjList = ($self);
        $returnAfter = shift;
    }
    else
    {
        $returnAfter = $self;
    }

    my $returnTime = time + $returnAfter;

    # Setup signal handlers to exit gracefully.
    $SIG{'TERM'} = $SIG{'INT'} = \&catchSignal;

    # Loop until all commands are finished executing.
    for(;;)
    {
        $timeLeft = $returnTime - time if (defined $returnAfter);
        $allFinished = 1;
        $lowestSleepTime = 600;
        
        # Have to keep re-loading the object list, since objects may have 
        # unregistered themselves during the last pass.
        @objList = (@passedObjList > 0) ? @passedObjList : @ALL_VBTK_OBJECTS;

        foreach $obj (@objList)
        {
            ($sleepTime,$retval) = $obj->run();

            # If retval is $::NOT_FINISHED, then the command is not complete and we should
            # look at the sleep time to determine when the command needs to be run again.
            if($retval == $::NOT_FINISHED)
            {
                $allFinished = 0;
                $lowestSleepTime = $sleepTime if ($sleepTime < $lowestSleepTime);
            }
            # Otherwise, the command is complete and we should examine the exit value.
            else
            {
                $highestExitValue = $retval if ($retval > $highestExitValue);
            }

            &catchSignal($SIGNAL_CAUGHT) if ($SIGNAL_CAUGHT ne '');
        }

        # If all processes have finished, then return.
        if ($allFinished)
        {
            $lowestSleepTime = -1;
            last;
        }

        # If we've exceeded our time limit, then return
        last if((defined $returnAfter)&&(time >= $returnTime));

        # Adjust lowest sleep time using the timeLeft variable
        if(defined $returnAfter)
        {
            $timeLeft = $returnTime - time;
            $lowestSleepTime = $timeLeft if ($timeLeft < $lowestSleepTime);
        }

        # Otherwise, just sleep until we need to run again
        &log("Sleeping for $lowestSleepTime") if ($VERBOSE > 1);
        $lowestSleepTime = $minSleepTime if ($lowestSleepTime < $minSleepTime);
        sleep $lowestSleepTime if ($lowestSleepTime > 0);
    }

    # If the calling subroutine wants an array then also return the highest exit
    # value
    (wantarray) ? ($lowestSleepTime,$highestExitValue) : ($lowestSleepTime);
}

#-------------------------------------------------------------------------------
# Function:     register
# Description:  Register the passed object so that it will be executed later when
#               the runAll method is executed.
# Input Parms:  Object
# Output Parms: None
#-------------------------------------------------------------------------------
sub register
{
    my $obj = shift;

    push(@ALL_VBTK_OBJECTS,$obj) if ($obj);

    (1);
}

#-------------------------------------------------------------------------------
# Function:     unRegister
# Description:  Remove the passed object from the registration list, so that it
#               won't be executed by the runAll method anymore.
# Input Parms:  Object
# Output Parms: None
#-------------------------------------------------------------------------------
sub unRegister
{
    my $delObj = shift;
    my @tempObjects = @ALL_VBTK_OBJECTS;

    # Clear out the list    
    @ALL_VBTK_OBJECTS = ();
    
    &log("Unregistering '$delObj' from process queue") if ($VERBOSE);

    # Now add back in any objects which don't match the passed one.    
    foreach my $obj (@tempObjects)
    {
        push(@ALL_VBTK_OBJECTS,$obj) unless ($obj eq $delObj);
    }

    (1);
}

#-------------------------------------------------------------------------------
# Function:     unRegisterAll
# Description:  Remove all objects from the registered list.
# Input Parms:  Object
# Output Parms: None
#-------------------------------------------------------------------------------
sub unRegisterAll
{
    # Clear out the list    
    @ALL_VBTK_OBJECTS = ();

    (0);
}

#-------------------------------------------------------------------------------
# Function id: catchSignal
#     Purpose: Capture signals sent to the program and re-route them.
#       Input: Exit code
#      Output: None
#-------------------------------------------------------------------------------
sub catchSignal
{
    my($signal) = @_;
    my $status = $::FAILED;
    my($obj,$pgrp);

    # Ignore all but TERM and INT signals
    if($signal =~ /^TERM|^INT/)
    {
        # If signal was caught once already, then kill all objects and
        # exit immediately
        if($SIGNAL_CAUGHT eq $signal)
        {
            foreach $obj (@ALL_VBTK_OBJECTS)
            {
                $obj->handleSignal($signal);
            }

            # Now kill anything else in the process group before we exit
            $SIG{'TERM'} = 'IGNORE';

            # Run 'getpgrp' in an eval, just in case it's not supported
            eval { $pgrp = getpgrp; };

            if ($pgrp > 0)
            {
                print STDOUT "Killing pgrp $pgrp\n";
                kill 15, -$pgrp;
            }

            exit(0);
        }
        # Otherwise, just mark the signal as caught, so that the main program
        # can exit when it's convenient.
        else
        {
            $SIGNAL_CAUGHT = $signal;
        }
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     appendToPath
# Description:  Add the paths path names to ENV{PATH} after checking to see if
#               they exist.
# Input Parms:  Array of path names
# Output Parms: New Path
#-------------------------------------------------------------------------------
sub appendToPath
{
    my(@searchPath) = @_;
    
    foreach my $dir (@searchPath)
    {
        if(-d $dir) { $ENV{PATH} .= ":$dir"; }
        else        { &log("Can't find searchpath dir '$dir', ignoring"); }
    }

    $ENV{PATH};
}

#-------------------------------------------------------------------------------
# Function:     prependToPath
# Description:  Add the paths path names to the beginning of ENV{PATH} after 
#               checking to see if they exist.
# Input Parms:  Array of path names
# Output Parms: New Path
#-------------------------------------------------------------------------------
sub prependToPath
{
    my(@searchPath) = @_;
    
    foreach my $dir (@searchPath)
    {
        if(-d $dir) { $ENV{PATH} = "$dir:$ENV{PATH}"; }
        else        { &log("Can't find searchpath dir '$dir', ignoring"); }
    }

    $ENV{PATH};
}

#-------------------------------------------------------------------------------
# Function:     install
# Description:  Use prompts to walk the user through the installation process.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub install
{
    my($resp,$dir,$installDir,$vbcObj,$vbcText,$mode,$result);

    # Check to see if VBHOME is created and writeable.
    if(! -d $::VBHOME)
    {
        print STDOUT "Can't find '$::VBHOME', please create it or set the " .
            "Environment variable \$VBHOME to an alternate location\n";
        exit 1;
    }
    
    # See if we're running as the userid 'vbtk', and warn if not.
    my ($uname) = getpwuid($<);
    if($uname ne 'vbtk')
    {
        print STDOUT "\n" .
            "It is recommended that you run all VB processes under a separate userid,\n" .
            "such as 'vbtk'.  You are currently running with the userid '$uname'.\n";
        $resp = prompt("Do you want to continue under this userid? ","n");
        exit 1 if($resp !~ /^y/i);
    }
    
    # Create appropriate directories under VBHOME, die if error
    foreach $dir ('bin','conf','etc','examples','logs','perf','web')
    {
        if ((! -d "$::VBHOME/$dir")&&(! mkdir "$::VBHOME/$dir"))
        {
            print STDOUT "Can't create dir '$::VBHOME/$dir'";
            exit 1;
        }
    }
    
    # Ask user if this will run the (M)aster VBServer, a (S)lave VBServer,
    # or just (C)lient VB processes?
    print STDOUT "\nWhich VBTK processes will you be running on this host?\n";
    $mode = prompt("(M)aster VBServer, (S)lave VBServer, or (C)lients only?","C");
    
    # If Master, then look for the original VBTK install directory and copy
    # files from bin, examples, etc, and web over from it.  Preconfigure the
    # vbc file in conf.  Ask user for a list of slave servers and clients on
    # which this will be run.  Once configured, give the user instructions
    # to install the perl libraries on each of those hosts and run the
    # install process there.
    if($mode =~ /^m/i)
    {
        print STDOUT "\n" .
            "Since this is to be a Master VBServer, I'll need to copy some files\n" .
            "from the original VBTK install directory.  Please enter it's location.\n";
            
        $installDir = prompt("Install dir location:","");
        
        if((! -d "$installDir")||(! -f "$installDir/Makefile.PL"))
        {
            print STDOUT "\nError: Can't find VBTK install files in '$installDir', try again\n";
            exit 1;
        }
        
        if($installDir eq $::VBHOME)
        {
            print STDOUT "\nError: Install dir can't be the same as \$VBHOME\n";
            exit 1;
        }
        
        # Check for all the appropriate directories
        my @copyDirs = qw(bin etc web examples);
        grep(s/^/$installDir\//,@copyDirs);
        foreach (@copyDirs)
        {
            if(! -d $_)
            {
                print STDOUT "\nError: Can't find '$_'\n";
                exit 1;
            }
        }
        
        # Copy specific files from install dir into new VBHOME.  If destination
        # file already exists, then prompt user what to do.
        my ($fileObj,$targetFile);
        my $filter = sub {
            return if (! -f or -l or m:/CVS:);
            
            $fileObj = new VBTK::File($_);
            $targetFile = $_;
            $targetFile =~ s/^$installDir/$::VBHOME/;

            # If there's no difference between source and destination files, then
            # just return
            return unless ($fileObj->hasChanged($targetFile));
            
            # If the file already exists, then prompt to override
            if(-f $targetFile)
            {
                print STDOUT "\nFile '$targetFile' already exists.  ";
                $resp = prompt("Overwrite?","y");
                return unless ($resp =~ /^y/i);
            }
            
            # Now try to sync the file
            if(! $fileObj->sync($targetFile))
            {
                print STDOUT "\nError: Can't copy '$_' to '$targetFile'\n";
                exit 1;
            }
        };
        
        print STDOUT "Copying files from '$installDir' to '$::VBHOME'\n";
        &find({ wanted => $filter, no_chdir => 1},@copyDirs);

        # If the conf/vbc file doesn't yet exist, then copy one over and make
        # a rough attempt to configure it.
        if (! -f "$::VBCONF/vbc")
        {
            print STDOUT "Copying 'examples/vbc' to 'conf/vbc\n";
            $vbcObj = new VBTK::File("$::VBHOME/examples/vbc");
            $vbcText = $vbcObj->get;
        
            # Make a few changes to the vbc file
            $vbcText =~ s/myhost1/$::HOST/mg;
        
            $vbcObj = new VBTK::File("$::VBCONF/vbc");
            $vbcObj->put($vbcText);
        }
        
        &checkPermsAndLinks();

        print STDOUT "\n" .
            "You should now proceed with the installation by editing the\n" .
            "'conf/vbc' file.  Just read the comments for instructions.\n";
    }
    # If Slave or Client, prompt user for VBURI of VBServer, connect, and 
    # download files.  Inspect vbc to see if it has been configured properly
    # and warn user if not.
    elsif($mode =~ /^s|^c/i)
    {
        # Prompt user for VBServerURI
        print STDOUT "\n" .
            "I need to pull some files from a configured VBServer.\n";
        $resp = prompt("Please enter the URI: ","$::VBURI") || 
            die ("Must specify VBServerURI");
        
        # Run the 'doSync' method on the controller object
        print STDOUT "Attempting to sync files from '$resp'\n";
        $result = &VBTK::Controller::doSync($resp);
        exit 1 if (! defined $result);
        print STDOUT "Sync was successful!\n";
        
        # Make sure our host is mentioned somewhere in the vbc file
        $vbcObj = new VBTK::File("$::VBCONF/vbc");
        $vbcText = $vbcObj->get;
        
        if (! $vbcText =~ /\b$::HOST\b/m)
        {
            print STDOUT "\n" .
                "Warning: It doesn't look like there's an entry for '$::HOST' in\n" .
                "the config file '$::VBCONF/vbc'.  Please go back to\n" .
                "the master VBServer and edit the 'vbc' config file to include\n" .
                "an entry for '$::HOST'\n";
            exit 1;
        }

        # If we're in slave mode, then remind the user to make sure that this
        # host is specified in the vbc file.
        if($mode =~ /^s/i)
        {
            print STDOUT "\n" .
                "You specified that this is to be a slave VBServer, so please\n" .
                "make sure that it's specified in the 'SlaveVBServers' parm in\n" .
                "the '$::VBCONF/vbc' file.\n";
        }
        
        &checkPermsAndLinks();

        print STDOUT "\n" .
            "Configuration was successful!!  You can now startup the monitoring\n".
            "processes on this machine with the command '$::VBCONF/vbc start'\n";
    }
    else
    {
        die("Invalid response, must select 'M','S', or 'C'");
    }
}

#-------------------------------------------------------------------------------
# Function:     checkPermsAndLinks
# Description:  Turn on the executable bit on 'vbc' and setup the 'start', 'stop'
#               'restart', and 'sync' links.
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub checkPermsAndLinks
{
    my($dir,$link);
    
    # Turn on the executable bit on the vbc script
    chmod 0755, "$::VBCONF/vbc";
    
    # Create symbolic links in both bin and conf
    foreach $dir ($::VBCONF,$::VBBIN)
    {
        foreach $link ('start','stop','restart','sync')
        {
            symlink "../conf/vbc","$dir/$link";
        }
    }
}

1;
__END__

=head1 NAME

VBTK - Virtual Brent Toolkit - A generic toolkit for system monitoring

=head1 DESCRIPTION

VBTK is a collection of modules which can be used to build a complex monitoring
system completely written in perl.  It's system monitoring abilities are, at the
moment, mostly limited to solaris unix servers.  But it also supports monitoring
through SNMP, HTTP, SMTP, POP3, etc., and the framework is easily expanded.
More modules will be added over time.  See the sections below on 
L<File System Layout|/FILE SYSTEM LAYOUT>, 
L<Environment Variables|/ENVIRONMENT VARIABLES>, 
L<Server and Control Modules|/SERVER AND CONTROL MODULES>, and
L<Data-Gathering Modules|/DATA-GATHERING MODULES>.

Note that the VB toolkit is just a group of modules.  You write the final
perl program which runs them yourself.  But don't let that deter you, everything
is defaulted and quite simple, so the final perl program is usually very simple.
Also, there are many L<examples|/item_examples> and templates to copy from.

=head2 SERVER AND CONTROL MODULES

The following modules are used in the VBTK collection to define the VB Server,
and control the various monitoring processes.  

=over 4

=item L<VBTK::Server|VBTK::Server>

This module allows the definition of a VB Server daemon process.  This process is
responsible for gathering, monitoring, and displaying the statuses and associated
text of of all test objects.  It has an embedded web server which is the access
point for client processes to submit statuses, as well as for users to view
statuses.  See L<VBTK::Server> for more details.

=item L<VBTK::Actions|VBTK::Actions>

This module allows the definition of actions which can be triggered by the VB server
based on status changes.  

There are also sub-classes of the VBTK::Actions module.  These provide convenient
defaults for two common types of actions - email and paging.  See L<VBTK::Actions> 
for more details.

=item L<VBTK::Controller|VBTK::Controller>

This module is used to start/stop all the various client and server processes
which make up the VBTK monitoring system.  See L<VBTK::Controller> for more
details.

=back


=head2 DATA-GATHERING MODULES

The following modules are run as part of client processes which gather data,
process it, and report it to the VB server.  Each module is setup with common
defaults so that it can be used with minimal configuration.  Some modules
have sub-classes which provide additional groups of common defaults, to 
further simplify configuration.  See each module's man page for more details.

=over 4

=item L<VBTK::Wrapper|VBTK::Wrapper>

This module is the heart of most of the monitoring scripts.  It is a simple 
command-line-execution wrapper.  It runs a command on the command line
and then parses the output.  It can also tail the output of a log file.
If multiple VBTK::Wrapper objects are defined in the same perl process,
the VBTK engine will time-share between them.  It passes it's collected
data on to the L<VBTK::Parser|VBTK::Parser> module.

There are also sub-classes of the VBTK::Wrapper module.  These provide convenient
defaults for various monitoring configurations, including running vmstat,
df, metatstat (DiskSuite), vxprint (VXVM), ping, etc.  (Mostly Solaris utilities)
See L<VBTK::Wrapper> for more details.

=item L<VBTK::Snmp|VBTK::Snmp>

This module allows the monitoring of systems through Snmp.  It retrieves a specified
list of SNMP oid's on a specified interval and passes them on to the 
L<VBTK::Parser|VBTK::Parser> module.

There are also sub-classes of the VBTK::Snmp module.  These provide convenient
defaults for various monitoring configurations, including monitoring network I/O,
Dynamo, NT cpu utilization, etc.  See L<VBTK::Snmp> for more details.

=item L<VBTK::Http|VBTK::Http>

This module allows the monitoring of a web server.  It retrieves HTML from specified
URL's on a specified interval.  It can establish an HTML baseline and compare the
retrieved HTML to the original baseline with each pass.  It also records the 
response time of the HTML retrieval.  See L<VBTK::Http> for more details.

=item L<VBTK::Tcp|VBTK::Tcp>

The module allows the monitoring of a TCP listener.  It simply attempts to 
connect to a specified host and port and then logs the success or failure.  It's
good for monitoring any TCP listener.  It records the reponse time of the 
connection attempt.  See L<VBTK::Tcp> for more details.

=item L<VBTK::DBI|VBTK::DBI>

This module allows the monitoring of databases through the use of the DBI module.
It executes pre-defined SQL on a specified interval, and passes the results on to 
the L<VBTK::Parser|VBTK::Parser> module.

There are also sub-classes of the VBTK::DBI module.  These provide convenient
defaults for various monitoring configurations, including monitoring oracle
tablespaces, io rates, and blocking processes.

=item L<VBTK::Smtp|VBTK::Smtp>

This module allows the monitoring of an SMTP server.  It sends an email through
the specified SMTP server on a specified interval, measures the response 
time, and passes the result on to the L<VBTK::Parser|VBTK::Parser> module.

=item L<VBTK::Pop3|VBTK::Pop3>

This module allows the monitoring of a POP3 server.  It connects to the POP3
server on a specified interval, measures the response 
time, and passes the result on to the L<VBTK::Parser|VBTK::Parser> module.
It can also be configured to retrieve email with a specified Subject, and
measure and store the round-trip time.  This is usually used together with the
L<VBTK::Smtp|VBTK::Smtp> module to test the full mail cycle.

=item L<VBTK::Log|VBTK::Log>

This module allows the monitoring of ascii text logs.  It will tail the specified
log or logs, searching for patterns, and setting VBObject statuses accordingly.

=item L<VBTK::Parser|VBTK::Parser>

This module is never called directly from a monitoring script.  It is the engine
responsible for parsing through the data retrieved by the data-gathering
modules and filtering, ignoring, or re-arranging the data as specified.  It makes
the decisions about what status to set, and handles contacting the VB server to
report the status, update graphs, store text, etc.  See L<VBTK::Parser> for more
details.

=back

=head2 ENVIRONMENT VARIABLES

The VB toolkit can make use of several environment variables to override the 
defaults entered when VBTK was first installed.  If you go with
the defaults, it makes things much simpler.

=over 4

=item VBHOME

This is the root directory of the VBTK files.  (Defaults to /usr/vbtk).

=item VBPORT

The TCP port on which the VBServer web server will be available and which the
client processes will report their statuses into the VBServer.  
(Defaults to 4712).

=item VBURI

The URI which the client processes will use to contact the VBServer when 
reporting their statuses.  (Defaults to 'http://vbserver:$VBPORT')  Note
that if you just setup a DNS alias for 'vbserver', then you don't have to
change the default.

=item VBPSWD

The path to a file where passwords can be stored for automated access by 
client processes.  This is currently only used by the 
L<VBTK::DBI|VBTK::DBI/item_user> module.

=item VBLOGS

The directory where the logs of STDOUT from each of the VBServer and 
client processes will be stored.  (Defaults to '$VBHOME/logs')

=item VBOBJ

The directory where the object database will be stored.  Don't put anything
else into this directory, it should just be for the object database.
(Defaults to '$VBHOME/vbobj')  You can override this in the call to
L<new VBTK::Server|VBTK::Server/Methods> with the 
L<ObjectDir|VBTK::Server/item_ObjectDir> parameter if you want.

=item RRDBIN

The location of the rrdtool binary.  Defaults to '/usr/local/bin/rrdtool'.

=back

=head2 FILE SYSTEM LAYOUT

By default, the VB toolkit installs into a single directory as designated by
the environment variable L<VBHOME|/item_VBHOME>.  Sub-directories are then setup
as follows.  See the section on L<Environment Variables|/ENVIRONMENT VARIABLES>
for details on how to relocate these from their default settings.

=over 4

=item bin

Location of some administrative scripts used for installing and replicating
the VBTK software.

=item conf

Location of user-defined configuration scripts

=item examples

A directory containing example files which can be copied into the 'conf' 
directory and then customized.

=item logs

Location of STDOUT log files from the VBServer and client processes.

=item mib

Directory in which MIB files can be installed for use by the 
L<VBTK::Snmp|VBTK::Snmp> module.

=item perf

Directory in which performance related log files are usually stored by
default.  These log files contain the data gathered by the client monitoring
processes.  Their format and location is determined by the 'LogFile', 
'LogHeader', and 'LogDetail' parameters passed in the contructors of the
L<data-gathering|/DATA-GATHERING MODULES> modules.

=item scripts

Directory in which can be placed shell or other scripts used by the
data-gathering processes to collect their data.

=item vbobj

Directory in which the VBServer stores it's VB Object database.  For each 
VB object created, the VBServer will create a sub-directory using the objects
full name.  All history data, RRD databases, meta data, etc will be stored in
this sub-directory.

=item web

Document root directory for the VBServer's built-in web server.  The '.phtml'
and images files in this directory are all user-customizable, so feel free to
customize the web interface as you like.  See the section on 
L<Customizing the Web Interface|VBTK::Server/CUSTOMIZING THE WEB INTERFACE>
in the L<VBTK::Server|VBTK::Server> documentation for more details.

=back

=head1 DEPENDENCIES

The VB toolkit depends on several other perl modules, which are readily 
available from CPAN.

=head2 REQUIRED DEPENDENCIES

The following modules are required.  They are available from CPAN -
http://www.cpan.org/modules.

=over 4

=item Bundle::LWP

=item L<Date::Manip|Date::Manip>

=item L<Algorithm::Diff|Algorithm::Diff>

=item L<File::Find|File::Find>

=item L<Storable|Storable>

=item L<Mail::Sendmail|Mail::Sendmail>

=item L<Mail::POP3Client|Mail::POP3Client>

=back

The simplest way to install these is to just use 'perl -MCPAN -e shell'.  Once 
in the shell, just type 'install Date::Manip', 'install Storable', etc.

=head2 OPTIONAL DEPENDENCIES

In addition, the VB toolkit can make use of the following modules if
installed.

=over 4

=item rrdtool

Allows for creation of RRD databases and dynamic generation of graphs
if the rrdtool is installed along with it's dependencies.  You can find the
source at http://www.rrdtool.com/index.html .  I strongly recommend installing
this!

=item L<SNMP|SNMP>

Allows for SNMP monitoring if the SNMP module is installed along 
with it's dependencies.  This requires requires the Net-SNMP toolkit library
available from http://sourceforge.net/projects/net-snmp .

=item L<DBI|DBI>

Allows for database monitoring via the DBI module, if the DBI module
is installed along with it's dependencies.

=back

=head1 INITIAL CONFIGURATION

Follow the README instructions for doing the usual Perl module 'make', 
'make test' and 'make install'.  Once that's done, getting a vanilla system
up and running is fairly easy.

=head2 ARCHITECTURE DESIGN

Before we start configuring anything, you need to plan your monitoring
architecture.  Draw a map of this on paper first, taking into consideration
the following areas.  Just start with something simple at first.

=over 4

=item Decide where to run the Master VBServer

Decide where you'll run the master VBServer process.  This is the instance
where you'll edit the config files for all other hosts and from which those
config files will be replicated when you use the 'vbc sync' command.

Note that the VBServer process can become quite intensive if you have a lot
of objects to monitor, so choose a machine which you can dedicate to just 
monitoring.  Also, make sure it's a stable machine (I guess that rules out
Windows...) which isn't going to get un-plugged by the janitor or crash
regularly.

=item Decide what hosts you will monitor

List out your hosts and what services they run.  Decide what you'll want to
monitor.  (ie: disk space, cpu utilization, web server, ftp server, mail server,
etc.)

=item Decide where to monitor from

Some monitoring is done locally, such as disk space, cpu utilization, disk
volume status, log tailing, etc.  Other monitoring is usually done remotely,
such as ping and testing of smtp, snmp, pop3, and other TCP services.  It's
usually easiest to run all the remote tests from one or two machines.  Also
you may want to run the same test from multiple locations.  For example, you
might want to test your HTTP server from both inside and outside the network.
That way you could better differentiate between a network failure and a HTTP
server failure.

=item Decide where to run Slave VBServers

If you have hosts you want to monitor which are not on the same LAN as the 
master VBServer, it's best
to setup a slave VBServer on the remote LAN.  The clients send a lot of data to
their VBServer and you don't want this all going over the WAN.  In addition, the 
master VBServer and slave VBServer can be configured to heartbeat each other, so
that in case one dies, the other can warn you. 

=item Decide where you'll access the web interface from

You can access the web interface from the Master node or from any Slave node.
They will all show all the objects in one interface.  But don't expose this
interface to the public internet, since I'm not sure about vulnerabilities.

=back

=head2 VBSERVER CONFIGURATION

Designate one host as the place to run your master VBServer.  This will be where
you make changes to the config files.  You can then use the 'vbc sync' command
on each of the other hosts to download the changes.  

Note that you don't have to use the 'sync' functionality.  You could just use
rsync or something similar to copy the config files around, or you could just
edit the config files independently on each host.  I prefer to have one master
and sync out from there, because it makes it easier to keep track of all the
config differences.

=over 4

=item Initial Setup

Follow the 'PER-SERVER CONFIGURATION' instructions below for just the VBServer
host.  When you run the installer, answer (M)aster when prompted for which
type of processes you'll be running on this host.

=item Edit 'vbc' Configuration File

Look in the $VBHOME/examples directory and you'll find example config files.  These
are actually perl programs, so it will help if you know some perl.  The 'vbc'
config file will have already been copied over to the $VBHOME/conf directory.
Open up the 'vbc' config file.  This is the controller file which defines which
instances will be running on each host.  You should already see the master VBServer
host listed there.  Add in all your other hosts, and specify any slave servers.

=item Edit 'vbserver' Configuration File

Copy the 'vbserver' config file from the 'examples' directory into the 'conf'
directory and edit it.  Just read the comments.

=item Start the 'vbserver' process.

Run 'conf/vbc start vbserver' and then check the log file 'logs/vbserver...'
for errors.  Now try to connect with a web browser to 
'http://<hostname>:4712'.

=back

=head2 PER-SERVER INITIAL CONFIGURATION

Now that you've drawn your monitoring map, let's get the various servers setup.
The software install is identical regardless of what you're going to run on the
host.  If you have hosts which won't be running any local tests, then you 
obviously don't need to install anything there.

=over 4

=item Create a user and group 'vbtk'.

If you're running this on a unix machine, you don't want to run it as superuser,
so create a user 'vb' and group 'vb' to run all the processes under.

    useradd vbtk 
    groupadd vbtk

=item Create a home directory.

Create a home directory for the VBTK software.  I suggest '/usr/vbtk', which is
the default.  Change this directory to be owned by the 'vbtk' user and to be the
'vbtk' user's home directory.

    mkdir /usr/vbtk; chown vb:vb /usr/vbtk

If you're going to use a directory other than '/usr/vbtk', then make sure you 
set the environment variable $VBHOME to the new location.  Make sure this is
always set before you run any scripts.

=item Run the installer.

This will check the VBHOME directory and prompt you for either the location of
the VBTK install directory or a VBServerURI from which it can sync config files.
It also does some setup in the $VBHOME directory.

    perl -MVBTK -e install

=back

=head2 ON-GOING CONFIGURATION

Once you have the initial VBServer running, read through the config files in
the examples directory and copy ones you want to use over to the conf directory.
Remember you have to list these config files in the 'vbc' config file in order
to start them with the 'vbc' command.  

You can also look through the various modules in the 
L<Data Gathering Modules|VBTK/Data-Gathering Modules> section of this document
for help on creating new config files.

=head1 SECURITY

Don't expose the web interface to the public internet!  I make no claims about 
how secure it is.  There may be vulnerabilities which I don't know about.

=head1 FAQ

=over 4

=item How do I delete an object?

Before you can delete an object, make sure that there isn't a client process
which is still sending sending a status for that object.  Otherwise it will 
just get recreated with the next status submission.  If you're not sure which
client process is setting the status, look under the 'Info' tab for that 
object for the 'Script Name' and 'Running From' values.  This shows you 
which script is setting the status.  Once you think you've fixed the script, 
check the object history to see if it's still being updated.  If not, go to 
the 'vbobj' directory, on the Master or Slave server to which this object is
reported, and delete the sub-directory which matches the object name.  After
about a minute, the object will disappear from the web interface.

=item There are error messages in the VBServer log about the 'rrdupdate' 
command failing.

If you've changed the number of entries being passed in the 
L<RrdColumns|VBTK::Parser/item_RrdColumns> entry, or if you've changed the 
L<CF|VBTK::Parser/CF> specification, then you probably need to rebuild
the corresponding RRD database.  Look in the VBHOME/vbobj directory for a 
directory named the same as the object and delete the RRD.db file.  Then 
restart the client process which monitors the object and the RRD.db file 
will be regenerated.

=back

=head1 OPTIONAL CUSTOMIZATION

The VBTK toolkit is written such that additional data-gathering modules can be
added on to it fairly easily.  See the 'examples' sub directory under the VBTK
home directory for examples of how to write your own data-gathering modules, or
look at the code of the data-gathering modules listed above.

=head1 KNOWN PROBLEMS

=over 4

=item @delta counter roll-over

The @delta array used in the 'VBDetail' and 'LogDetail' parms of data-gathering 
arrays doesn't yet take into account 32-bit and 64-bit roll-over.  So you may get
an occasional very large negative number when counters roll-over.  This will be
fixed in a future release.

=item Won't run on Windows

I did some initial testing running this under Windows, but had too many problems
with the 'fork' emulation.  It just didn't work quite right.  Also,
windows doesn't support 'alarm', which I use quite a bit.  So it's not
going to work.  It runs great on Cygwin however, so this is probably the best
way to go if you want to run it on a windows platform.

=item The VBServer engine needs performance tuning

The VBServer engine uses more resources than I would have liked, but seems to
run okay.  On my Sun Netra T1 440MHz server, with about 100 objects reporting
in, it runs at about 3-5% all the time.  I'll work on getting that down lower
in a future release.

=item Date::Manip timezone determination

The VBServer process will default to GMT if Date::Manip can't determine the 
timezone.  See L<Date::Manip/Timezones> for details on how to set the Timezone.

=back

=head1 FUTURE ENHANCEMENTS

I have several things in mind, but feel free to send suggestions.

=over 4

=item Action History Log and improved Actions

There needs to be a single place to go to see a log of all the actions fired
recently.  In addtion, I would like to add the option of requiring actions
to be acknowledged.  That way if your sysadmin misses the first page, it will
keep paging every n minutes, until they log in and acknowledge the problem.  

=item Persistent Cookie Handling in the VBTK::Http Module

I'd like to add the option of saving the cookie database somewhere on disk,
so that it doesn't get wiped out every time you restart.

=item Admin page in web interface

I'd like to add an 'Admin' page in the web interface to allow administrative
actions such as deleting an object, resetting the RRD database, etc.

=item MaxRepeat option for object history

I'd like to add a 'MaxRepeat' option for object history.

=back

=head1 SEE ALSO

=over 4

=item L<VBTK::Server|VBTK::Server>

=item L<VBTK::Actions|VBTK::Actions>

=item L<VBTK::RmtServer|VBTK::RmtServer>

=item L<VBTK::Templates|VBTK::Templates>

=item L<VBTK::Controller|VBTK::Controller>

=item L<VBTK::Wrapper|VBTK::Wrapper>

=item L<VBTK::Snmp|VBTK::Snmp>

=item L<VBTK::Http|VBTK::Http>

=item L<VBTK::Tcp|VBTK::Tcp>

=item L<VBTK::DBI|VBTK::DBI>

=item L<VBTK::Smtp|VBTK::Smtp>

=item L<VBTK::Pop3|VBTK::Pop3>

=item L<VBTK::Log|VBTK::Log>

=item L<VBTK::Parser|VBTK::Parser>

=back

=head1 SPECIAL THANKS

And a special thanks to all the great perl authors who's libraries I 
used to build this.  I couldn't have done it without you!  CPAN is great!

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
