package Xymon::Monitor::Informix;


use DBI;
use DBD::Informix;
use Xymon::Client;

use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.07';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}





sub new
{
    my $class = shift;
    my $parm = shift;
    
	
	
	my $self = bless ({}, ref ($class) || $class);

	$ENV{INFORMIXCONTIME} = $parm->{CONTIME} || 5;
	$ENV{INFORMIXCONTRY}= $parm->{CONTRY} || 1;
	$ENV{INFORMIXDIR}= $parm->{INFORMIXDIR} || "/informix/";
	$ENV{LD_LIBRARY_PATH} = $parm->{LD_LIBRARY_PATH} || "/informix/lib:/informix/lib/esql";
	
	$self->{home} = $parm->{HOBBITHOME} || '/home/hobbit/server/';
	$self->{informixdir} = $parm->{INFORMIXDIR} || "/informix/";
	

    return $self;
    
    
}


sub check {
	
	my $self = shift;
	
	my $error;
	my $message;
	my $instance;
	

	# Get instances and hostnames from sqlhosts
	#
	#
	my $fh;
	open( $fh, "<", $self->{informixdir} . "/etc/sqlhosts");
	while(<$fh>) {
		my ($server, $proto,$hostname) = split(/\s+/,$_);
		push @{$instance->{$hostname}}, $server;
	}
	
	close($fh);
	#
	# Cycle through hosts
	#
	
	foreach my $hostname (keys %$instance ) {
		
	
		my $hostsuccess = 0;
		my $hostmsg = "Database Status\n";
		my $color = "green";
		
		#
		# Now through instances
		#	
		foreach my $dbserver (@{$instance->{$hostname}}) {
			
			
			my $dbh = DBI->connect('dbi:Informix:sysmaster@'.$dbserver,"informix","kcgp.36", { AutoCommit => 0, PrintError => 1 });
			if( $dbh ) {
				my @row_ary = $dbh->selectrow_array('select count(*) from systables;');
				$hostmsg .= "<IMG src=http://hobbit/gifs/green-recent.gif> $dbserver Connected OK\n";
			} else {
				$hostmsg .= "<IMG src=http://hobbit/gifs/red-recent.gif> $dbserver Failed Connection\n";
				$hostsuccess = -1;
				$color = "red";
			}
				
					
		}
	
		#
		# Send to xymon server
		#	
		my $xymon = Xymon::Client->new({home=>$self->{home}});
	
		$xymon->send_status({
			server=>"$hostname",
			testname=>"database",
			color=>$color,
			msg=>$hostmsg,		
		});
	
	}	
	
}




=head1 NAME

Xymon::Monitor::Informix - Hobbit / Xymon Informix Database Monitor

=head1 SYNOPSIS

  use Xymon::Monitor::Informix;
  
  #
  # All parameters ar optional and defaults are shown
  #
  
  my $informix = Xymon::Monitor::Informix->new({
		CONTIME			=>	5,
		CONTRY			=>	1,
		INFORMIXDIR		=>	"/informix/",
		LD_LIBRARY_PATH	=>	"/informix/lib:/informix/lib/esql/",
		HOBBITHOME		=>	"/home/hobbit/client/"			
  });
  
  #
  # 
  $informix->check();


=head1 DESCRIPTION

Tries to connect to all instances specified your sqlhosts file and
sends the status to your Xymon/Hobbit Server. Each server will be sent a single
test called database which is red if any single database is down. Status page
shows status of all db instances on that host.

You must install DBI and DBD::Informix for this module to work.

=head1 CONSTRUCTOR

	my $informix = Xymon::Monitor::Informix->new({.....});
	
All parameters are optional and are listed below:

	CONTIME - connection timeout (default 5)
	CONTRY - connection tries (default 1)
	INFORMIXDIR - informix directory ($INFORMIXDIR) (default /informix)
	LD_LIBRARY_PATH	- default (/informix/lib:/informix/lib/esql/)
	HOBBITHOME - hobbit/xymon dir (default home/hobbit/client/)	

The script listed in the synopsis is all you need to send updates to Xymon/Hobbit,
however you will also need to add the script to your hobbitlaunch.cfg file.

A group of lines like the following should work. 

	[informix]
        ENVFILE /home/hobbit/server/etc/hobbitserver.cfg
        NEEDS hobbitd
        CMD /home/hobbit/server/ext/ifxcheck.pl
        LOGFILE $BBSERVERLOGS/informix.log
        INTERVAL 30


The installation script asks you where you want to install the included test script. 
It should go in your hobbit ext directory.

=head1 METHODS

	check() - checks all found instances from sqlhosts and sends status
	to master hobbit server. 


=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Xymon::Client, www.xymon.com

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

