#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 17;
use Test::Exception;

use Test::Mock::Net::SNMP;

use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

$mock_net_snmp->set_varbindlist(
    [
        { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
        { '1.2.2.1' => 'tset', '1.2.2.2' => 'tset2', '1.2.2.3' => 'tset3' }
    ]
);

my $oid = '1.1.2.1.1';

my $set_val = [
    '1.3.6.1.2.1.1.3.0', TIMETICKS, 600,           '1.3.6.1.6.3.1.1.4.1.0',
    OBJECT_IDENTIFIER,   $oid,      '1.1.2.1.1.1', OCTET_STRING,
    'Test Message'
];

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
my $result;
ok($result = $snmp->inform_request(-varbindlist => $set_val), 'can call inform_request in blocking mode');
is_deeply(
    $result,
    { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
    'first element of varbindlist is returned for inform_request'
);
is_deeply($mock_net_snmp->get_option_val('inform_request', '-varbindlist'),
    $set_val, 'mock object stores varbindlist for inform_request');

# non-blocking mode
my $oid_result;
ok($snmp->inform_request(-callback => [ \&getr_callback, \$oid_result ], -delay => 60, -varbindlist => $set_val),
    'calling inform_request in non-blocking mode returns true');
is($oid_result, 'tset', q{inform_request in non-blocking mode calls the call back});
is_deeply($mock_net_snmp->get_option_val('inform_request', '-varbindlist'),
    $set_val, 'mock object stores varbindlist in non-blocking mode for inform_request');
is_deeply($mock_net_snmp->get_option_val('inform_request', '-delay'),
    60, 'mock object stores delay in non-blocking mode for inform_request');

# check an error is created if there is no varbindlist
ok(!defined $snmp->inform_request(-delay => 60), 'calling inform_request without varbindlist returns undefined');
is(
    $snmp->error(),
    '-varbindlist option not passed in to inform_request',
    'inform_request error message set to what we expect'
);
$mock_net_snmp->reset_values();

# check an error is created if the varbindlist has less than 6 elements
ok(!defined $snmp->inform_request(-varbindlist => ['1.2.2']), 'inform_request returns undef if less than 6 elements');
is(
    $snmp->error(),
    'inform_request requires sysUpTime and snmpTrapOID as the first 2 sets of varbindlist.',
    'correct error message for less than 6'
);
$mock_net_snmp->reset_values();

ok(
    !defined $snmp->inform_request(
        -varbindlist => [ '1.2.2', OCTET_STRING, 'blah', '1.2.4', OCTET_STRING, 'blah4', '1.2.3' ]),
    q{inform_request returns undef for arguments that aren't multiples of 3}
);
is(
    $snmp->error(),
    q{-varbindlist expects multiples of 3 in call to inform_request},
    q{correct error message for non multiples of 3}
);
$mock_net_snmp->reset_values();

ok(
    !defined $snmp->inform_request(
        -varbindlist => [ '1.2.2', OCTET_STRING, 'blah', '1.2.4', OCTET_STRING, 'blah4', '1.2.3', INTEGER, 3 ]
    ),
    q{inform_request returns undef for when the first two oids are incorrect}
);
is(
    $snmp->error(),
    q{inform_request: Wrong oids found in sysUpTime and snmpTrapOID spaces},
    q{correct error message for non arguments that don't start with the correct oids}
);

$mock_net_snmp->reset_values();

# no more elements in varbindlist
ok(
    !defined $snmp->inform_request(-varbindlist => $set_val),
    'inform_request returns undef if there are no more elements'
);
is($snmp->error(), 'No more elements in varbindlist!', 'inform_request no more elements error set correctly');

sub getr_callback {
    my ($session, $or_ref) = @_;
    my $list = $session->var_bind_list();

    $$or_ref = $list->{'1.2.2.1'};
    return;
}
