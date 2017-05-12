#!/usr/bin/perl

# Compile test

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;

ok( $] >= 5.005, 'Perl version is new enough' );

my @modules = qw{
	Filter
	Filter::Chain
	Filter::Network
	Filter::Null
	Filter::ThreatCache
	IRC
	IRC::Envelope
	Message
	Message::IPv4
	Topic
	Bot::AmmoBot
};
foreach ( @modules ) {
	use_ok( "ThreatNet::$_" );
}
