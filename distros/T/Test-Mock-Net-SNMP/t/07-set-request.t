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

$mock_net_snmp->set_varbindlist(
    [
        { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
        { '1.2.2.1' => 'tset', '1.2.2.2' => 'tset2', '1.2.2.3' => 'tset3' }
    ]
);

my $OID_sysContact = '1.3.6.1.2.1.1.4.0';
my $set_val = [ $OID_sysContact, OCTET_STRING, 'Help Desk x911' ];

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
my $result;
ok($result = $snmp->set_request(-varbindlist => $set_val), 'can call set_request in blocking mode');
is_deeply(
    $result,
    { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
    'first element of varbindlist is returned for set_request'
);
is_deeply($mock_net_snmp->get_option_val('set_request', '-varbindlist'), $set_val, 'mock object stores varbindlist');

# non-blocking mode
my $oid_result;
ok($snmp->set_request(-callback => [ \&getr_callback, \$oid_result ], -delay => 60, -varbindlist => $set_val),
    'calling set_request in non-blocking mode returns true');
is($oid_result, 'tset', q{set_request in non-blocking mode calls the call back});
is_deeply($mock_net_snmp->get_option_val('set_request', '-varbindlist'),
    $set_val, 'mock object stores varbindlist in non-blocking mode');
is_deeply($mock_net_snmp->get_option_val('set_request', '-delay'), 60, 'mock object stores delay in non-blocking mode');

# check an error is created if there is no varbindlist
ok(!defined $snmp->set_request(-delay => 60), 'calling set_request without varbindlist returns undefined');
is($snmp->error(), '-varbindlist option not passed in to set_request', 'error message set to what we expect');
$mock_net_snmp->reset_values();

# check an error is created if varbindlist has the wrong number of elements
ok(!defined $snmp->set_request(-varbindlist => ['1.2.2']), 'returns undef if there is the wrong number of elements');
is($snmp->error(), '-varbindlist expects multiples of 3 in call to set_request',
    'no more elements error set correctly');
$mock_net_snmp->reset_values();

# no more elements in varbindlist
ok(!defined $snmp->set_request(-varbindlist => $set_val), 'returns undef if there are no more elements');
is($snmp->error(), 'No more elements in varbindlist!', 'no more elements error set correctly');

sub getr_callback {
    my ($session, $or_ref) = @_;
    my $list = $session->var_bind_list();

    $$or_ref = $list->{'1.2.2.1'};
    return;
}
