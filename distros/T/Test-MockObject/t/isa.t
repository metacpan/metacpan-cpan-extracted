#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use_ok( 'Test::MockObject' );
my $mock = Test::MockObject->new();

can_ok( $mock, 'set_isa' );

# set_isa() should make isa() report true for the given parents
$mock->set_isa( 'CGI', 'Apache::Request', 'Apache' );

isa_ok( $mock, 'CGI' );
isa_ok( $mock, 'Apache' );

# ... it should be able to add parents
$mock->set_isa( 'Something' );
isa_ok( $mock, 'Something' );

# ... without overwriting previous parents
isa_ok( $mock, 'Apache::Request' );

# ... or reporting true for everything
ok( ! $mock->isa( 'Fail' ), '... this is not a "Fail" object' );
