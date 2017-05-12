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

my $columns = [ '1', '2', '3' ];

# blocking mode
my $snmp = Net::SNMP->session(-hostname => 'blah', -community => 'blah');
my $result;
ok($result = $snmp->get_entries(-columns => $columns), 'can call get_entries in blocking mode');
is_deeply(
    $result,
    { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
    'first element of varbindlist is returned for get_entries'
);
is_deeply($mock_net_snmp->get_option_val('get_entries', '-columns'),
    $columns, 'mock object stores varbindlist for get_entries');

# non-blocking mode
my $oid_result;
ok($snmp->get_entries(-callback => [ \&getr_callback, \$oid_result ], -delay => 60, -columns => $columns),
    'calling get_entries in non-blocking mode returns true');
is($oid_result, 'tset', q{get_entries in non-blocking mode calls the call back});
is_deeply($mock_net_snmp->get_option_val('get_entries', '-columns'),
    $columns, 'mock object stores varbindlist in non-blocking mode for get_entries');
is_deeply($mock_net_snmp->get_option_val('get_entries', '-delay'),
    60, 'mock object stores delay in non-blocking mode for get_entries');

# check an error is created if there is no varbindlist
ok(!defined $snmp->get_entries(-delay => 60), 'calling get_entries without columns returns undefined');
is($snmp->error(), '-columns not passed in to get_entries', 'get_entries error message set to what we expect');
$mock_net_snmp->reset_values();

# no more elements in varbindlist
ok(!defined $snmp->get_entries(-columns => '1.2.2'), 'get_entries returns undef if there are no more elements');
is($snmp->error(), 'No more elements in varbindlist!', 'get_entries no more elements error set correctly');

sub getr_callback {
    my ($session, $or_ref) = @_;
    my $list = $session->var_bind_list();

    $$or_ref = $list->{'1.2.2.1'};
    return;
}
