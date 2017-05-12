#!/usr/local/bin/perl

use Time::Business;
use HTTP::Date;


my $bustime = Time::Business->new({
	STARTTIME=>"9:00",
	ENDTIME=>"17:00",
	WORKDAYS=>[1,2,3,4,5]
});
	



	my $end = str2time("Tue 29 Jun 2010 00:31");
	my $start = str2time("Tue 29 Jun 2010 00:30");
	print scalar localtime($end) . "\n";
	my $seconds = $bustime->duration($start,$end);
	print $seconds . "\n";

