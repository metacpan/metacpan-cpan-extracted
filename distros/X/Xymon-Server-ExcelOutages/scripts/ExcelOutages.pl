#!/usr/local/bin/perl



use Xymon::Server::ExcelOutages;
use CGI;


$| = 1; # Do not buffer output

my $cgi = CGI->new();



if (defined $ENV{'SERVER_PROTOCOL'} ) {
	
	print "Content-type: text/html\n\n
	<head>
	<META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">\n
	<META HTTP-EQUIV=\"Expires\" CONTENT=\"-1\">
	<meta http-equiv=\"Cache-Control\" content=\"no-store\" />
	<title>Outage Report</title>
	<script>
		function finished() {
			
			var idv=document.getElementById('status');
			idv.style.display='none';
		} 
		
		function hideme() {
			
			var ifr=document.getElementById('exceldiv');
			ifr.style.display='none';
			ifr=document.getElementById('top');
			ifr.style.display='none';
			
		}	
	</script>
	</head>	
	";
	print "<body bgcolor='#000000' text='#FFFFFF' onload='finished()'>";
	print "<center>";
	print "<DIV id=top><p><FONT FACE=\"Arial, Helvetica\" SIZE=\"+1\" COLOR=\"silver\"><B>Generating Outage Report</B></FONT><BR></P></div>";
	print "<BR><DIV align=center id=status name=status><IMG src='/ajax-loader.gif'></DIV>";
	my $ishttp = 1;
	
} else {
	print "Running...\n";
}


 
#print "Start Collating<BR>";


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
						HTTP => $ishttp,
						EXCELFILE => '/home/hobbit/server/www/weeklyexcel.xls',
						
			});




$outages->create();
if (defined $ENV{'SERVER_PROTOCOL'} ) {
	print "<DIV name=exceldiv id=exceldiv>
			<IFRAME border=0 id=excel name=excel src='/weeklyexcel.xls' onload='hideme()'>";
	print "</IFRAME></DIV>
			<p><FONT FACE=\"Arial, Helvetica\" SIZE=\"+1\" COLOR=\"silver\"><B>Finished</B></FONT><BR></P>
			</body>";
};