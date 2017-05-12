#!/usr/bin/perl

# Tests for ThreatNet::IRC::Envelope

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use ThreatNet::IRC ();





#####################################################################
# Main Tests (only very basic)

my $Message = bless {}, 'ThreatNet::Message';
isa_ok( $Message, 'ThreatNet::Message' );

my $Envelope = ThreatNet::IRC::Envelope->new(
	$Message, 'foo!bar@ali.as', 'threatnet'
	);
isa_ok( $Envelope, 'ThreatNet::IRC::Envelope' );
isa_ok( $Envelope->message, 'ThreatNet::Message' );
is( $Envelope->who, 'foo!bar@ali.as', '->who returns as expected' );
is( $Envelope->where, 'threatnet', '->where returns as expected' );

1;
