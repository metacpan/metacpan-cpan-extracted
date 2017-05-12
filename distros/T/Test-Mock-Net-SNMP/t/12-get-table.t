#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 11;
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

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
my $result;
ok($result = $snmp->get_table(-baseoid => '1.2.1.1'), 'can call get_table in blocking mode');
is_deeply(
    $result,
    { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
    'first element of varbindlist is returned for get_table'
);
is($mock_net_snmp->get_option_val('get_table', '-baseoid'), '1.2.1.1', 'mock object stores varbindlist for get_table');

# non-blocking mode
my $oid_result;
ok($snmp->get_table(-callback => [ \&getr_callback, \$oid_result ], -delay => 60, -baseoid => '1.2.2'),
    'calling get_table in non-blocking mode returns true');
is($oid_result, 'tset', q{get_table in non-blocking mode calls the call back});
is_deeply($mock_net_snmp->get_option_val('get_table', '-baseoid'),
    '1.2.2', 'mock object stores varbindlist in non-blocking mode for get_table');
is_deeply($mock_net_snmp->get_option_val('get_table', '-delay'),
    60, 'mock object stores delay in non-blocking mode for get_table');

# check an error is created if there is no varbindlist
ok(!defined $snmp->get_table(-delay => 60), 'calling get_table without baseoid returns undefined');
is($snmp->error(), '-baseoid not passed in to get_table', 'get_table error message set to what we expect');
$mock_net_snmp->reset_values();

# no more elements in varbindlist
ok(!defined $snmp->get_table(-baseoid => '1.2.2'), 'get_table returns undef if there are no more elements');
is($snmp->error(), 'No more elements in varbindlist!', 'get_table no more elements error set correctly');

sub getr_callback {
    my ($session, $or_ref) = @_;
    my $list = $session->var_bind_list();

    $$or_ref = $list->{'1.2.2.1'};
    return;
}
