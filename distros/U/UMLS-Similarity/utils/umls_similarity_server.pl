#!/usr/bin/perl -wT

# umls_similarity_server.pl version 0.01
# (Last updated $Id: umls_similarity_server.pl,v 1.16 2013/04/16 23:29:40 btmcinnes Exp $)
#
# ---------------------------------------------------------------------

# Include external packages
use strict;
use Getopt::Long;
use File::Temp;
use File::Spec;
use UMLS::Similarity;
use POSIX ':sys_wait_h';  # for waitpid() and friends; used by reaper()
use POSIX qw(setsid);     # to daemonize

my $doc_base = '/var/www/umls_similarity';

# Get the command-line options
our($opt_port, $opt_logfile, $opt_maxchild, $opt_version, $opt_help);
&GetOptions("port=i", "logfile=s", "maxchild=i", "version",  "help");

# Check for version
if(defined($opt_version))
{
  print "umls_similarity_server.pl version 0.01\n";
  print "UMLS::Similarity version ".($UMLS::Similarity::VERSION)."\n";
  print "Copyright (c) 2010-2011, Ted Pedersen, Bridget McInnes\n";
  exit;
}

# Check for help
if(defined($opt_help))
{
  print "Usage: umls_similarity_server.pl [--port PORTNUMBER] [--logfile LOGFILE] [--maxchild NUM] \n";

  print "                            | --help\n";
  print "                            | --version\n";

  print "\nStarts the similarity server, which listens for requests on a predefined\n";
  print "port. It presents a network interface to the UMLS::Similarity modules.\n\n";
  print "Options:\n";

  print "--port        Specify the port PORTNUMBER for the server to listen on.\n";
  print "--logfile     The output LOGFILE where any error or warning messages\n";
  print "              should be written out.\n";
  print "--maxchild    Specify the maximum number NUM of the processes that should\n";
  print "              be forked to handle the requests.\n";
  print "--help        Display this help message and quit.\n";
  print "--version     Display the version information and quit.\n";
  exit;
}

# Local variables
my $localport = 31135;
my $error_log = undef;
my $maxchild = 4; # max number of child processes at one time
sub reaper;

# Set the log file, if specified
$error_log = $1 if(defined($opt_logfile) and $opt_logfile ne "" and $opt_logfile =~ /^(.*)$/);
print STDERR "Error log = ".($error_log?$error_log:"<none>")."\n";

# Set the port
$localport = $opt_port if(defined($opt_port));
print STDERR "Local port = $localport\n";

# Set the maxchild
$maxchild = $opt_maxchild if(defined($opt_maxchild));
print STDERR "Maxchild = $maxchild\n";

# Create the temporary lock file
my $lockfh = File::Temp->new();
my $lock_file = $lockfh->filename();
die "Error: Unable to create temporary lock file.\n" if(!$lockfh);
print $lockfh $$;
close $lockfh or die "Error: Cannot close lock file: $! \n";
print STDERR "Loading modules... ";

# prototypes:
sub getAllForms ($ $);
sub getAllDefForms ($ $);
sub getlock ();
sub releaselock ();
sub timestamp ($);

use sigtrap handler => \&bailout, 'normal-signals';
use IO::Socket::INET;

use UMLS::Interface;
use UMLS::Similarity::path;
use UMLS::Similarity::lch;
use UMLS::Similarity::wup;
use UMLS::Similarity::res;
use UMLS::Similarity::lin;
use UMLS::Similarity::jcn;
use UMLS::Similarity::cdist;
use UMLS::Similarity::nam;
use UMLS::Similarity::zhong;
use UMLS::Similarity::vector;
use UMLS::Similarity::lesk;
use UMLS::Similarity::random;

# reset (untaint) the PATH
$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
print STDERR "done.\n";
print STDERR "Starting server... going into background.\n";

# Daemonize
open STDIN, '/dev/null' or die "Can't read /dev/null: $! \n";
open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $! \n";

# The is the socket we listen to
my $socket = IO::Socket::INET->new(
  LocalPort => $localport,
  Listen => SOMAXCONN,
  Reuse => 1,
  Type => SOCK_STREAM
) or die "Could not bind to network port: $! \n";
print STDERR "Closing output to terminal.\n";

if(defined($error_log))
{
  print STDERR "All future messages will be routed to the log file.\n";
  if(!open(STDERR, '>>', $error_log))
  {
    print "Error: Could open error log.\n";
    die "Error: Could not re-open STDERR.\n";
  }
  chmod 0664, $error_log;
}
else
{
  print STDERR "No more messages will be printed (even if the server dies).\n";
  open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $! \n";
}

chdir '/' or die(&timestamp("Can't chdir to /: $! \n"));
defined(my $pid = fork) or die(&timestamp("Can't fork: $! \n"));
exit if $pid;
setsid or die(&timestamp("Can't start a new session: $! \n"));
umask 0;

my %option_hash = ();

our $interface;
our $path;
our $lch;
our $wup;
our $res;
our $lin;
our $jcn;
our $nam;
our $zhong;
our $cdist;
our $vector;
our $lesk;
our $random;

my @measures = ();

&setInterface("MSH", "PAR/CHD", "path");


# this variable is incremented after every fork, and is
# updated by reaper() when a child process dies
my $num_children = 0;
## SEE BELOW
# automatically reap child processes
#$SIG{CHLD} = 'IGNORE';
##
## BETTER WAY:
# handle death of child process
$SIG{CHLD} = \&reaper;
my $interrupted = 0;
ACCEPT:

while((my $client = $socket->accept) or $interrupted)
{
  $interrupted = 0;
  next unless $client; # a SIGCHLD was raised

  # check to see if it's okay to handle this request
  if($num_children >= $maxchild)
  {
    print $client "busy\015\012";
    $client->close;
    undef $client;
    next ACCEPT;
  }
  my $childpid;

  # fork; let the child handle the actual request
  if($childpid = fork)
  {

    # This is the parent
    $num_children++;

    # go wait for next request
    undef $client;
    next ACCEPT;
  }

  # This is the child process
  defined $childpid or die(&timestamp("Could not fork: $! \n"));

  # here we're the child, so we actually handle the request
  my @requests;
  while(my $request = <$client>)
  {
    last if $request eq "\015\012";
    push @requests, $request;
  }
  foreach my $i (0..$#requests)
  {
    my $request = $requests[$i];
    my $rnum = $i + 1;
    my $type = 'UNDEFINED';
    if($request =~ m/^(\w)\b/)
    {
      $type = $1;
    }
    else
    {
      $type = 'UNDEFINED';
    }

    print STDERR "TYPE: $type\n";
    
    if($type eq 't') { 
	
	my (undef, $cui) = split/\|/, $request;
	my $preferred = "";
	if($cui=~/C0000000/) { 
	    $preferred = "UMLS_ROOT";
	}
	else {
	    print STDERR "CUI: $cui\n";
	    $preferred = $interface->getAllPreferredTerm($cui); 
	}
	
        $preferred=~s/\s+/ /g;
        $preferred=~s/^\s+//g;
        $preferred=~s/\s+$//g;
        $preferred=~s/\s/_/g;

	print $client "t $cui $preferred\015\012";
    }

    elsif($type eq 'v')
    {
      eval{
        # get version information
        my $u_version = $interface->version();
	my $i_version = $UMLS::Interface::VERSION;
	my $s_version = $UMLS::Similarity::VERSION;
        print $client "v UMLS $u_version\015\012";
        print $client "v UMLS::Interface $i_version\015\012";
        print $client "v UMLS::Similarity $s_version\015\012";
      };
      print(STDERR &timestamp("$@\n")) if($@);
    }
    elsif($type eq 'r')
    {
	my (undef, $word1, $word2, $button, $measure, $sab, $rel)= split /\|/, $request;

	print STDERR "$word1 $word2 $button $measure $sab $rel\n";

	&setInterface($sab, $rel, $measure);

	unless(defined $word1 and defined $word2)
	{
	    print $client "! Error: undefined input words\015\012";
	    sleep 2;
	    goto EXIT_CHILD;
	}
	my $module;
	if($measure =~ /^(?:path|lch|wup|res|lin|jcn|nam|zhong|cdist|lesk|vector|random)$/){
	    no strict 'refs';
	    $module = $$measure;
	    unless(defined $module) {
		print $client "! Error: Couldn't get reference to measure\015\012";
		sleep 2;
		goto EXIT_CHILD;
	    }
	}
	else
	{
	    print $client "! Error: no such measure $measure\015\012";
	    sleep 2;
	    goto EXIT_CHILD;
	}
	
	my @wps1 = ();
	my @wps2 = ();

	if($button eq "Compute Similarity") { 
	    @wps1 = getAllForms($word1, $interface);
	    @wps2 = getAllForms($word2, $interface);
	}
	else { 
	    @wps1 = getAllDefForms($word1, $interface);
	    @wps2 = getAllDefForms($word2, $interface);
	}

	unless(scalar @wps1) {
	    print $client "! $word1 was not found in $sab\015\012";
	    goto EXIT_CHILD;
	}
	unless(scalar @wps2) {
	    print $client "! $word2 was not found in $sab\015\012";
	    goto EXIT_CHILD;
	}
	
	getlock;
	foreach my $wps1 (@wps1)
	{
	    foreach my $wps2 (@wps2)
	    {
		eval{
		    my $score = $module->getRelatedness($wps1, $wps2);
		    print $client "r $measure $wps1 $wps2 $score\015\012";
		};
		
		print(STDERR &timestamp("$@\n")) if($@);
	    }
	}
	releaselock;
	
	getlock;
    }
    elsif($type eq 'g') { 

	my (undef, $button, $word) = split/\|/, $request;

	print STDERR "HERE ($button) g ($word)\n";	
	my @cuis = ();
	if($word =~/[Cc][0-9]+/) { 
	    push @cuis, uc($word);
	}
	else {
	    if($button eq "Compute Similarity") { 
		@cuis = getAllForms($word, $interface);
	    }
	    else { 
		@cuis = getAllDefForms($word, $interface);
	    }
	    print STDERR "CUIS: @cuis\n";
	}
	foreach my $cui (@cuis) { 
	    my $defs = $interface->getCuiDef($cui, 1);
	    my $string = "";
	    foreach my $def (@{$defs}) { 
		my @array = split/\s+/, $def;
		my $sab = shift @array;
		$string .= "$sab : @array|";
	    }
	    print $client "g $cui $string\015\012";
	    print STDERR "g $cui $string\n";
	}
    }
    elsif($type eq 'p') { 
	
	my (undef, $word1, $word2) = split/\|/, $request;
	
	my @cuis1 = ();
	if($word1 =~/[Cc][0-9]+/) { 
	    push @cuis1, uc($word1);
	}
	else {
	    @cuis1 = getAllForms($word1, $interface);
	}

	my @cuis2 = ();
	if($word2 =~/[Cc][0-9]+/) { 
	    push @cuis2, uc($word2);
	}
	else {
	    @cuis2 = getAllForms($word2, $interface);
	}

	my $string = "";
	foreach my $cui1 (@cuis1) { 
	    my $t1 = $interface->getAllPreferredTerm($cui1);
	    foreach my $cui2 (@cuis2) {
		my $t2 = $interface->getAllPreferredTerm($cui2);
		my $paths = $interface->findShortestPath($cui1, $cui2);
		print STDERR "HERE: $cui1 $t1 $cui2 $t2\n";
		foreach my $path (@{$paths}) { 
		    my @array = split/\s+/, $path;
		    $string .= "$cui1 ($t1)|$cui2 ($t2)|";
		    foreach my $i (0..$#array) {
			my $concept = $array[$i];
			my $t = $interface->getAllPreferredTerm($concept); 
			$string.= "$concept ($t) => "; 
		    }
		    chop $string; chop $string; chop $string; chop $string;
		    $string .= "|"
		} 
	    }
	}
	chop $string;
	print $client "p $string\015\012";
	print STDERR "p $string\n";
    }
    else
    {
	print $client "! Bad request type `$type'\015\012";
    }
  }
  
  # Terminate ALL messages with CRLF (\015\012).  Do NOT use
  # \r\n (the meaning of \r and \n varies on different platforms).
 EXIT_CHILD:
  print $client "\015\012";
  $client->close;
  $socket->close;
  
  # don't let the child accept:
  exit;
}
$socket->close;
exit;

sub setInterface {
    
    my $sab     = shift;
    my $rel     = shift;
    my $measure = shift;

    %option_hash = ();

    my @rels = split/\//, $rel;
    my $rstring = join ", ", @rels;
    
    print STDERR "In setInterface($sab, $rel, $measure)\n";

    ## create config file
    my $fh = File::Temp->new();
    my $cfg = $fh->filename();
    die "Error: Unable to create temporary config file.\n" if(!$fh);

    if($measure=~/lesk|vector/) { 
	print $fh "SABDEF :: include $sab\n";
	print $fh "RELDEF :: include $rstring\n";
    }
    else {
	print $fh "SAB :: include $sab\n";
	print $fh "REL :: include $rstring\n";
    }
    close $fh or die "Error: Unable to close config file.\n";

    print STDERR "FILENAME: $cfg\n";

    #  set the information content default files
    my %ic_options = ();
    my $relname = join ".", @rels;
    my $sabname = lc($sab);
    $relname = lc($relname);
    my $icfilename = "icprop.$sabname.$relname";
    $ic_options{"icpropagation"} = "$doc_base/icpropagation/$icfilename";
    
    #  set the vector default files
    my %vector_options = ();
    $vector_options{"vectormatrix"} = "$doc_base/vectorfiles/mtx.remove75.uremove1k";
    $vector_options{"vectorindex"}  = "$doc_base/vectorfiles/idx.remove75.uremove1k";
    
    $option_hash{"config"} = $cfg;
    #$option_hash{"debug"} = 1;
    $option_hash{"forcerun"} = 1;

    $interface = UMLS::Interface->new(\%option_hash);

    if($measure=~/path|lch|wup|res|lin|jcn|nam|zhong|cdist|random/) { 
	print STDERR "Setting measures\n";
	
	$path   = UMLS::Similarity::path->new($interface);
	$lch    = UMLS::Similarity::lch->new($interface);
	$wup    = UMLS::Similarity::wup->new($interface);
	$res    = UMLS::Similarity::res->new($interface, \%ic_options);
	$lin    = UMLS::Similarity::lin->new($interface, \%ic_options);
	$jcn    = UMLS::Similarity::jcn->new($interface, \%ic_options);
	$nam    = UMLS::Similarity::nam->new($interface);
	$zhong  = UMLS::Similarity::zhong->new($interface);
	$cdist  = UMLS::Similarity::cdist->new($interface);
	$random = UMLS::Similarity::random->new($interface);
    }
    if($measure=~/lesk|vector/) { 
	$lesk   = UMLS::Similarity::lesk->new($interface);
	$vector = UMLS::Similarity::vector->new($interface, \%vector_options);
    }

    @measures = ($path, $wup, $lch, $res, $lin, $jcn, $nam, $zhong, $cdist, $lesk, $vector, $random);
}

sub getCuis {
    my $word = shift;

    my $forms = undef;

    # check if the string is a CUI just use it
    if($word =~ m/C[0-9]+/) { push @{$forms}, $word; }
    
    # otherwise find the CUIs
    else {
	getlock;
	my @temp = $interface->getConceptList($word);
	eval{$forms = $interface->getConceptList($word);};
	print(STDERR &timestamp("$@\n")) if($@);
	releaselock;
	return () unless scalar @{$forms};	 
    }
    #  return the forms
    return @{$forms};
}

sub getAllForms ($ $)
{
    my $word = shift;
    my $umls = shift;
    
    print STDERR "In getAllForms ($word)\n";

    my $forms = undef;

    
    # check if the string is a CUI just use it
    if($word =~ m/[cC][0-9]+/) { $word = uc($word); push @{$forms}, $word; }
    
    # otherwise find the CUIs
    else {
	getlock;
	eval{$forms = $umls->getConceptList($word);};
	print STDERR "Forms ($word) : @{$forms}\n";
	print(STDERR &timestamp("$@\n")) if($@);
	releaselock;
	return () unless scalar @{$forms};	 
    }
    #  return the forms
    print STDERR "Returning Forms ($word) : @{$forms}\n";
    return @{$forms};
}

sub getAllDefForms ($ $)
{
    my $word = shift;
    my $umls = shift;
    
    print STDERR "In getDefAllForms ($word)\n";

    my $forms = undef;
    
    # check if the string is a CUI just use it
    if($word =~ m/[cC][0-9]+/) { $word = uc($word); push @{$forms}, $word; }
    
    # otherwise find the CUIs
    else {
	getlock;
	eval{$forms = $umls->getDefConceptList($word);};
	print STDERR "Forms ($word) : @{$forms}\n";
	print(STDERR &timestamp("$@\n")) if($@);
	releaselock;
	return () unless scalar @{$forms};	 
    }
    #  return the forms
    print STDERR "Returning Forms ($word) : @{$forms}\n";
    return @{$forms};
}


# A signal handler, good for most normal signals (esp. INT).  Mostly we just
# want to close the socket we're listening to and delete the lock file.
sub bailout
{
  my $sig = shift;
  $sig = defined $sig ? $sig : "?UNKNOWN?";
  $socket->close if defined $socket;
  print(STDERR &timestamp("Bailing out (SIG$sig).\n"));
  releaselock if($lockfh);
  exit 1;
}
use Fcntl qw/:flock/;

# gets a lock on $lockfh.  The return value is that of flock.
sub getlock ()
{
  open($lockfh, '>>', $lock_file) or die(&timestamp("Cannot open lock file $lock_file: $! \n"));
  eval{flock $lockfh, LOCK_EX;};
  print(STDERR &timestamp("$@\n")) if($@);
}

# releases a lock on $lockfh.  The return value is that of flock.
sub releaselock ()
{
  eval{
    flock $lockfh, LOCK_UN;
    close $lockfh;
  };
  print(STDERR &timestamp("$@\n")) if($@);
}

# attach a time stamp
sub timestamp ($)
{
  my $instring = shift;
  return $instring if(!defined($instring));
  my @monthNames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear) = localtime();
  my $year = 1900 + $yearOffset;
  return "["."$dayOfMonth/$monthNames[$month]/$year:$hour:$minute:$second"."] $instring";
}

# sub to reap child processes (so they don't become zombies)
# also updates the num_children variable
#
# Sub was loosely inspired by an example at
# http://www.india-seo.com/perl/cookbook/ch16_20.htm
sub reaper
{
  my $moribund;
  if(my $pid = waitpid(-1, WNOHANG) > 0)
  {
    $num_children-- if WIFEXITED($?);
  }
  $interrupted = 1;
  $SIG{CHLD} = \&reaper; # cursed be SysV
}

__END__

=head1 NAME

umls_similarity_server.pl - [Web] The backend UMLS::Similarity server for the Web Interface

=head1 SYNOPSIS

Usage: umls_similarity_server.pl [--port PORTNUMBER] [--logfile LOGFILE] [--maxchild NUM] 
                            | --help
                            | --version


=head1 DESCRIPTION

This script implements the backend of the web interface for UMLS::Similarity.

This script listens to a port waiting for a request form similarity.cgi or
wps.cgi.  The client script sends a message to this script as series of
queries (see QUERY FORMAT).  After all the queries, the client sends a
message containing only CRLF (carriage-return line-feed, or \015\012).

The server (this script) responds with the results (see MESSAGE FORMAT)
terminated by a message containing only CRLF.

=head2 Example:

 Client:
 g car#n#1CRLF
 CRLF

 Sever responds:
 g car#n#1 4-wheeled motor vehicle; usually propelled by an internal
 combustion engine; "he needs a car to get to work"CRLF
 CRLF

=head1 OPTIONS

B<--port>=I<PORTNUMBER>
    Specify the port PORTNUMBER for the server to listen on.

B<--logfile>=I<LOGFILE>
    The output LOGFILE where any error or warning messages should be
    written out.

B<--maxchild>=I<NUM>
    Specify the maximum number NUM of the processes that should be forked
    to handle the requests.

B<--help>
    Display the help message and quit.

B<--version>
    Display the version information and quit.

=head1 QUERY FORMAT

<CRLF> means carriage-return line-feed "\r\n" on Unix, "\n\r" on Macs,
\015\012 everywhere and anywhere (i.e., don't use \n or \r, use \015\012).

The queries consist of messages in the following formats:

 s <word1> <word2><CRLF> - server will return all senses of word1 and
 word2

 g <word><CRLF> - server will return the gloss for each synset to which
 word belongs

 r <wps1> <wps2> <measure> <etc...><CRLF> - server will return the
 relatedness of wps1 and wps2 using measure.

 v <CRLF> - get version information

=head1 MESSAGE FORMAT

The messages sent from this server will be in the following formats:

 ! <msg><CRLF> - indicates an error or warning

 g <wps> <gloss><CRLF> - the gloss of wps

 r <wps1> <wps2> <score><CRFL> - the relatedness score of wps1 and wps2

 t <msg><CRLF> - the trace output for the previous relatedness score

 s <wps1> <wps2> ... <wpsN><CRLF> - a synset

 v <package> <version number><CRLF> - the version of 'package' being used

=head1 BUGS

Report to UMLS::Similarity mailing list :
 L<http://groups.yahoo.com/group/umls-similarity>

=head1 SEE ALSO

L<UMLS::Similarity>

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Bridget T McInnes
 bthomson at umn.edu

 Jason Michelizzi

=head1 COPYRIGHT

Copyright (c) 2005-2011, Ted Pedersen, Jason Michelizzi and 
Bridget T McInnes

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to: 

    The Free Software Foundation, Inc., 
    59 Temple Place - Suite 330, 
    Boston, MA  02111-1307, USA.

=cut
