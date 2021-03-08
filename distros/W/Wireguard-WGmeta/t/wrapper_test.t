#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
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

my $wg_meta = Wireguard::WGmeta::Wrapper::Config->new(TEST_DIR);


# parser tests
# interfaces
my @interface_list = ('mini_wg0', 'mini_wg1');
my @output = $wg_meta->get_interface_list();
ok eq_array(\@output, \@interface_list), 'interface_list';

# sections
my @sections = ('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY');
@output = $wg_meta->get_section_list('mini_wg0');
ok eq_array(\@output, \@sections), 'section_list wg0';

@sections = ('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY', 'WG_1_PEER_B_PUBLIC_KEY');
@output = $wg_meta->get_section_list('mini_wg1');
ok eq_array(\@output, \@sections), 'section_list wg1';

# section of non existent interface
@output = $wg_meta->get_section_list('mini_wg0s');
@sections = ();
ok eq_array(\@output, \@sections), 'unknown interface';

# n_peers (all)
ok $wg_meta->get_peer_count() == 3, 'peer count [all]';

# n_peers (one interface)
ok $wg_meta->get_peer_count('mini_wg1') == 2, 'peer count [wg1]';

# set
my $expected = '[Interface]
Address = 10.0.0.2/24, fdc9:281f:04d7:9ee9::2/64
ListenPort = 60000
PrivateKey = OHLK9lBHFqnu+9olAnyUN11pCeKP4uW6fwMAeRSy2F8=

[Peer]
PublicKey = WG_0_PEER_A_PUBLIC_KEY
PresharedKey = PEER_A-PEER_B-PRESHARED_KEY
#A normal comment
Custom_attr_from_very_custom_implementation = Some crazy value with spaces :D
AllowedIPs = fdc9:281f:04d7:9ee9::1/128
Endpoint = 198.51.100.101:60001
#+Name = Name_by_test1
#+Alias = alias2

';

# normal attributes (mixed type)
$wg_meta->set('mini_wg0', 'mini_wg0', 'listen-port', 60000, 1);
$wg_meta->set('mini_wg0', 'mini_wg0', 'private-key', 'OHLK9lBHFqnu+9olAnyUN11pCeKP4uW6fwMAeRSy2F8=', 1);
$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'endpoint', '198.51.100.101:60001', 1);

# wg-meta attrs
$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'name', 'Name_by_test1');
$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'alias', 'alias1');

# wg-meta update alias by alias
$wg_meta->set_by_alias('mini_wg0', 'alias1', 'alias', 'alias2');

my $actual = $wg_meta->_create_config('mini_wg0', 1);
ok $actual eq $expected, 'set valid attrs';

# add peer
my ($iface_privkey, $iface_listen) = $wg_meta->add_peer('mini_wg0', 'added_peer', '10.0.0.9/32', 'sa9sXzMC5h4oE+38M38D1bcakH7nQBChAN1ib30lODc=');
ok $iface_privkey eq 'OHLK9lBHFqnu+9olAnyUN11pCeKP4uW6fwMAeRSy2F8=', 'add peer, priv-key';
ok $iface_listen eq '60000', 'add peer, listen-port';

$expected .= '[Peer]
#+Name = added_peer
PublicKey = sa9sXzMC5h4oE+38M38D1bcakH7nQBChAN1ib30lODc=
AllowedIPs = 10.0.0.9/32
#+Alias = new_peer

';
# and set an alias on this new peer
$wg_meta->set('mini_wg0', 'sa9sXzMC5h4oE+38M38D1bcakH7nQBChAN1ib30lODc=', 'alias', 'new_peer');

$actual = $wg_meta->_create_config('mini_wg0', 1);
ok $actual eq $expected, 'add peer, content';

$expected = '[Interface]
Address = 10.0.0.2/24
ListenPort = 51860
PrivateKey = WG_1_PEER_B_PRIVATE_KEY

[Peer]
PublicKey = WG_1_PEER_B_PUBLIC_KEY
#+Alias = Alias2
PresharedKey = WG_1_PEER_B-PEER_B-PRESHARED_KEY
AllowedIPs = 10.0.0.2/32
Endpoint = 198.51.100.102:51871

';

# remove peer
$wg_meta->remove_peer('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY');
$actual = $wg_meta->_create_config('mini_wg1', 1);
ok $actual eq $expected, 'removed peer, content';

# check peer count after removal
ok $wg_meta->get_peer_count('mini_wg1') == 1, 'peer count after removal [wg1]';

# test if the alias got removed too
does_throw('access deleted alias', (sub(@args) {$wg_meta->translate_alias(@args)}), ('mini_wg1', 'Alias1'));


# try to an alias which is already present
does_throw('alias already known', \&set_wrapper, ('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'alias', 'alias1', 1));

# remove interface (and keep file)
$wg_meta->remove_interface('mini_wg1');
@output = $wg_meta->get_interface_list();
my @expected = ('mini_wg0');
ok eq_array(\@output, \@expected), 'remove interface';

# forwarder test
$wg_meta->set('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'listen-port', 12345, 0, \&_forward);
sub _forward($interface, $identifier, $attribute, $value) {
    ok $interface eq 'mini_wg0' && $identifier eq 'WG_0_PEER_A_PUBLIC_KEY' && $attribute eq 'listen-port' && $value == 12345, 'set forward_fun';
}

# reload listener test
my $listener_result = 0;
sub _my_reload_listener($interface, $ref_args) {
    my @args = @{$ref_args};
    $listener_result = 1 if "$interface,$args[0]" eq "mini_wg0,hello from listener";
}


$wg_meta->register_on_reload_listener(\&_my_reload_listener, 'bla', [ 'hello from listener' ]);
$wg_meta->reload_from_disk('mini_wg0');

ok $listener_result, 'Reload listener';

# no forwarder test
does_throw('no-meta w/o forwarder', \&set_wrapper, ('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'listen-port', 12345, 0));

# invalid attr name
does_throw('invalid attr name', \&set_wrapper, ('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'invalid_name', 12345, 1));

# try to set a non peer attribute on a peer
does_throw('non peer attribute on peer', \&set_wrapper, ('mini_wg0', 'WG_0_PEER_A_PUBLIC_KEY', 'listen-port', 5000, 1));

# try to set a non interface attribute on a interface
does_throw('non interface attribute on interface', \&set_wrapper, ('mini_wg0', 'mini_wg0', 'allowed-ips', '10.0.0.0/32', 1));

# data validation errors (uncomment if we eventually implement attribute value validation...)
does_throw('listen-port nan', \&set_wrapper, ('mini_wg0', 'mini_wg0', 'listen-port', 'not_a_number', 1));
# does_throw('private-key too short', \&set_wrapper, ('mini_wg0', 'mini_wg0', 'private-key', 'key_to_short', 1));
# does_throw('private-key invalid chars', \&set_wrapper, ('mini_wg0', 'mini_wg0', 'private-key', 'key invalid chars', 1));
# does_throw('address invalid', \&set_wrapper, ('mini_wg0', 'mini_wg0', 'address', 'invalid_address', 1));


# remove all interfaces
$wg_meta->remove_interface('mini_wg0');
@output = $wg_meta->get_interface_list();
@expected = ();
ok eq_array(\@output, \@expected), 'removed all interfaces [wg0]';

ok((not -e TEST_DIR . 'mini_wg0.conf'), 'interface file removed');

# write back initial configs
my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
write_file($filename_1, $initial_wg1);
write_file($filename_2, $initial_wg0);

# helper methods
sub set_wrapper(@args) {
    $wg_meta->set(@args);
}
sub set_alias_wrapper(@args) {
    $wg_meta->set_by_alias(@args);
}

sub does_throw($test_name, $fun, @args) {
    my $ok = 0;
    eval {
        &{$fun}(@args);
    } or $ok = 1;
    ok $ok, $test_name;
}

done_testing();



