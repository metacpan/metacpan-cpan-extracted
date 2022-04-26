#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

# ----------------------------------------------------------------------
# This test illustrates a minimal pure-Perl WASI implementation.
# ----------------------------------------------------------------------

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Wasm::Wasm3;

use File::Spec;
use File::Slurper;
use Scalar::Util;

use FindBin;

my $wasm = Wasm::Wasm3->new();

my $wasm_bin = File::Slurper::read_binary(
    File::Spec->catfile($FindBin::Bin, qw(assets hello.wasm) ),
);

my $module = $wasm->parse_module($wasm_bin);
my $rt = $wasm->create_runtime(123123)->load_module($module);

Scalar::Util::weaken( my $weak_rt = $rt );

my $exit_code;

my $stdout = q<>;

my $wasi_size_pack = 'V';
my $wasi_size_len = length pack 'V';
my $iovec_pack = ($wasi_size_pack x 2);
my $iovec_len = length pack $iovec_pack;

$module->link_function(
    wasi_snapshot_preview1 => fd_write => 'i(iiii)',
    sub {
        my ($fd, $iovec_p, $iovs_len, $nwritten_p) = @_;

        warn "FD should be 1, not $fd??" if $fd != 1;

        for my $iov_offset (0 .. ($iovs_len-1)) {
            my ($buf_p, $buflen) = unpack( $iovec_pack, $weak_rt->get_memory( $iovec_p + ($iov_offset * $iovec_len), $iovec_len ) );

            my $output = $weak_rt->get_memory($buf_p, $buflen);

            $stdout .= $output;
        }

        return 0;
    },
);

# AssemblyScript’s WASI always seems to require this regardless of
# its actual necessity.
#
$module->link_function(
    wasi_snapshot_preview1 => proc_exit => 'v(i)', sub { },
);

my $got_code = $rt->call('_start');

is( $stdout, "Hello, world!\n", 'expected output' );

done_testing;
