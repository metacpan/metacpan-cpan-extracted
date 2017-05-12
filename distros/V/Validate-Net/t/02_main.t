#!/usr/bin/perl

# Formal testing for Validate::Net

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 33;
use Validate::Net;





# Create a bunch of basic "good" and "bad" ips
my @good = qw{
	1.2.3.4
	0.0.0.0
	};
my @bad = qw{1.2.3};

# Check the good and bad ips
foreach ( @good ) {
	ok( Validate::Net->ip( $_ ), "'$_' passes ->ip correctly" );
	ok( Validate::Net->host( $_ ), "'$_' passes ->host correctly" );
}
foreach ( @bad ) {
	ok( ! Validate::Net->ip( $_ ), "'$_' fails ->ip correctly" );
}




# Create a bunch of basic "good" and "bad" domain and host names
@good = qw{
	foo
	bar
	foo-bar
	32146
	black.342.hole
	dot.at.end.
	};
@bad = qw{
	1st
	-blah
	blah-
	blah--blah
	reallyreallyreallyreallyreallyreallyreallyreallyreallyreallyreallyreallylong
	.dot.at.start
	this.is.1st.also.bad
	blah.blah-.blah
	};

# Check the good and bad domains
foreach ( @good ) {
	ok( Validate::Net->domain( $_ ), "'$_' passes ->domain correctly" );
	ok( Validate::Net->host( $_ ), "'$_' passes ->host correctly" );
}
foreach ( @bad ) {
	ok( ! Validate::Net->domain( $_ ), "'$_' fails ->domain correctly" );
	ok( ! Validate::Net->host( $_ ), "'$_' fails ->host correctly" );
}
