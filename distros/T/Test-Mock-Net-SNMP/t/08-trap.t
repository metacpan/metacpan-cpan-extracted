#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 7;
use Test::Exception;

use Test::Mock::Net::SNMP;

use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

my $OID_sysContact = '1.3.6.1.2.1.1.4.0';
my $set_val = [ $OID_sysContact, OCTET_STRING, 'Help Desk x911' ];

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
ok($snmp->trap(-varbindlist => $set_val), 'can call trap in blocking mode');
is_deeply($mock_net_snmp->get_option_val('trap', '-varbindlist'), $set_val, 'mock object stores varbindlist');

# non-blocking mode
ok($snmp->trap(-delay => 60, -varbindlist => $set_val), 'calling trap in non-blocking mode returns true');
is_deeply($mock_net_snmp->get_option_val('trap', '-varbindlist'),
    $set_val, 'mock object stores varbindlist in non-blocking mode');
is_deeply($mock_net_snmp->get_option_val('trap', '-delay'), 60, 'mock object stores delay in non-blocking mode');

# force a fail
$mock_net_snmp->set_trap_failure();
$mock_net_snmp->set_error('Trap failure');
ok(!$snmp->trap(-varbindlist => $set_val), 'returns undef when told to');
is($snmp->error(), 'Trap failure', 'error message set correctly');

