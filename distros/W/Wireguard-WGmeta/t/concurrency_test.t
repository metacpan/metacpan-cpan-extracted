#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use experimental 'signatures';
use Test::More;
use Time::HiRes qw(usleep);

use Wireguard::WGmeta::Wrapper::ConfigT;
use Wireguard::WGmeta::Utils;

my $unknown_handler = sub($attribute, $value) {
    # Since unknown attribute handling is tested separately, we can safely ignore it
    return $attribute, $value;
};
use constant TEST_DIR => $FindBin::Bin . '/test_data/';

my $initial_wg0 = read_file(TEST_DIR . 'mini_wg0.conf');
my $initial_wg1 = read_file(TEST_DIR . 'mini_wg1.conf');

my $wg_meta1 = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
my $wg_meta2 = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);

$wg_meta1->add_peer('mini_wg1', '10.0.3.56/32', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'alias_out');
$wg_meta1->commit(1, 1);

ok $wg_meta2->is_valid_identifier('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD'), 'added from other instance [Pub-Key]';
ok $wg_meta2->is_valid_alias('mini_wg1', 'alias_out'), 'added from other instance [Alias]';


# concurrent edit (non conflicting)
my %integrity_hashes1 = (
    'PUBLIC_KEY_PEER_OUTSIDE_THREAD' => $wg_meta1->calculate_sha_from_internal('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD')
);
$wg_meta1->set('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'name', 'Set by instance 1', $unknown_handler);

my %integrity_hashes2 = (
    'WG_1_PEER_A_PUBLIC_KEY' => $wg_meta2->calculate_sha_from_internal('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY')
);
$wg_meta2->set('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY', 'name', 'Set by instance 2', $unknown_handler);
# on fast systems the mtime would be identical otherwise...
usleep(5000);
$wg_meta2->commit(1, 1, \%integrity_hashes2);
# on fast systems the mtime would be identical otherwise...
usleep(5000);
$wg_meta1->commit(1, 1, \%integrity_hashes1);

my %section2 = $wg_meta2->get_interface_section('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD');
my %section1 = $wg_meta1->get_interface_section('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY');

ok $section2{name} eq 'Set by instance 1', 'concurrent edit [1]';
ok $section1{name} eq 'Set by instance 2', 'concurrent edit [2]';


# concurrent edit (conflict)
%integrity_hashes1 = (
    'WG_1_PEER_A_PUBLIC_KEY' => $wg_meta1->calculate_sha_from_internal('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY')
);
$wg_meta1->set('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY', 'name', 'Set by instance 1 [2]');

%integrity_hashes2 = (
    'WG_1_PEER_A_PUBLIC_KEY' => $wg_meta2->calculate_sha_from_internal('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY')
);
$wg_meta2->set('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY', 'name', 'Set by instance 2 [2]');
$wg_meta2->commit(1, 1, \%integrity_hashes2);
eval {
    # on fast systems the mtime would be identical otherwise...
    usleep(5000);
    $wg_meta1->commit(1, 1, \%integrity_hashes1);
} or ok 1, 'concurrent edit [3]';


# the story of the (not) lost peer...
$wg_meta1->add_peer('mini_wg0', '10.0.5.56/32', 'PUBLIC_KEY_PEER_ADDED_5', 'alias_peer5');
$wg_meta2->add_peer('mini_wg0', '10.0.5.57/32', 'PUBLIC_KEY_PEER_ADDED_6', 'alias_peer6');
$wg_meta1->commit(1);
# on fast systems the mtime would be identical otherwise...
usleep(5000);
$wg_meta2->commit(1);

ok $wg_meta1->is_valid_identifier('mini_wg0', 'PUBLIC_KEY_PEER_ADDED_6'), 'the (not) lost peer [1]';
ok $wg_meta2->is_valid_identifier('mini_wg0', 'PUBLIC_KEY_PEER_ADDED_5'), 'the (not) lost peer [2]';


# ping pong

$wg_meta1->add_interface('thread_iface1', '192.168.1.0/24', 8123, 'THREAD_IFACE1_PRIV_KEY');
$wg_meta1->commit(1);

my @actual = $wg_meta2->get_interface_list();
ok eq_array(\@actual, [ 'mini_wg0', 'mini_wg1', 'thread_iface1' ]), 'add interface';

$wg_meta2->add_peer('thread_iface1', '192.168.2.10/32', 'PEER_IFACE2_PUB_KEY', 'alias_thread_iface2');
$wg_meta2->commit(1);

@actual = $wg_meta1->get_section_list('thread_iface1');
ok eq_array \@actual, [ 'thread_iface1', 'PEER_IFACE2_PUB_KEY' ], 'add peer to new interface';

$wg_meta1->remove_peer('thread_iface1', 'PEER_IFACE2_PUB_KEY');
# on fast systems the mtime would be identical otherwise...
usleep(5000);
$wg_meta1->commit(1);

@actual = $wg_meta2->get_section_list('thread_iface1');
ok eq_array \@actual, [ 'thread_iface1' ], 'remove peer from new interface';

$wg_meta2->remove_interface('thread_iface1');
# on fast systems the mtime would be identical otherwise...
usleep(5000);
$wg_meta2->commit(1);

@actual = $wg_meta1->get_interface_list();
ok eq_array(\@actual, [ 'mini_wg0', 'mini_wg1' ]), 'removed interface';

# write back initial configs
my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
write_file($filename_1, $initial_wg1);
write_file($filename_2, $initial_wg0);

done_testing();

