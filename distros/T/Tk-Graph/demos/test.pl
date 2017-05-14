#!/usr/local/bin/perl -w

use strict;
use lib '../.';
use Tk;
use Tk::Graph; 

my $mw = MainWindow->new;

my $to_register = {
	'one'  => [0,5,4,8,6,8],
	'two' => [2,5,9,4,6,2],
	'three' => [0,5,6,8,6,8],
};

my $data = {
	'one'  => 3,
	'two'  => 3,
	'three'  => 3,
};

my $ca = $mw->Graph(
	-type	=> 'Line',
	-max 	=> 10,
#	-look	=> 10,
	)->pack(-expand => 1, 
		-fill => 'both');

$ca->register($to_register);

$ca->variable($data);

# $mw->after(2000, sub { shuffle($data, $ca) } );

MainLoop;

sub shuffle {
	my $data = shift || die;
	my $ca = shift || die;

	foreach my $n (keys %$data) {
		$data->{$n} = int( rand(10) );		
	}
	$mw->after(1000, sub { shuffle($data, $ca) } );
}
                                                                             
