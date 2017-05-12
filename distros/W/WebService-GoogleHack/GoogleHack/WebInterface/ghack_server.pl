#!/usr/local/bin/perl 
=head1 GoogleHack web interface server

=head1 SYNOPSIS

ghack_server.pl acts as a server to which the web interface connects to for all user queries.
The server then retrieves the results of the queries and sends it back to the web interface.

=head1 DESCRIPTION

To install the server please follow these steps:

1) Change the following variables accordingly:

The localport should be a number above 1024, and less than around 66,000. Make
 sure that localport number is the same on both the client and server side.

$LOCALPORT = XXXXX;

Next, change the the path to the GoogleHack/Temp directory eg, /home/username/WebService/GoogleHack/Temp/

$ghackDir="/home/username/WebService/GoogleHack/Temp/";

Next, update the Google-Hack configuration file path, to eg /home/username/WebService/GoogleHack/Datafiles/initconfig.txt

$configFile="/home/username/WebService/GoogleHack/Datafiles/initconfig.txt";


2)If your ghack server is running behind a firewall, you will need to
edit the file /etc/sysconfig/iptables to allow clients to connect to the machine through the port you had given.  There is a line that looks like this:

-A RH-Firewall-1-INPUT -p tcp --dport XXXXX -j ACCEPT

Where XXXXX is the port that your client will be connecting to (the value of $localport in ghack_server.pl).

Now start the server by running the ghack_server.pl as you would run a 
regular perl file.

=head1 AUTHOR

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt> 

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt> 

Jason Michelizzi, E<lt>mich0212@d.umn.eduE<gt> 

Date 11/08/2004

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Pratheepan Raveendranathan, Ted Pedersen, Jason Michelizzi

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

use strict;

# The port through which the client would connect
# said another the way, the port in which the server will be listening
# for requests

my $LOCALPORT = 32983;

# The path to the GoogleHack/Temp directory
# /home/username/WebService/GoogleHack/Temp/

my $GHACKDIR="";

# This would be the Google-Hack configuration file
# /home/username/WebService/GoogleHack/Datafiles/initconfig.txt

my $CONFIGFILE="";


my $lock_file = "ghack_server.lock";
my $error_log = "error.log";

my $lockfh;
{
    if (-e $lock_file) {
	die "Lock file `$lock_file' already exists.  Make sure that another\n",
	    "instance of $0 isn't running, then delete the lock file.\n";
    }
    open ($lockfh, '>', $lock_file)
      or die "Cannot open lock file `$lock_file' for writing: $!";
    print $lockfh $$;
    close $lockfh or die "Cannot close lock file `lock_file': $!";
}
END {
    if (open FH, '<', $lock_file) {
	my $pid = <FH>;
	close FH;
	unlink $lock_file if $pid eq $$;
    }
}


# prototypes:
sub getlock ();
sub releaselock ();

use sigtrap handler => \&bailout, 'normal-signals';
use IO::Socket::INET;
use SOAP::Lite;
use WebService::GoogleHack;

# automatically reap child processes
$SIG{CHLD} = 'IGNORE';

# re-direct STDERR from wherever it is now to a log file
close STDERR;
open (STDERR, '>', $error_log) or die "Could not re-open STDERR";
chmod 0664, $error_log;


# The is the socket we listen to
my $socket = IO::Socket::INET->new (LocalPort => $LOCALPORT,
				    Listen => SOMAXCONN,
				    Reuse => 1,
				    Type => SOCK_STREAM
				   ) or die "Could not be a server: $!";

print "SERVER started on port $LOCALPORT "; 

my $search = new WebService::GoogleHack;

$search->initConfig("$CONFIGFILE");
$search->printConfig(); 

#my @terms=();
#push(@terms,"rachel");
#push(@terms,"ross");
#my $resultssss=$search->wordClusterInPage(\@terms,10,20,1,"results.txt","true");


ACCEPT:
while (my $client = $socket->accept) {
    my $childpid;
    if ($childpid = fork) {
	# we're the parent here, so we just go wait for the next request
	next ACCEPT;
    }

    defined $childpid or die "Could not fork: $!";

    # here we're the child, so we actually handle the request
    my @requests;
    while (my $request = <$client>) {
	last if $request eq "\015\012";
	push @requests, $request;
    }

    foreach my $i (0..$#requests) {

        my $request = $requests[$i];
	my $rnum = $i + 1;
	$request =~ m/^(\w)\b/;
	my $type = $1 || 'UNDEFINED';
	my $query=$request;

	print $type."\n";
	print $query;
	print "\n\n";

	if ($type eq 'v') {
	    # get version information
# Configuration
	    my $key   = "iROSyfxQFHKjtA1CLcVQ3aGawqQW2j2Q"; 

# Initialise with local SOAP::Lite file
	    my $service = SOAP::Lite-> service('http://www.d.umn.edu/~rave0029/GoogleSearch.wsdl');
	    
	    my $search_query1= "dulut";
	    
	    
	    my $correction = $service->doSpellingSuggestion($key,$search_query1);
	    
	    print $client "Answer Here $search_query1, $correction\015\012";
	    print $client "\015\012";
	    goto EXIT_CHILD;
	}
	elsif ($type eq 'c')
	{		   
	    #print $client "$search->printConfig()";

	    my ($dummy,$key,$searchString,$numResults,$cutOffs,$numIterations)= split(/\t/, $query);
	    my @terms=();
	    
	    print "\n Key is $key ";

	    my @temp= split(/:/, $searchString);
	    
	    foreach my $word (@temp)
	    {
	       if($word ne "")
	       {
		   push(@terms,$word);
	       }
	   
	    }
	    print "$numResults,$cutOffs,$numIterations";
	    print $terms[0]."\n".$terms[1];;

	    $search->{'Key'}="$key";
	    my $results=$search->wordClusterInPage(\@terms,$numResults,$cutOffs,$numIterations,"results.txt","true");	 
	    print $client "$results";
	    print $client "\015\012";
	}
	elsif ($type eq 'g')
	{		   
	    #print $client "$search->printConfig()";

	    my ($dummy,$key,$searchString,$numResults,$cutOffs,$numIterations,$scoreType,$scoreCutOff)= split(/\t/, $query);
	    my @terms=();
	    
	    print "\n Key is $key ";

	    my @temp= split(/:/, $searchString);
	    
	    foreach my $word (@temp)
	    {
	       if($word ne "")
	       {
		   push(@terms,$word);
	       }
	   
	    }
	    print "$numResults,$cutOffs,$numIterations,$scoreType,$scoreCutOff";
	    print $terms[0]."\n".$terms[1];;

	    $search->{'Key'}="$key";
	    my $results=$search->Algorithm2(\@terms,$numResults,$cutOffs,5,$numIterations,$scoreType,$scoreCutOff,"results.txt","true");	 
	    print $client "$results";
	    print $client "\015\012";
	}
	elsif ($type eq 'p')
	{		   
	    #print $client "$search->printConfig()";
	    my ($dummy,$key,$searchString1,$searchString2)= split(/\t/, $query); 
	    
	    print "\n Key is $key";
	    
	    $search->{'Key'}="$key";
	    my $results=$search->measureSemanticRelatedness($searchString1,$searchString2);
	 

	    print $client "$results";
	    print $client "\015\012";
	}
	  elsif ($type eq 'r')
        {
            #print $client "$search->printConfig()";
            my ($dummy,$key,$review,$positive,$negative)= split(/\t/, $query);
	    $review=~s/\#+/ /g;
	    my $filename=$GHACKDIR."temp.txt";
	    open(DAT,">$filename") || die("Cannot Open $filename to write");
	    print DAT $review;
	    close(DAT);
	    $search->{'Key'}="$key";
	    print "\n the review is $review";
	    print "\n Predict Review Request $positive $negative\n"; 
            my $results=$search->predictSemanticOrientation($filename,$positive,$negative,"trace.txt");
            print $client "$results";
            print $client "\015\012";
        }
	  elsif ($type eq 's')
        {
            #print $client "$search->printConfig()";
            my ($dummy,$key,$review,$positive,$negative)= split(/\t/, $query);
	    $review=~s/\#+/ /g;
	    my $filename=$GHACKDIR."temp.txt";
	    open(DAT,">$filename") || die("Cannot Open $filename to write");
	    print DAT $review;
	    close(DAT);
	    $search->{'Key'}="$key";
	    print "\n the review is $review";
	    print "\n Predict Review Request $positive $negative\n"; 
            my $results=$search->predictWordSentiment($filename,$positive,$negative,"true");
            print $client "$results";
            print $client "\015\012";
        }
	elsif ($type eq 'h')
        {
            #print $client "$search->printConfig()";
            my ($dummy,$key,$review,$positive,$negative)= split(/\t/, $query);
	    $review=~s/\#+/ /g;
	    my $filename=$GHACKDIR."temp.txt";
	    open(DAT,">$filename") || die("Cannot Open $filename to write");
	    print DAT $review;
	    close(DAT);
	    $search->{'Key'}="$key";
	    print "\n the review is $review";
	    print "\n Predict Review Request $positive $negative\n"; 
            my $results=$search->predictPhraseSentiment($filename,$positive,$negative,"true");
            print $client "$results";
            print $client "\015\012";
        }
	else {
	    print $client "! Bad request type `$type'\015\012";
	}
    }

    # Terminate ALL messages with CRLF (\015\012).  Do NOT use
    # \r\n (the meaning of \r and \n varies on different platforms).
    print $client "\015\012";

 EXIT_CHILD:
    $client->close;
    $socket->close;

    # don't let the child accept:
    exit;
}

$socket->close;
exit;

# A signal handler, good for most normal signals (esp. INT).  Mostly we just
# want to close the socket we're listening to and delete the lock file.
sub bailout
{
    my $sig = shift;
    $sig = defined $sig ? $sig : "?UNKNOWN?";
    $socket->close if defined $socket;
    print STDERR "Bailing out (SIG$sig)\n";
    releaselock;
    unlink $lock_file;
    exit 1;
}


use Fcntl qw/:flock/;

# gets a lock on $lockfh.  The return value is that of flock.
sub getlock ()
{
    open $lockfh, '>>', $lock_file
	or die "Cannot open lock file $lock_file: $!";
    flock $lockfh, LOCK_EX;
}

# releases a lock on $lockfh.  The return value is that of flock.
sub releaselock ()
{
    flock $lockfh, LOCK_UN;
    close $lockfh;
}

__END__

