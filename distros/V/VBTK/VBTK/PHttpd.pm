#############################################################################
#
#                 NOTE: This file under revision control using RCS
#                       Any changes made without RCS will be lost
#
#              $Source: /usr/local/cvsroot/vbtk/VBTK/PHttpd.pm,v $
#            $Revision: 1.12 $
#                $Date: 2002/03/04 20:53:07 $
#              $Author: bhenry $
#              $Locker:  $
#               $State: Exp $
#
#              Purpose: 
#
#           Depends on: HTTP::Daemon, HTTP::Status, IPC::Open2, URI::Escape
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
#       $Log: PHttpd.pm,v $
#       Revision 1.12  2002/03/04 20:53:07  bhenry
#       *** empty log message ***
#
#       Revision 1.11  2002/03/04 16:49:09  bhenry
#       Changed requirement back to perl 5.6.0
#
#       Revision 1.10  2002/03/02 00:53:55  bhenry
#       Documentation updates
#
#       Revision 1.9  2002/02/13 07:41:05  bhenry
#       Changed to use  instead of
#
#       Revision 1.8  2002/01/29 00:50:08  bhenry
#       Changes to make generic
#
#       Revision 1.7  2002/01/28 22:28:45  bhenry
#       *** empty log message ***
#
#       Revision 1.6  2002/01/28 18:13:19  bhenry
#       *** empty log message ***
#
#       Revision 1.5  2002/01/26 06:15:59  bhenry
#       *** empty log message ***
#
#       Revision 1.4  2002/01/23 20:21:43  bhenry
#       Improved handling of passed parms
#
#       Revision 1.3  2002/01/21 17:07:40  bhenry
#       Disabled 'uninitialized' warnings
#
#       Revision 1.2  2002/01/18 19:24:50  bhenry
#       Warning Fixes
#
#       Revision 1.1.1.1  2002/01/17 18:05:57  bhenry
#       VBTK Project
#
#       Revision 1.23  2002/01/04 10:40:44  bhenry
#       Improvements during vacation.
#       Revision 1.22  2001/12/18 10:40:08  bhenry
#

package VBTK::PHttpd;

use 5.6.0;
use strict;
use warnings;
# I like using undef as a value so I'm turning off the uninitialized warnings
no warnings qw(uninitialized);

use VBTK::Common;
use VBTK::PHtml;
use HTTP::Daemon;
use HTTP::Status;
use IPC::Open2;
use URI::Escape;
use POSIX;

our $VERBOSE = $ENV{VERBOSE};

our $ALARM_SUPPORTED;
our $FORK_SUPPORTED;
our $SIGNAL_CAUGHT;

our $REQUIRED = "$;$;::REQUIRED_PARM::$;$;";

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

    &log("Creating PHttpd object") if ($VERBOSE);

    # Call the set method to setup all passed arguments    
    $self->set(@_);

    my $defaultParms = {
        DocRoot      => $REQUIRED,
        LocalPort    => 80,
        LocalAddr    => undef,
        ListenQueue  => 30,
        IndexNames   => 'index.html,index.htm,index.phtml',
        Handlers     => {},
        Redirects    => {},
        AuthList     => {},
        AuthRealm    => "Perl PHttpd",
        DontForkList => [],
        ReqTimeout   => 6,
    };

    # Validate the passed parms
    $self->validateParms($defaultParms) || &fatal("Exiting");

    # Setup some default handlers        
    my $h = $self->{Handlers};
    $h->{'.phtml$'} = \&defaultPHtmlHandler if (! defined $h->{'.phtml$'});
    #$h->{'.cgi$'} = \&defaultCgiHandler if (! defined $h->{'.cgi$'});

    # Convert comma-separated lists into arrays if they aren't already
    $self->{IndexNames} = [ split(/,/,$self->{IndexNames}) ]
        unless (ref($self->{IndexNames}) eq 'ARRAY');
    $self->{DontForkList} = [ split(/,/,$self->{DontForkList}) ]
        unless (ref($self->{DontForkList}) eq 'ARRAY');

    # Create a listener
    my $localAddr = $self->{LocalAddr};
    $localAddr = '*' if (! defined $localAddr);
    
    &log("Setting up HTTP listener on $localAddr:$self->{LocalPort}")
        if ($VERBOSE);
    my $httpd = new HTTP::Daemon(
        LocalPort => $self->{LocalPort},
        LocalAddr => $self->{LocalAddr},
        Reuse => 1,
        Listen => $self->{ListenQueue});

    # Check for errors
    unless($httpd)
    {
        &error("Can't allocate HTTP::Daemon on $self->{LocalAddr}:$self->{LocalPort}");
        return undef;
    }

    # Test the alarm and fork functions
    # $ALARM_SUPPORTED = &testAlarm;
    $FORK_SUPPORTED = &testFork;

    $self->{httpd} = $httpd;

    ($self);
}

#-------------------------------------------------------------------------------
# Function:     run
# Description:  Start listening for and handling requests
# Input Parms:
# Output Parms: 
#-------------------------------------------------------------------------------
sub run
{
    my ($self,$returnAfter,$parms) = @_;

    my $httpd = $self->{httpd};

    # Calculate when to return, if the 'returnAfter' value was set.
    my $returnTime = time + $returnAfter;
    my ($conn,$req,$timeLeft,$pid);

    # If no parameters were passed in then create an empty hash.
    $parms = {} unless ($parms);

    # Ignore SIGPIPE errors, which seem to occur sporadically during
    # communications.
    $SIG{'PIPE'} = 'IGNORE';

    # Setup local signal handlers
    local $SIG{'TERM'} = \&catchSignal;
    local $SIG{'INT'} = \&catchSignal;

    # Handle connections forever
    for(;;)
    {
        # Calculate how much time we have left
        $timeLeft = $returnTime - time if ($returnAfter);
        $conn = $self->waitForRequest($timeLeft);

        # Check for any signals previously caught
        &catchSignal($SIGNAL_CAUGHT) if (defined $SIGNAL_CAUGHT);

        if(defined $conn)
        {
            while ($req = $self->getRequest) 
            {
                if ($req->method =~ /^GET$|^POST$/) 
                {
                    $self->forkHandleRequest($conn,$req,$parms);
                }
                else 
                {
                    &error("Invalid request method - " . $req->method);
                    $conn->send_error(RC_FORBIDDEN);
                }
                # Force a new connection each time so we don't lock up waiting
                # for a subsequent request from the same client.
                $conn->force_last_request;
            }
            $conn->close;
        }

        # Close the connection
        undef($conn);
        undef($self->{conn});

        # Cleanup any zombies
        while(($pid = waitpid(-1,&WNOHANG)) > 0)
        {
            &log("VBTK::PHttpd - Reaping pid $pid") if ($VERBOSE > 1);
        }

        # Check for any signals previously caught
        &catchSignal($SIGNAL_CAUGHT) if (defined $SIGNAL_CAUGHT);

        # If we've exceeded our time limit then return
        if(($returnAfter > 0)&&(time >= $returnTime))
        {
            &log("PHttpd::run, time to return") if ($VERBOSE > 1);
            return 0;
        }
    }
}

#-------------------------------------------------------------------------------
# Function:     getRequest
# Description:  Get the incoming HTTP request.  Only allow the specified amount
#               of time before hanging up.
# Input Parms:
# Output Parms: 
#-------------------------------------------------------------------------------
sub getRequest
{
    my $self = shift;

    my $httpd = $self->{httpd};
    my $conn = $self->{conn};
    my $ReqTimeout = $self->{ReqTimeout};

    my ($req);

    &log("Retrieving request...") if ($VERBOSE > 1);

    $conn->timeout($ReqTimeout);
    $req = $conn->get_request;
    
#    eval {
#        local $SIG{ALRM} = sub { die "Timed out waiting for request\n"; };
#        alarm $ReqTimeout if($ALARM_SUPPORTED);
#
#        $req = $conn->get_request;
#
#        alarm 0 if ($ALARM_SUPPORTED);
#    };
#
#    alarm 0 if ($ALARM_SUPPORTED);

    # Store connection object in the main object.    
    $self->{req} = $req;

    ($req);
}


#-------------------------------------------------------------------------------
# Function:     waitForRequest
# Description:  Wait for a HTTP request.  Only wait as long as the specified
#               time.
# Input Parms:
# Output Parms: 
#-------------------------------------------------------------------------------
sub waitForRequest
{
    my $self = shift;
    my $timeLeft = shift;

    my $httpd = $self->{httpd};

    my ($conn,$logStr);

    $logStr = "up to $timeLeft seconds " if ($timeLeft > 0);
    &log("Waiting " . $logStr . "for a connection...") if ($VERBOSE > 2);

    $httpd->timeout($timeLeft);
    $conn = $httpd->accept;

    # Log a message if we timed out
    unless ($conn)
    {
        &log('Timed out waiting for connection') if ($VERBOSE > 2);
    }

    # Store connection object in the main object.    
    $self->{conn} = $conn;

    ($conn);
}

#-------------------------------------------------------------------------------
# Function:     forkHandleRequest
# Description:  Check to see if we match the 'dontFork' pattern list and if not,
#               then fork a process to handle the passed request.  Otherwise, 
#               just process it inline.
# Input Parms:  
# Output Parms: 
#-------------------------------------------------------------------------------
sub forkHandleRequest
{
    my ($self,$conn,$req,$parms) = @_;
    my $DontForkList = $self->{DontForkList};
    my $target = $req->url->path;
    my $fork = 1;
    my ($pattern,$pid);

    # Check to see if we should prevent forking.
    foreach $pattern (@{$DontForkList})
    {
        &log("Checking dontForkList - $pattern") if ($VERBOSE > 2);
        $fork = 0 if ($target =~ /$pattern/);
    }

    if($fork)
    {
        &log("Forking process to handle request") if ($VERBOSE > 1);

        # If this is the parent process, then just return
        if($pid = fork)
        {
            return 1;
        }
        # If it's the child, then handle the request and die
        elsif(defined $pid)
        {
            $self->handleRequest($conn,$req,$parms);
            $conn->force_last_request;
            $conn->close;
            exit 0;
        }
        # Otherwise, there was an error while forking, so just handle it
        # inline.
        else
        {
            &error("Unable to fork, processing in-line");
        }
    }

    # If we made it this far, then either the fork failed, or we're not
    # supposed to fork.  Either way, we'll just handle it inline.
    $self->handleRequest($conn,$req,$parms);
}

#-------------------------------------------------------------------------------
# Function:     handleRequest
# Description:  Handle the passed request
# Input Parms:
# Output Parms: 
#-------------------------------------------------------------------------------
sub handleRequest
{
    my ($self,$conn,$req,$parms) = @_;

    my $DocRoot = $self->{DocRoot};
    my $IndexNames = $self->{IndexNames};
    my $Handlers = $self->{Handlers};
    my $Redirects = $self->{Redirects};
    my $ReqTimeout = $self->{ReqTimeout};
    my $HouseKeeper = $self->{HouseKeeper};
    my $AuthList = $self->{AuthList};
    my $AuthRealm = $self->{AuthRealm};
    my $httpd = $self->{httpd};

    my $target = $req->url->path;
    my $equery = $req->url->equery || '';
    my $from = $conn->peerhost;

    # Set the host part of the URL back to what the user typed in
    my $reqHost = $req->header('Host');
    $req->url->host_port($reqHost) if ($reqHost);

    if($VERBOSE)
    {
        my $reqStr = $req->method . " $target?" . $equery;
        $reqStr .= $req->content if ($VERBOSE > 2);
        $reqStr =~ s/[^\w\s\=\&\?\/\\\-\%\.]//g;
        &log("Request from '$from' - $reqStr");
    }

    my ($str,$key,$value,$response,$pattern,$rURI,$listRef);

    # If the target matches one of the redirects, then redirect
    foreach $pattern (keys %{$Redirects})
    {
        &log("Checking redirect rule for '$pattern'") if ($VERBOSE > 2);
        if($target =~ /$pattern/)
        {
            # Create a redirect URI, using the current URI as it's base
            $rURI = URI->new_abs($Redirects->{$pattern},$req->url);

            &log("Redirecting to '$rURI'") if ($VERBOSE > 1);
            $conn->send_redirect($rURI);
            return 0;
        }
    }

    # If the target is a directory, then see if there's an index and if so
    # send a redirect to it.
    if(-d "$DocRoot/$target")
    {
        foreach my $indexName (@{$IndexNames})
        {
            &log("Checking for '$DocRoot$target$indexName'") if ($VERBOSE > 2);
            if (-f "$DocRoot$target$indexName")
            {
                # Create a redirect URI, using the current URI as it's base
                $rURI = URI->new_abs("$indexName",$req->url);

                &log("Redirecting to '$rURI'") if ($VERBOSE > 1);
                $conn->send_redirect($rURI);
                return 0;
            }
        }
    }

    # Check to see if access has been restricted
    foreach $pattern (keys %{$AuthList})
    {
        &log("Checking security restrictions for '$pattern'") if ($VERBOSE > 2);

        # If it matches, then see if we've received the authentication,
        # otherwise, request authentication
        if($target =~ /$pattern/)
        {
            &log("Using security settings for '$pattern'") if ($VERBOSE > 2);

            my $handler = $AuthList->{$pattern};
            my ($user,$pswd) = $req->authorization_basic;

            # If the user and password are blank, or the authentication fails,
            # then we need to send the authenticate challenge
            if((! defined $user)||(! &$handler($user,$pswd)))
            {
                $response = new HTTP::Response;
                $response->code(RC_UNAUTHORIZED);
                $response->www_authenticate("basic realm=\"$AuthRealm\"");
                $conn->send_response($response);
                return 0;
            }

            # If we made it this far, then setup a cookie to save the fact
            # that we made it through the authorization
            # -- TBD --
        }
    }

    # Check for passed handlers
    foreach $pattern (keys %{$Handlers})
    {
        &log("Checking handler list for '$pattern'") if ($VERBOSE > 2);

        # If it matches, then call it, passing the target and parms.
        if($target =~ /$pattern/)
        {
            &log("Using handler for '$pattern'") if ($VERBOSE > 1);

            my $sub = $Handlers->{$pattern};

            my %allParms = %{$parms};

            # Create a hash with all passed name/value pairs, including
            # the ones passed from the calling method.
            foreach my $str (split(/[&]/, $equery),split(/[&]/, $req->content))
            {
                ($key,$value) = split(/[=]/, $str);
                $value =~ s/\+/ /g;
                $value = uri_unescape($value);

                # Create a list entry, in case multiple values are passed in for
                # the same parm.
                $allParms{'list',$key} ||= [];
                push(@{$allParms{'list',$key}},$value);

                $allParms{$key} = $value;
            }

            &$sub($conn,$req,"$DocRoot$target",$DocRoot,\%allParms);

            &log("Finished handling request") if ($VERBOSE > 2);

            return 0;
        }
    }

    # If there's no special handler, then just serve up the file
    if (-f "$DocRoot$target")
    {
        $conn->send_file_response("$DocRoot$target");
    }
    else
    {
        &error("Request for invalid file - '$DocRoot$target'");
        $conn->send_error(RC_NOT_FOUND);
    }

    (0);
}

#-------------------------------------------------------------------------------
# Function:     defaultPHtmlHandler
# Description:  Handle the incoming request
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
sub defaultPHtmlHandler
{
    my ($conn,$req,$target,$baseDir,$parms) = @_;

    my $html = VBTK::PHtml::generateHtml($target,$baseDir,$parms,$conn,$req);

    if(defined $html)
    {
        &log("Creating HTTP::Response object") if ($VERBOSE > 2);
        my $response = new HTTP::Response;
        $response->content($html);

        # Force the content type if the PHtml set it in the parms hash
        $response->content_type($parms->{content_type})
            if (defined $parms->{content_type});

        $conn->send_response($response);
    }
    else
    {
        $conn->send_error(RC_INTERNAL_SERVER_ERROR);
    }
    (0);
}

#-------------------------------------------------------------------------------
# Function:     defaultCgiHandler
# Description:  Handle the incoming request
# Input Parms:
# Output Parms:
#-------------------------------------------------------------------------------
#sub defaultCgiHandler
#{
#    my ($conn,$req,$baseDir,$target,$parms) = @_;
#    my ($rdrfh,$wtrfh,$key,$str,$pid,@html,$htmlRoot,$podFile);
#
#    pipe (CRDR, CWTR) || &fatal("defaultCgiHandler: Can't create pipe");
#    pipe (PRDR, PWTR) || &fatal("defaultCgiHandler: Can't create pipe");
#    CWTR->autoflush(1);
#    PWTR->autoflush(1);
#
#    if($pid = fork)
#    {
#        &log("In parent, waiting for response from child") if ($VERBOSE > 3);
#        WTR->close();
#        @html = <RDR>;
#        RDR->close();
#        waitpid $pid, 0;
#    }
#    elsif(defined $pid)
#    {
#        &log("In child, preparing to run pod2html") if ($VERBOSE > 3);
#
#        RDR->close();
#        open(STDOUT,">&WTR") || &fatal("Can't redirect STDOUT to pipe");
#
#        pod2html(
#            "--htmlroot=$htmlRoot",
#            "--header",
#            "--libpods=perlfunc:perlguts:perlvar:perlrun:perlop",
#            "--infile=$podFile"
#        );
#
#        WTR->close();
#        STDOUT->close();
#        exit 0;
#    }
#    else
#    {
#        error("genPodHtml: Can't fork");
#    }
#
#    # Run the command;
#    $pid = open2($rdrfh,$wtrfh,$target);
#
#    # If there's no PID, then just return
#    unless($pid)
#    {
#        $conn->send_error(RC_INTERNAL_SERVER_ERROR);
#        $rdrfh->close;
#        $wtrfh->close;
#        return -1;
#    }
#
#    # Write out all the passed parameters to the CGI
#    foreach $key (keys %{$parms})
#    {
#        print $wtrfh "$key=$parms->{$key}\n";
#    }
#    $wtrfh->close;
#
#    # Read all the output    
#    my @output = <$rdrfh>;
#
#    # Define a response object
#    my $response = new HTTP::Response;
#
#    # Step through the headers
#    for(;;)
#    {
#        $str = unshift(@output);
#        last if ($str =~ /^\s*$/);
#
#        if($str =~ /ContentType/) { $response->type($1); }
#    }
#
#    my $html = join('',@output);
#
#    if(defined $html)
#    {
#        $response->content($html);
#
#        $conn->send_response($response);
#    }
#    else
#    {
#        $conn->send_error(RC_INTERNAL_SERVER_ERROR);
#    }
#
#    (0);
#}

#-------------------------------------------------------------------------------
# Function:     unixAuthWGroup
# Description:  Check the passed userid and password using the getpwuid function.
#               If they authenticate, then check to see if the user is in one of
#               the specified groups.
# Input Parms:  Userid, Password, Group List (space or comma delimited)
# Output Parms: True | False
#-------------------------------------------------------------------------------
sub unixAuthWGroup
{
    my ($userId,$passwd,$groupList) = @_;

    &unixAuth($userId,$passwd) && &inGroup($userId,$groupList);
}

#-------------------------------------------------------------------------------
# Function:     unixAuth
# Description:  Check the passed userid and password using the getpwuid function
# Input Parms:  Userid, Password
# Output Parms: True | False
#-------------------------------------------------------------------------------
sub unixAuth
{
    my ($userId,$passwd) = @_;

    my $pwd = (getpwnam($userId))[1];

    if (! defined $pwd)
    {
        &log("Invalid user '$userId'");
        (0);
    }
    elsif (crypt($passwd, $pwd) ne $pwd) 
    {
        &log("User '$userId' failed authorization");
        (0);
    } 
    else 
    {
        &log("User '$userId' passed authorization") if ($VERBOSE);
        (1);
    }
}

#-------------------------------------------------------------------------------
# Function:     inGroup
# Description:  See if the passed userid is in the specified group.
# Input Parms:  Userid, Group
# Output Parms: True | False
#-------------------------------------------------------------------------------
sub inGroup
{
    my($userId,$groupList) = @_;
    my($str,$group,$gid,$userList);

    # Load up the list of allowed groups.
    my(@allowedGroupList) = split(/[\s,:]+/,$groupList);

    foreach $group (@allowedGroupList)
    {
        my $memberStr = (getgrnam($group))[3];

        if ($memberStr =~ /\b$userId\b/)
        {
            &log("User '$userId' is in group '$group'") if ($VERBOSE > 1);
            return 1;
        }
    }

    &log("User '$userId' is not in group '$groupList'") if ($VERBOSE);

    (0);    
}

#-------------------------------------------------------------------------------
# Function:     reaper
# Description:  Look for dead child processes and reap them
# Input Parms:  None
# Output Parms: None
#-------------------------------------------------------------------------------
sub reaper
{
    my $waitpid = wait;
    &log("Reaped pid $waitpid") if ($VERBOSE);

    # Store the exit code in a global location
    $::EC = $?;

    # Reinstate the handler
    $SIG{'CHLD'} = \&reaper;
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

1;
__END__

=head1 NAME

VBTK::PHttpd - Generic web server built on the HTTP::Daemon library

=head1 SYNOPSIS

  use VBTK::PHtml;
  use VBTK::PHttpd;

  # Pass most of the parameters on to create a PHttpd object    
  my $phttpd = new VBTK::PHttpd(
    LocalPort    => '80',
    LocalAddr    => undef,
    DocRoot      => '/mydocroot'
  );

  $phttpd->run;

=head1 DESCRIPTION

VBTK::PHttpd is a very simple web server built on the L<HTTP::Daemon|HTTP::Daemon>
library.  It can be setup to fork off a handler for each request, or can be 
run in a single-threaded mode.  It's probably not a good choice for highly scalable
applications, but it works great if you're just trying to add a simple web interface
to a perl application.  It supports various features such as redirection, special
handling of files based on file type, user authentication, etc.  It works especially
well with the L<VBTK::PHtml|VBTK::PHtml> library.

So why use this rather than just setup Apache and PHP?  Well, I decided to do it
this way, because I wanted to add a web interface into an existing perl program
rather than convert it to run under Apache or PHP.  I just think it's simpler this
way and there's less to install.

=head1 METHODS

The following methods are supported

=over 4

=item $httpd = new VBTK::PHttpd (<parm1> => <val1>, <parm2> => <val2>, ...)

The constructor passes many of it's parameters on in a call to HTTP::Daemon.  All of 
these parms will default to a useable value if not specified, except for the 'DocRoot'
parm which is required.  This call initializes the daemon, but does not start it 
listening yet.  The allowed parameters are:

=over 4

=item DocRoot

The directory to be used as the docroot by the web server.  (Required)

=item LocalPort

The TCP port number on which the daemon will start it's web server listening for
requests.  See L<HTTP::Daemon>.  (Defaults to 80)

=item LocalAddr

The IP address to which the daemon will bind itself.  If none is supplied, the
daemon will bind itself to '*'.  (Default is none.)

=item ListenQueue

The size of the listener queue.  See L<HTTP::Daemon> for more details.  (Defaults
to 10)

=item IndexNames

A string containing a comma-separated list of file names to be treated as directory
indexes when a requesting URL specifies a directory.  (Defaults to 
'index.html,index.htm,index.phtml' )

=item Handlers

A pointer to a hash containing pairs of filename patterns and pointers to
subroutines.  This is used to specify alternate sub-routines to handle specific
file types.  (Defaults to { '.phtml$' => \&defaultPHtmlHandler } )  The handler
subroutine will be called whenever there is a match between the URL and the
pattern.  The handler will be passed the following:

  $_[0] - Connection object from HTTP::Daemon
  $_[1] - Request object from HTTP::Daemon
  $_[2] - Full path to file to be handled
  $_[3] - Docroot path for this server
  $_[4] - Pointer to a hash containing name/value pairs for all parameters
          passed in the request.

The handler should then make the appropriate calls to handle the request, form
an HTTP::Response object, and transmit the response.  An example handler, which
simply serves up the file would be something like:

  sub myHandler 
  {
    my($conn,$req,$target,$docRoot,$parms) = @_;

    my $fh = new FileHandle "$target";

    # Check for errors
    unless($fh)
    {
        $conn->send_error(RC_NOT_FOUND);
        return;
    }

    # Slurp mode
    local $/:

    my $html = <$fh>;
    $fh->close;

    # Setup a response object    
    my $resp = new HTTP::Response;
    $response->content($html);

    # Return a response
    $conn->send_response($response);
  }

=item Redirects

A pointer to a hash containing pairs of URL patterns and URL's to redirect to.
This is used when you want to redirect from an old location to a new one.

    Redirects => {
        'oldurl'  => 'newurl',
        'oldurl2' => 'newurl2' },

=item AuthList

A pointer to a hash containing pairs of filename patterns and pointers to 
authentication subroutines.  This is used to restrict access to certain
URL's in your docroot.

    AuthList => {
        'protectedURL1' => \&authSub1,
        'protectedURL2' => \&authSub2 },
        
When the protected URL is accessed, the user will be prompted to enter
a username and password, which will then be passed as $_[0] and $_[1]
respectively to the specified &authSub.  The authSub should then return
true if the user is allowed access, or false if not.  Two pre-defined
&authSub subroutines are provided, unixAuth and unixAuthWGroup.  See 
their descriptions below for more details.

=item AuthRealm

A string containing a message which will be passed to the browser and
displayed to the user when prompting them for their username and password.
(Defaults to 'Perl PHttpd')

    AuthRealm => 'My Server',

=item DontForkList

A string containing a comma-separated list of URL patterns which, if they
match the incoming HTTP request, will cause the server to not fork off 
a child process to handle the request.  Instead, the process will be 
handled in-line.  This is normally used when calling a '.phtml' URL which
changes the value of something in memory, and so you don't want it to fork
or the change won't happen in the right process.  You can also set this
to '.*' if you want to disable forking completely.

    DontForkList => 'setStatus.phtml,changeValue.phtml',

=item ReqTimeout

A number containing the maximum number of seconds to wait for the requestor
to issue their request.  The requestor could be a VBClient process reporting
in or it might be a user's web browser.  This prevents a single hung 
requestor from hanging up the entire server.  (Defaults to 6 seconds).

    ReqTimeout => 6,

=back

=item $httpd->run ( <return_after_sec> )

This call starts the daemon listening for and handling requests.  If a
'return_after_sec' value is supplied, the daemon will return back after
approximately 'return_after_sec' seconds.  This enables the running of
housekeeping tasks on a specified interval.  So an example might be:

  while ( 1 )
  {
    $httpd->run(60);
    &runHousekeepingTasks;
  }

=item unixAuth (<username>,<password>)

This subroutine is provided for use in authenticating users.  It requires the
ability to lookup the user's encrypted unix password via the getpwnam system
call.  So it probably won't work unless you're running NIS.  Returns true if
the user was successfully authenticated, false otherwise.

=item unixAuthWGroup (<username>,<password>,<comma-separated-group-list>)

Same as 'unixAuth', but it also checks that the user is one of the groups
in the specified 'comma-separated group list'.

=back

=head1 SEE ALSO

L<HTTP::Daemon|HTTP::Daemon>,
L<VBTK::PHtml|VBTK::PHtml>

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

