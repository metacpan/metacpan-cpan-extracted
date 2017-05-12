#!/usr/bin/perl
#
# usage: start-remote-servers.pl [-s server-script] [clients...]
#
# starts all clients every 30 minutes
#

use FindBin qw($Bin);

$ALARM=5;                 # give up after 5 seconds trying to make a connection

my $RSH="ssh -q -f";             # remote shell
my $PERL='perl';                 # perl-interpreter
my $SRV="$Bin/uplug-server.pl";  # server script (may be changed with -s)


@CLIENTS=                        # list of clients
    qw ();

while ($ARGV[0]=~/^\-/){      # get program arguments
    my $o=shift @ARGV;        # option
    if ($o eq '-s'){          # -s .... set server script
	$SRV=shift (@ARGV);
    }
}
if (@ARGV){                   # all other arguments are names of clients!
    push (@CLIENTS,@ARGV);
}



################ main loop


my $count=0;
while (not -e $stop){
    if ($count){sleep(1);$count--;next;}
    foreach (@CLIENTS){
	print "start client $_!\n";

	# start a perl-script for setting an alarm signal
	# something like:
	# perl -e 'alarm(5);system("ssh -f ...");'

	system("$PERL -e 'alarm($ALARM);system(\"$RSH $_ \\\"$SRV\\\"\");'");
    }
    $count=1800;
}

