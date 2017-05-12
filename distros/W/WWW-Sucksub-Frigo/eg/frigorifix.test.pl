#!/usr/bin/perl 
use WWW::Sucksub::Frigo;
my $mot= shift;
$test=WWW::Sucksub::Frigo->new(
		html=>'/home/timo/frigohtml.html',
		motif=>$mot,
		debug=>1,
		logout=>'/home/timo/frigolog.txt',
		dbsearch=>1,
		);

$test->search();
#
