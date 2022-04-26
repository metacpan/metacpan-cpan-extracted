#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Wasm::Wasm3;

use File::Spec;
use File::Temp;
use Scope::Guard;

use File::Slurper;

use FindBin;

my $wasi_is_simple = (Wasm::Wasm3::WASI_BACKEND ne 'uvwasi');

my $wasm = Wasm::Wasm3->new();

my $wasm_bin = File::Slurper::read_binary(
    File::Spec->catfile($FindBin::Bin, qw(assets wasi-demo.wasm) ),
);

close *STDIN;
open *STDIN, '<&', scalar File::Temp::tempfile();

{
    my $mod = $wasm->parse_module($wasm_bin);
    my $rt = $wasm->create_runtime(102400)->load_module($mod);

    if ($wasi_is_simple) {
        $mod->link_function('wasi_snapshot_preview1', 'fd_readdir', 'i(iiiIi)', sub { 0 } );
    }

    my $tfh = File::Temp::tempfile();

    my $exit_code = do {
        open my $dupe_stdout, '>&', \*STDOUT;
        close \*STDOUT;
        open \*STDOUT, '>&', $tfh;

        my $guard = Scope::Guard->new( sub {
            close \*STDOUT;
            open \*STDOUT, '>&', $dupe_stdout;
        } );

        $mod->link_wasi_default();

        $rt->run_wasi();
    };

    is($exit_code, 42, 'WASI exit code returned');

    sysseek $tfh, 0, 0;

    my $got = do { local $/; <$tfh> };

    like($got, qr<hello.+world>i, 'WASI ran');
}

#----------------------------------------------------------------------

SKIP: {
    skip "Needs uvwasi", 1 if $wasi_is_simple;

    my $mod = $wasm->parse_module($wasm_bin);
    my $rt = $wasm->create_runtime(10240000)->load_module($mod);

    my $in = File::Temp::tempfile();
    syswrite( $in, 'this is stdin' );
    sysseek( $in, 0, 0 );

    my $out = File::Temp::tempfile();
    my $err = File::Temp::tempfile();

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $preopen_host = "$dir/ü";
    CORE::mkdir $preopen_host;

    for ( qw( abc é ää ø Ÿ ) ) {
        open my $a, '>', "$preopen_host/$_";
    }
    system('ls', '-laR', $dir);

    $mod->link_wasi(
        in => fileno($in),
        out => fileno($out),
        err => fileno($err),

        env => [
            THIS => 'is',
            ENV => 'wasm::wasm3',
        ],

        preopen => {
            "/\x{e9}p\x{e9}e" => $preopen_host,
        },
    );

    my $exit_code = $rt->run_wasi(qw(this is ärgv));

    is($exit_code, 42, 'WASI exit code returned');

    sysseek $out, 0, 0;
    my $got = do { local $/; <$out> };
    like($got, qr<hello.+world>i, 'WASI ran');
    like($got, qr<THIS.*is>, 'env 1');
    like($got, qr<ENV.*wasm::wasm3>, 'env 2');
    like($got, qr<épée.*abc.*ää.*é.*ø.*Ÿ>, 'preopen & printout');
    like($got, qr<this.*is.*ärgv>, 'argv given');

    sysseek $err, 0, 0;
    my $got2 = do { local $/; <$err> };
    like( $got2, qr<stdin.*this is stdin>, 'read from stdin, wrote to stderr' );
}

done_testing();
