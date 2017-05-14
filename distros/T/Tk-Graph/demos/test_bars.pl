#!/usr/local/bin/perl -w

use strict;
use lib '../.';
use Tk;
use Tk::Graph; 

my $mw = MainWindow->new;

my $data = {
	'one'  => 5,
	'two' => 10,
	'three' => 3,
};

my $ca = $mw->Graph(
	-type		=> 'BARS',
	-printvalue 	=> '%s %d',
	)->pack(-expand => 1, 
		-fill => 'both');

$ca->set($data);	# Auf Daten anzeigen

$mw->after(2000, sub { shuffle($data, $ca) } );

MainLoop;

sub shuffle {
	my $data = shift || die;
	my $ca = shift || die;

	foreach my $n (keys %$data) {
		$data->{$n} = int( rand(100) );		
	}
	$mw->after(1000, sub { shuffle($data, $ca) } );
}
                                                                             
