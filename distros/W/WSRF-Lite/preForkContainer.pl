#! /usr/bin/perl -w 
#
#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#

use HTTP::Daemon;
use WSRF::Lite;
use POSIX;
use File::Temp;
use WSRF::SSLDaemon;

$ENV{PATH}= "";

#$ENV{'WSRF_MODULES'} = "/tmp/WSRF-Lite/modules";

#Check that the path to the Grid Service Modules is set
if ( !defined($ENV{'WSRF_MODULES'}) )
{
  die "Enviromental Variable WSRF_MODULES not defined";
}


# This is our lock file - we use File::Temp because POSIX::tmpnam is bad!!
# The UNLINK option means the file will be destroyed on exit.
my $file = new File::Temp();

print "Temp File= $file\n";


#ignore broken pipes
$SIG{PIPE} = 'IGNORE';

#create the Service Container - just a Web Server
#my $server = HTTP::Daemon->new(
#    			        LocalPort => '50000',
#			        Listen => SOMAXCONN, 
#    			        Reuse => 1				
#    			      ) || die "ERROR $!\n";

   my $server = WSRF::SSLDaemon->new(
                                LocalPort => '50000',
                                Listen => SOMAXCONN, 
                                Reuse => 1,
                                SSL_key_file => '/home/zzcgumk/.globus/hostkey.pem',
                                SSL_cert_file => '/home/zzcgumk/.globus/hostcert.pem',
                                SSL_ca_file => '/etc/grid-security/certificates/01621954.0',
                                SSL_verify_mode => 0x00
				 ) || die "ERROR $!\n";




#Store the Container Address in the ENV variables - child
#processes can then pick it up and use it
$ENV{'URL'} = $server->url;



#Global Variables
$PREFORK                = 10;        # number of children to maintain
$MAX_CLIENTS_PER_CHILD  = 1000;     # number of clients each child should process
%children               = ();       # keys are current child process IDs
$children               = 0;        # current number of children


sub REAPER {                        # takes care of dead children
    local $!;
    while( defined( my $pid = waitpid(-1,POSIX::WNOHANG()) ) ) 
    { 
      last unless $pid > 0;
      $children --;
      print "Child $pid died\n";
      delete $children{$pid};
    }  
    $SIG{CHLD} = \&REAPER;
}

$SIG{PIPE} = 'IGNORE';

sub HUNTSMAN {                      # signal handler for SIGINT
    local($SIG{CHLD}) = 'IGNORE';   # we're going to kill our children
    foreach my $key ( keys %children) 
    {  
      print "  Killing $key\n";
      kill 'INT' => $key;
    }
    exit;                           # clean up with dignity
}

    
# Fork off our children.
for (1 .. $PREFORK) {
    make_new_child();
}

# Install signal handlers.
$SIG{CHLD} = \&REAPER;
$SIG{INT}  = \&HUNTSMAN;

# And maintain the population.
while (1) {
    sleep;                          # wait for a signal (i.e., child's death)
    for ($i = $children; $i < $PREFORK; $i++) {
        make_new_child();           # top up the child pool
    }
}

print "\nContainer Contact Address: ", $server->url, "\n";

sub make_new_child {
    my $pid;
    my $sigset;
    
    # block signal for fork
    $sigset = POSIX::SigSet->new(SIGINT);
    sigprocmask(SIG_BLOCK, $sigset)
        or die "Can't block SIGINT for fork: $!\n";
    
        
    die "fork: $!" unless defined ($pid = fork);
    
    if ($pid) {
        # Parent records the child's birth and returns.
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die "Can't unblock SIGINT for fork: $!\n";
        $children{$pid} = 1;
        $children++;
	print "Parent $$ created Client handler - $pid\n";
        return;
    } else {
        # Child can *not* return from this subroutine.
        $SIG{INT} = 'DEFAULT';      # make SIGINT kill us as it did before
    
        # unblock signals
        sigprocmask(SIG_UNBLOCK, $sigset)
            or die "Can't unblock SIGINT for fork: $!\n";
    
        # handle connections until we've reached $MAX_CLIENTS_PER_CHILD
        for ($i=0; $i < $MAX_CLIENTS_PER_CHILD; $i++) {
	    my ($client);

#	    local *LOCK;
#	    open(LOCK,"$file") or die "Cannot open lock file $file\n";
#	    flock(LOCK,Fcntl::LOCK_EX()) or die "Couldn't get lock on file $file\n";
	   
            print "$$ got lock\n";
	    $client = $server->accept(); 

#	    flock(LOCK,Fcntl::LOCK_UN());   
            next if $!{EINTR};
	    next if !$client;	
	    print "$$ client= $client\n";    
	    
	    my $resp = WSRF::Container::handle($client->get_request);
	    my $result = $client->send_response($resp);
	    print "result= $result\n";
			    
	    print "closing <$client>\n";
	    $client->close;
	    undef $client;
        }
    
        exit;
    }
}

