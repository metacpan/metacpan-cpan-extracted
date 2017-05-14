#!/usr/local/bin/perl -w

use strict;
use lib '../.';
use Tk;
use Tk::Graph; 

my $mw = MainWindow->new;

my $data = {
	'one'  => 0.1,
	'two' => 0.1,
	'three' => 10,
};

my $ca = $mw->Graph(
	-type		=> 'HBARS',
#	-shadowdepth	=> 5,
	-padding	=> [50,50,50,50],
	-light		=> [80,50,0],
	-wire		=> 'gray',
	-bg		=> 'white',
	-threed		=> 10,
	)->pack(-expand => 1, 
		-fill => 'both');

$ca->set($data);	# Auf Daten anzeigen

# $mw->after(2000, sub { shuffle($data) } );

MainLoop;

sub shuffle {
	my $data = shift || die;

	foreach my $n (keys %$data) {
		$data->{$n} = int( rand(100) );		
	}
	$mw->after(1000, sub { shuffle($data) } );
}
                                                                             
