#!/usr/bin/perl

use strict; 
use warnings;

use lib './lib';

use IO::Socket::INET;
use Time::HiRes;
use Test::More tests => 3;

my $listen = IO::Socket::INET->new( Listen => 4, LocalAddr => 'localhost', LocalPort => 13903, ReuseAddr => 1, ReusePort => 1) or die $!;

if(fork) {
	my $socket = $listen->accept;

	print $socket "200 OK\r\n";
	$socket->shutdown(1);

	while(<$socket>) {
		#print $_;
		if( /Authorization/ and /Basic/ ) {
			ok("Auth");
		}
		if( /application\/json/ ) {
			ok("JSON");
		}
		if( /INFO/ ) {
			last;
		}
	}

	ok(1);
}

else {

	use WebService::LogDNA;

	Time::HiRes::sleep(0.1);

	my $dna = WebService::LogDNA->new( key => "foo", url => "http://localhost:13903" );

	$dna->ingest({ line => "test line", env=>'production', level => 'INFO' });

}
