#!/usr/bin/perl

# Load test the ThreatNet::Filter module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 53;
use ThreatNet::Message::IPv4;

my $Message = ThreatNet::Message::IPv4->new( '123.123.123.123' );
isa_ok( $Message, 'ThreatNet::Message' );





#####################################################################
# Tests for ThreatNet::Filter

use ThreatNet::Filter;
SCOPE: {
	my $Filter = ThreatNet::Filter->new;
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );
	is( $Filter->keep($Message), 1, '->keep(msg) returns true' );
}





#####################################################################
# Tests for ThreatNet::Filter::Null

use ThreatNet::Filter::Null;
SCOPE: {
	my $Filter = ThreatNet::Filter::Null->new;
	isa_ok( $Filter, 'ThreatNet::Filter::Null' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );
	is( $Filter->keep($Message), '', '->keep(msg) returns false' );
}





#####################################################################
# Tests for ThreatNet::Filter::ThreatCache

use ThreatNet::Filter::ThreatCache;
SCOPE: {
	my $Filter = ThreatNet::Filter::ThreatCache->new;
	isa_ok( $Filter, 'ThreatNet::Filter::ThreatCache' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );

	# For the same message, it should be kept the first time and
	# rejected the second time
	is( $Filter->keep($Message), 1, '->keep(msg) returns true the first time' );
	is( $Filter->keep($Message), '', '->keep(msg) returns false the second time' );
	my $Message2 = ThreatNet::Message::IPv4->new( '123.123.123.124' );
	isa_ok( $Message2, 'ThreatNet::Message::IPv4' );
	is( $Filter->keep($Message2), 1, '->keep(msg) returns true the first time' );

	# Does it return some stats
	is( ref($Filter->stats), 'HASH', '->stats returns stats' );
	my $stats = $Filter->stats;
	is( $stats->{seen}, 3, 'stats{seen} is correct' );
	is( $stats->{kept}, 2, 'stats{kept} is correct' );
}





#####################################################################
# Tests for ThreatNet::Filter::Chain

use ThreatNet::Filter::Chain;
SCOPE: {
	my $counter1 = 0;
	my $counter2 = 0;
	my $Filter = ThreatNet::Filter::Chain->new(
		ThreatNet::Filter->new,
		My::Filter1->new,
		ThreatNet::Filter::ThreatCache->new,
		My::Filter2->new,
		ThreatNet::Filter::Null->new,
		);
	isa_ok( $Filter, 'ThreatNet::Filter::Chain' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );

	# Throw some messages at the filter chain
	my @messages = (
		ThreatNet::Message::IPv4->new( '1.2.3.4' ),
		ThreatNet::Message::IPv4->new( '1.2.3.5' ),
		ThreatNet::Message::IPv4->new( '1.2.3.4' ),
		);
	foreach my $msg ( @messages ) {
		isa_ok( $msg, 'ThreatNet::Message' );
		is( $Filter->keep($msg), '', '->keep(msg) always returns false' );
	}

	is( $counter1, 3, '$counter1 ends with the expected value 3' );
	is( $counter2, 2, '$counter2 ends with the expected value 2' );

	### Test filters
	package My::Filter1;
	use base 'ThreatNet::Filter';
	sub keep { $counter1++; 1 }

	package My::Filter2;
	use base 'ThreatNet::Filter';
	sub keep { $counter2++; 1 }
}





#####################################################################
# Tests for ThreatNet::Filter::Network

use ThreatNet::Filter::Network;
SCOPE: {
	my $Filter1 = ThreatNet::Filter::Network->new(
		discard => '123.123.123.123', 'LOCAL', '124.1.0.0/16'
		);
	my $Filter2 = ThreatNet::Filter::Network->new( keep => 'rfc1918' );
	isa_ok( $Filter1, 'ThreatNet::Filter::Network' );
	is( $Filter1->type, 'discard', '->type returns discard correctly' );
	is( $Filter2->type, 'keep',    '->type returns keep correctly' );
	is_deeply( [ $Filter1->network ], [
		'123.123.123.123', '127.0.0.0/8',
		'10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',
		'124.1.0.0/16',
		], '->network returns as expect for local expansion' );
	is_deeply( [ $Filter2->network ], [
		'10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',
		], '->network returns as expected for wrong-cases rfc expansion' );

	# Throw some messages at the filter chain
	my @messages = (
		'123.123.123.123' => '', '',
		'123.123.123.124' => 1,  '',
		'1.2.3.4'         => 1,  '',
		'127.0.0.2'       => '', '',
		'10.0.0.4'        => '', 1,
		);
	while ( @messages ) {
		my $ip = shift @messages;
		my $Message = ThreatNet::Message::IPv4->new( $ip );
		isa_ok( $Message, 'ThreatNet::Message::IPv4' );
		is( $Filter1->keep($Message), shift(@messages), "$ip: Filter1->keep returns as expected" );
		is( $Filter2->keep($Message), shift(@messages), "$ip: Filter2->keep returns as expected" );
	}
}
