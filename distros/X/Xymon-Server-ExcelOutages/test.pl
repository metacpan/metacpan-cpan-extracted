#!/usr/local/bin/perl

use Xymon::Server::ExcelOutages;
use Data::Dumper;


my $outages=Xymon::Server::ExcelOutages->new({
						DBCONNECT=>'DBI:Sybase:server=testsql2008;database=Hobbit',
						DBUSER=>'hobbitadm',
						DBPASSWD=>'7i4zou',
						HOME=>'/home/hobbit/server',
						SERVERS=>['oranprodsys'], 
						TESTS=>['disk', 'memory','conn', 'cpu', 'procs',],
						STARTTIME=>"9:00",
						ENDTIME=>"17:00",
						WORKDAYS=>[1,2,3,4,5],
						RANGESTART => time() - 86400 * 7,
						RANGEEND => time(),
						MINSECS => 60*5,
			});



$history  = $outages->create();

foreach my $key (sort {$history->{$a}->{starttime} <=> $history->{$b}->{starttime}} keys %$history) {
	if($history->{$key}->{bussecs}>0) {
		print $history->{$key}->{server};
		print " " . localtime $history->{$key}->{starttime};
		print " - " . localtime $history->{$key}->{endtime};
		print " - " . $history->{$key}->{bussecs};
		print "\n";
	}
	
}

