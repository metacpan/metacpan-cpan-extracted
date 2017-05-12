#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 13;
use Test::Exception;

use Test::Mock::Net::SNMP;

use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

my $oid = '1.1.2.1.1';

my $set_val = [
    '1.3.6.1.2.1.1.3.0', TIMETICKS, 600,           '1.3.6.1.6.3.1.1.4.1.0',
    OBJECT_IDENTIFIER,   $oid,      '1.1.2.1.1.1', OCTET_STRING,
    'Test Message'
];

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
ok($snmp->snmpv2_trap(-varbindlist => $set_val), 'can call snmpv2_trap in blocking mode');
is_deeply($mock_net_snmp->get_option_val('snmpv2_trap', '-varbindlist'),
    $set_val, 'mock object stores varbindlist for snmpv2_trap');

# non-blocking mode
ok($snmp->snmpv2_trap(-delay => 60, -varbindlist => $set_val), 'calling snmpv2_trap in non-blocking mode returns true');
is_deeply($mock_net_snmp->get_option_val('snmpv2_trap', '-varbindlist'),
    $set_val, 'mock object stores varbindlist in non-blocking mode for snmpv2_trap');
is($mock_net_snmp->get_option_val('snmpv2_trap', '-delay'),
    60, 'mock object stores delay in non-blocking mode for snmpv2_trap');

# check an error is created if there is no varbindlist
ok(!defined $snmp->snmpv2_trap(-delay => 60), 'calling snmpv2_trap without varbindlist returns undefined');
is(
    $snmp->error(),
    '-varbindlist option not passed in to snmpv2_trap',
    'snmpv2_trap error message set to what we expect'
);
$mock_net_snmp->reset_values();

# check an error is created if the varbindlist has less than 6 elements
ok(!defined $snmp->snmpv2_trap(-varbindlist => ['1.2.2']), 'snmpv2_trap returns undef if less than 6 elements');
is(
    $snmp->error(),
    'snmpv2_trap requires sysUpTime and snmpTrapOID as the first 2 sets of varbindlist.',
    'correct error message for less than 6'
);
$mock_net_snmp->reset_values();

ok(
    !defined $snmp->snmpv2_trap(
        -varbindlist => [ '1.2.2', OCTET_STRING, 'blah', '1.2.4', OCTET_STRING, 'blah4', '1.2.3' ]),
    q{snmpv2_trap returns undef for arguments that aren't multiples of 3}
);
is(
    $snmp->error(),
    q{-varbindlist expects multiples of 3 in call to snmpv2_trap},
    q{correct error message for non multiples of 3}
);
$mock_net_snmp->reset_values();

ok(
    !defined $snmp->snmpv2_trap(
        -varbindlist => [ '1.2.2', OCTET_STRING, 'blah', '1.2.4', OCTET_STRING, 'blah4', '1.2.3', INTEGER, 3 ]
    ),
    q{snmpv2_trap returns undef for when the first two oids are incorrect}
);
is(
    $snmp->error(),
    q{snmpv2_trap: Wrong oids found in sysUpTime and snmpTrapOID spaces},
    q{correct error message for non arguments that don't start with the correct oids}
);

$mock_net_snmp->reset_values();

