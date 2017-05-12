#!/usr/bin/perl

# ThreatNet::Message basic functionality tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 34;
use ThreatNet::Message ();

# Create the test data
my @good = (
	'',
	'a',
	' ',
	'foo',
	'this is a multipart thing',
	);
my @bad = (
	undef,
	[],
	\"stringref",
	{},
	);

# Create a basic object
foreach my $string ( @good ) {
	my $Message = ThreatNet::Message->new($string);
	isa_ok( $Message, 'ThreatNet::Message' );
	ok( $Message, 'bool overload returns true' );
	is( $Message->message, $string, '->message returns original string' );
	is( "$Message", $string, 'Stringify overload returns string' );
	ok( $Message->created, '->created returns true' );
	ok( $Message->event_time, '->event_time returns true' );
}
foreach my $something ( @bad ) {
	my $Message = ThreatNet::Message->new($something);
	is( $Message, undef, 'Bad message returns undef' );
}

