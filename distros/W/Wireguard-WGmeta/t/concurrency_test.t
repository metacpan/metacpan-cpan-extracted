#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use experimental 'signatures';
use Test::More;
use Time::HiRes qw(usleep);

use Wireguard::WGmeta::Wrapper::ConfigT;
use Wireguard::WGmeta::Utils;

use constant TEST_DIR => $FindBin::Bin . '/test_data/';

my $THREADS_PRESENT;
BEGIN {
    eval {
        require threads;
        threads->import();
        require threads::shared;
        threads::shared->import();
        $THREADS_PRESENT = 1;
    };
}

my $initial_wg0 = read_file(TEST_DIR . 'mini_wg0.conf');
my $initial_wg1 = read_file(TEST_DIR . 'mini_wg1.conf');

my $wg_meta_outside = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);

$wg_meta_outside->add_peer('mini_wg1', 'added_outside_thread', '10.0.3.56/32', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'alias_out');
$wg_meta_outside->commit(1);

my $sync :shared;
my $thread_no_error :shared = 1;

sub thread_tester($test_name, $thread_name, $ref_function) {
    eval {
        # unfortunately sleep is needed here otherwise it could be the case that we're just too fast,
        # which means the timestamps of the file stay the same (even with hires!)
        usleep 50000;
        &{$ref_function}();
    };
    if ($@) {
        print "Test `$test_name` failed inside thread `$thread_name`:, $@ \n";
        $thread_no_error = 0;
        return 1;
    }
}

if (defined $THREADS_PRESENT) {

    my $thr1 = threads->create(\&run_in_thread_1);
    my $thr2 = threads->create(\&run_in_thread_2);
    $thr1->join();
    $thr2->join();

    sub run_in_thread_1 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        my %integrity_hashes;
        thread_tester('modify peer merge', '1', (sub() {
            %integrity_hashes = (
                'WG_1_PEER_A_PUBLIC_KEY' => $wg_meta_t->calculate_sha_from_internal('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY')
            );
            $wg_meta_t->set('mini_wg1', 'WG_1_PEER_A_PUBLIC_KEY', 'name', 'Name_set_in_thread_1');
        }));
        cond_wait $sync;
        thread_tester('delayed commit', '1', (sub() {
            $wg_meta_t->commit(1, 0, \%integrity_hashes);
        }));

    }
    sub run_in_thread_2 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        my %integrity_hashes;
        thread_tester('modify peer merge', '2', (sub() {
            %integrity_hashes = (
                'PUBLIC_KEY_PEER_OUTSIDE_THREAD' => $wg_meta_t->calculate_sha_from_internal('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD')
            );
            $wg_meta_t->set('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'name', 'Name_set_in_thread_2');
            $wg_meta_t->commit(1, 0, \%integrity_hashes);
        }));
        cond_signal $sync;
    }
    my $expected_after_thread = "# This config is generated and maintained by wg-meta.
# It is strongly recommended to edit this config only through a supporting wg-meta
# implementation (e.g the wg-meta cli interface)
#
# Changes to this header are always overwritten, you can add normal comments in [Peer] and [Interface] section though.
#
# Support and issue tracker: https://github.com/sirtoobii/wg-meta
#+Checksum = 974226613

[Interface]
Address = 10.0.0.2/24
ListenPort = 51860
PrivateKey = WG_1_PEER_B_PRIVATE_KEY

[Peer]
PublicKey = WG_1_PEER_A_PUBLIC_KEY
#+Alias = Alias1
PresharedKey = WG_1_PEER_A-PEER_B-PRESHARED_KEY
AllowedIPs = 10.0.0.1/32
Endpoint = 198.51.100.101:51871
#+Name = Name_set_in_thread_1

[Peer]
PublicKey = WG_1_PEER_B_PUBLIC_KEY
#+Alias = Alias2
PresharedKey = WG_1_PEER_B-PEER_B-PRESHARED_KEY
AllowedIPs = 10.0.0.2/32
Endpoint = 198.51.100.102:51871

[Peer]
#+Name = Name_set_in_thread_2
PublicKey = PUBLIC_KEY_PEER_OUTSIDE_THREAD
AllowedIPs = 10.0.3.56/32
#+Alias = alias_out

";
    ok((read_file(TEST_DIR . 'mini_wg1.conf') eq $expected_after_thread) && $thread_no_error, 'Thread merge_modify');

    my $test_result :shared = 0;
    $thread_no_error = 1;
    my $thr3 = threads->create(\&run_in_thread_3);
    my $thr4 = threads->create(\&run_in_thread_4);
    $thr3->join();
    $thr4->join();
    ok $test_result, 'Thread modify conflict';


    sub run_in_thread_3 {
        local $SIG{__DIE__} = sub {
            $test_result = 1;
        };
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        my %integrity_hashes;
        thread_tester('merge conflict', '3', (sub() {
            %integrity_hashes = (
                'PUBLIC_KEY_PEER_OUTSIDE_THREAD' => $wg_meta_t->calculate_sha_from_internal('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD')
            );
            $wg_meta_t->set('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'name', 'Name_set_in_thread_3');
        }));
        cond_wait $sync;
        thread_tester('merge conflict commit', '3', (sub() {
            eval {
                $wg_meta_t->commit(1, 0, \%integrity_hashes);
            };
        }));

    }
    sub run_in_thread_4 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        my %integrity_hashes;
        thread_tester('merge conflict commit other', '4', (sub() {
            %integrity_hashes = (
                'PUBLIC_KEY_PEER_OUTSIDE_THREAD' => $wg_meta_t->calculate_sha_from_internal('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD')
            );
            $wg_meta_t->set('mini_wg1', 'PUBLIC_KEY_PEER_OUTSIDE_THREAD', 'name', 'Name_set_in_thread_4');
            $wg_meta_t->commit(1, 0, \%integrity_hashes);
        }));
        cond_signal $sync;
    }

    $thread_no_error = 1;
    my $thr5 = threads->create(\&run_in_thread_5);
    my $thr6 = threads->create(\&run_in_thread_6);
    $thr5->join();
    $thr6->join();

    sub run_in_thread_5 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        cond_wait $sync;
        thread_tester('the lost peer', '5', (sub() {
            $wg_meta_t->commit(1);
        }));
    }
    sub run_in_thread_6 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        thread_tester('the new peer', '5', (sub() {
            $wg_meta_t->add_peer('mini_wg0', 'peer_added_in_thread_6', '10.0.5.56/32', 'PUBLIC_KEY_PEER_ADDED_6', 'alias_thread6');
            $wg_meta_t->commit(1);
        }));
        cond_signal $sync;
    }

    my $expected_after_th56 = '# This config is generated and maintained by wg-meta.
# It is strongly recommended to edit this config only through a supporting wg-meta
# implementation (e.g the wg-meta cli interface)
#
# Changes to this header are always overwritten, you can add normal comments in [Peer] and [Interface] section though.
#
# Support and issue tracker: https://github.com/sirtoobii/wg-meta
#+Checksum = 2806865288

[Interface]
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

[Peer]
#+Name = peer_added_in_thread_6
PublicKey = PUBLIC_KEY_PEER_ADDED_6
AllowedIPs = 10.0.5.56/32
#+Alias = alias_thread6

';

    ok((read_file(TEST_DIR . 'mini_wg0.conf') eq $expected_after_th56 && $thread_no_error), 'Thread, adding peer');

    my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
    write_file($filename_1, $initial_wg1);
    write_file($filename_2, $initial_wg0);

    $thread_no_error = 1;
    my $thr7 = threads->create(\&run_in_thread_7);
    my $thr8 = threads->create(\&run_in_thread_8);
    $thr7->join();
    $thr8->join();

    sub run_in_thread_7 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        thread_tester('add peer', '7', (sub() {
            $wg_meta_t->add_peer('mini_wg0', 'peer_added_in_thread_7', '10.0.5.56/32', 'PUBLIC_KEY_PEER_ADDED_7', 'alias_thread7');
        }));
        cond_wait $sync;
        thread_tester('add peer commit', '7', (sub() {
            $wg_meta_t->commit(1);
        }));
    }
    sub run_in_thread_8 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        thread_tester('add peer and commit', '8', (sub() {
            $wg_meta_t->add_peer('mini_wg0', 'peer_added_in_thread_8', '10.0.5.56/32', 'PUBLIC_KEY_PEER_ADDED_8', 'alias_thread8');
            $wg_meta_t->commit(1);
        }));
        cond_signal $sync;
    }

    my $expected_after_th78 = '# This config is generated and maintained by wg-meta.
# It is strongly recommended to edit this config only through a supporting wg-meta
# implementation (e.g the wg-meta cli interface)
#
# Changes to this header are always overwritten, you can add normal comments in [Peer] and [Interface] section though.
#
# Support and issue tracker: https://github.com/sirtoobii/wg-meta
#+Checksum = 3707844997

[Interface]
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

[Peer]
#+Name = peer_added_in_thread_7
PublicKey = PUBLIC_KEY_PEER_ADDED_7
AllowedIPs = 10.0.5.56/32
#+Alias = alias_thread7

[Peer]
#+Name = peer_added_in_thread_8
PublicKey = PUBLIC_KEY_PEER_ADDED_8
AllowedIPs = 10.0.5.56/32
#+Alias = alias_thread8

';

    ok((read_file(TEST_DIR . 'mini_wg0.conf') eq $expected_after_th78) && $thread_no_error, 'Thread, adding peer [both]');

    my $ping_pong_result :shared = 1;
    $thread_no_error = 1;
    my $thr9 = threads->create(\&run_in_thread_9, 'Thread 9');
    my $thr10 = threads->create(\&run_in_thread_10, 'Thread 10');
    $thr9->join();
    $thr10->join();

    sub run_in_thread_9 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        thread_tester('add interface 1', '9', (sub() {
            $wg_meta_t->add_interface('thread_iface1', '192.168.1.0/24', 8123, 'THREAD_IFACE1_PRIV_KEY');
            $wg_meta_t->commit(1);
        }));
        cond_wait $sync;
        thread_tester('add interface 2', '9', (sub() {
            $wg_meta_t->add_interface('thread_iface2', '192.168.2.0/24', 8125, 'THREAD_IFACE2_PRIV_KEY');
            $wg_meta_t->commit(1);
        }));
        cond_signal $sync;
        cond_wait $sync;
        thread_tester('add peer to interface 2', '9', (sub() {
            $wg_meta_t->add_peer('thread_iface2', 'PEER_THREAD_IFACE_2', '192.168.2.10/32', 'PEER_IFACE2_PUB_KEY', 'alias_thread_iface2');
            $wg_meta_t->commit(1);
        }));
        cond_signal $sync;
        cond_wait $sync;
        thread_tester('remove peer', '9', (sub() {
            $wg_meta_t->remove_peer('thread_iface2', 'PEER_IFACE2_PUB_KEY');
            $wg_meta_t->commit(1);
        }));
        cond_signal $sync;
        return 1;
    }

    sub run_in_thread_10 {
        lock $sync;
        my $wg_meta_t = Wireguard::WGmeta::Wrapper::ConfigT->new(TEST_DIR);
        thread_tester('get interface list 1', '10', (sub() {
            my @actual = $wg_meta_t->get_interface_list();
            $ping_pong_result &= eq_array(\@actual, [ 'mini_wg0', 'mini_wg1', 'thread_iface1' ]);
        }));
        cond_signal $sync;
        cond_wait $sync;
        thread_tester('get interface list 2', '10', (sub() {
            my @actual = $wg_meta_t->get_interface_list();
            $ping_pong_result &= eq_array(\@actual, [ "mini_wg0", "mini_wg1", "thread_iface1", "thread_iface2" ]);
        }));
        cond_signal $sync;
        cond_wait $sync;
        thread_tester('get section list', '10', (sub() {
            my @actual = $wg_meta_t->get_section_list('thread_iface2');
            $ping_pong_result &= eq_array \@actual, [ 'thread_iface2', 'PEER_IFACE2_PUB_KEY' ];
            $ping_pong_result &= $wg_meta_t->try_translate_alias('thread_iface2', 'alias_thread_iface2') eq 'PEER_IFACE2_PUB_KEY';
        }));
        cond_signal $sync;
        cond_wait $sync;
        thread_tester('get section list after remove', '10', (sub() {
            my @actual = $wg_meta_t->get_section_list('thread_iface2');
            $ping_pong_result &= eq_array \@actual, [ 'thread_iface2' ];
        }));
        return 1;

    }

    ok $ping_pong_result && $thread_no_error, 'Thread ping-pong';

    $wg_meta_outside->remove_interface('thread_iface2');
    $wg_meta_outside->remove_interface('thread_iface1');

}
else {
    ok 1, 'skip....no thread support present';
}

done_testing();

# write back initial configs
my ($filename_1, $filename_2) = (TEST_DIR . 'mini_wg1.conf', TEST_DIR . 'mini_wg0.conf');
write_file($filename_1, $initial_wg1);
write_file($filename_2, $initial_wg0);

