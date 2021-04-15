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

my $validator_called = 0;
sub dummy_val($value) {
    $validator_called = 1;
    return $value;
}

my $custom_attr_config = {
    'email' => {
        'in_config_name' => 'Email',
        'validator'      => \&dummy_val
    }
};

my $wg_meta = Wireguard::WGmeta::Wrapper::Config->new(TEST_DIR, '#+', '#-', '.not_applied', $custom_attr_config);

$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'email', 'test@test.com', 1);

ok $validator_called, 'validator called';

my $expected = '[Interface]
Address = 10.0.0.2/24, fdc9:281f:04d7:9ee9::2/64
ListenPort = 51888
PrivateKey = WG_0_PEER_B_PRIVATE_KEY

[Peer]
PublicKey = WG_0_PEER_A_PUBLIC_KEY
PresharedKey = PEER_A-PEER_B-PRESHARED_KEY
#A normal comment
Custom_attr_from_very_custom_implementation = Some crazy value with spaces :D
AllowedIPs = fdc9:281f:04d7:9ee9::1/128
Endpoint = 198.51.100.101:51871
#+Email = test@test.com

';

my $actual = $wg_meta->_create_config('mini_wg0', 1);
ok $actual eq $expected, 'generate config';

$wg_meta->commit(1,1);

# parser test
$wg_meta->may_reload_from_disk('mini_wg0');
my %section = $wg_meta->get_interface_section('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY');

ok $section{email} eq 'test@test.com', 'parse custom attr';

# write back initial configs
my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
write_file($filename_1, $initial_wg1);
write_file($filename_2, $initial_wg0);

done_testing();

