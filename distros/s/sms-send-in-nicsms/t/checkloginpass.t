#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use SMS::Send;

#####################################################################
# Testing creation of new sender object with account credentials

# Create a new sender
my $sender = SMS::Send->new( 'IN::NICSMS',
	_login         => 'foo',
	_password      => 'bar',
        _signature     => 'foobar',
        _dlt_entity_id => '1234567890123456789',
	);
isa_ok( $sender, 'SMS::Send' );

# Test some internals
isa_ok( $sender->_OBJECT_, 'SMS::Send::IN::NICSMS' );
is( $sender->_OBJECT_->{_login},    'foo',
	'Login set correctly in internals' );
is( $sender->_OBJECT_->{_password}, 'bar',
	'Password set correctly in internals' );
is( $sender->_OBJECT_->{_signature}, 'foobar',
        'SenderID set correctly in internals' );
is( $sender->_OBJECT_->{_dlt_entity_id}, '1234567890123456789',
        'DLT Entity ID set correctly in internals' );

exit(0);
