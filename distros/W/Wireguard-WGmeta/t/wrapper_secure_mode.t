#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use experimental 'signatures';
use Test::More;

use Wireguard::WGmeta::Wrapper::Config;
use Wireguard::WGmeta::Utils;

use constant TEST_DIR => $FindBin::Bin . '/test_data/';

my $initial_wg0 = read_file(TEST_DIR . 'mini_wg0.conf');
my $initial_wg1 = read_file(TEST_DIR . 'mini_wg1.conf');

my $unknown_handler = sub($attribute, $value) {
    # Since unknown attribute handling is tested separately, we can safely ignore it
    return $attribute, $value;
};

my $wg_meta = Wireguard::WGmeta::Wrapper::Config->new(TEST_DIR);

$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'name', 'bli_blu', $unknown_handler);
$wg_meta->commit(0,1);

$wg_meta->may_reload_from_disk('mini_wg0');

my %section = $wg_meta->get_interface_section('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY');

ok $section{name} eq 'bli_blu', 'secure apply and reload';

$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'name', 'new_value_hot');
$wg_meta->commit(1,1);

$wg_meta->may_reload_from_disk('mini_wg0');

%section = $wg_meta->get_interface_section('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY');


ok $section{name} eq 'new_value_hot', 'apply hot and reload';



# write back initial configs
my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
write_file($filename_1, $initial_wg1);
write_file($filename_2, $initial_wg0);

done_testing();


