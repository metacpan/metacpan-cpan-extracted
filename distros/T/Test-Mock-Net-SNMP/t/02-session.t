#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 9;

use Test::Mock::Net::SNMP;
use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

$mock_net_snmp->set_error('Session failed');
$mock_net_snmp->set_session_failure();

my ($snmp, $error) = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');
ok(!defined $snmp, 'session call should return undefined snmp object if call failed');
is($error, 'Session failed', 'session call should return the error specified by user');

my $snmp2 = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');
ok(!defined $snmp, 'session call should return undefined when called in scalar context');

# remove the session failed and error message
$mock_net_snmp->reset_values();

($snmp, $error) = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');
isa_ok($snmp, 'Net::SNMP');
is($mock_net_snmp->get_option_val('session', '-hostname'), 'localhost', 'session -hostname option set');
is($mock_net_snmp->get_option_val('session', '-version'),  'v2c',       'session -version option set');

$snmp2 = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');
isa_ok($snmp2, 'Net::SNMP', 'Scalar context object');
is($mock_net_snmp->get_option_val('session', '-hostname'),
    'localhost', 'session -hostname option set in scalar context');
is($mock_net_snmp->get_option_val('session', '-version'), 'v2c', 'session -version option set in scalar context');

