#!/usr/local/bin/perl
use Xymon::Monitor::Informix;

my $Informix = new Xymon::Monitor::Informix->new({
										CONTIME => 5,
										CONTRY => 1,
										INFORMIXDIR => '/informix/',
										LD_LIBRARY_PATH => '/informix/lib:/informix/lib/esql',
										HOBBITHOME => '/home/hobbit/client/',									
	
									});
									

$Informix->check();
