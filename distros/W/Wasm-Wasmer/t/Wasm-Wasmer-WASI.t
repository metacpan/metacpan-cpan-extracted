#!/usr/bin/env perl

package t::Wasm::Wasmer::WASI;

use strict;
use warnings;

use Test2::V0 -no_utf8 => 1;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'TestBase';

use Wasm::Wasmer;
use Wasm::Wasmer::Module;
use Wasm::Wasmer::WASI;

use File::Temp;

use constant _WAT => <<'END';
(module

    (import "wasi_snapshot_preview1" "fd_write" (func $fdwrite (param i32 i32 i32 i32) (result i32)))

    (memory (export "memory") 1)

    ;; function export:
    (func (export "fd_write") (param i32 i32 i32 i32) (result i32)
        local.get 0
        local.get 1
        local.get 2
        local.get 3
        call $fdwrite
    )
)
END

__PACKAGE__->new()->runtests() if !caller;

sub test_create : Tests(2) {
    isa_ok(
        Wasm::Wasmer::Store->new()->create_wasi(),
        ['Wasm::Wasmer::WASI'],
        'empty new()',
    );

    my $dir1 = File::Temp::tempdir( CLEANUP => 1 );
    my $dir2 = File::Temp::tempdir( CLEANUP => 1 );

    isa_ok(
        Wasm::Wasmer::Store->new()->create_wasi(
            stdin  => 'inherit',
            stdout => 'inherit',
            stderr => 'inherit',

            args => [ 'one', 'two' ],

            env => [ HEY => 'there', YOU => 'two' ],

            preopen_dirs => [ $dir1, $dir2 ],

            map_dirs => {
                '/HEY/foo' => $dir1,
                '/HEY/bar' => $dir2,
            },
        ),
        ['Wasm::Wasmer::WASI'],
        'decked-out new()',
    );

    return;
}

sub test_filesys_nonutf8 : Tests(3) {
    my $todo = todo('Wasmer seems to have stopped caring here.');

    my $baddir = "/../../foo/\xff\xff\xff";

    my $baddir_utf8 = $baddir;
    utf8::encode($baddir_utf8);

    my $err = dies {
        Wasm::Wasmer::Store->new()->create_wasi(
            preopen_dirs => [$baddir],
        );
    };

    is(
        $err,
        check_set(
            match(qr<$baddir_utf8>),
        ),
        'preopen_dirs: error as expected (dir is UTF-8 encoded)',
    );

    # --------------------------------------------------

    $err = dies {
        Wasm::Wasmer::Store->new()->create_wasi(
            map_dirs => {
                $baddir => '/good/dir',
            },
        );
    };

    is(
        $err,
        check_set(
            match(qr<$baddir_utf8>),
        ),
        'map_dirs: alias is UTF-8 encoded',
    );

    $err = dies {
        Wasm::Wasmer::Store->new()->create_wasi(
            map_dirs => {
                '/good/dir' => $baddir,
            },
        );
    };

    is(
        $err,
        check_set(
            match(qr<$baddir_utf8>),
            match(qr</good/dir>),
        ),
        'map_dirs: host dir is UTF-8 encoded',
    );

    return;
}

sub test_fd_write : Tests(4) {
    my $ok_wasm = Wasm::Wasmer::wat2wasm(_WAT);

    my @tt = (
        [ 1 => 'read_stdout' ],
        [ 2 => 'read_stderr' ],
    );

    for my $t_ar (@tt) {
        my ( $wasi_fd, $read_fn ) = @$t_ar;

        my $module = Wasm::Wasmer::Module->new($ok_wasm);

        my $wasi = $module->store()->create_wasi(
            stdout => 'capture',
            stderr => 'capture',
        );

        my $instance = $module->create_wasi_instance($wasi);

        my $mem     = $instance->export('memory');
        my $payload = 'hello';

        # Cribbed from as-wasi’s use of fd_write and wasi.rs:
        # Payload at offset 32, (addr, len) at offset 16.

        $mem->set( $payload,                          32 );
        $mem->set( pack( 'LL', 32, length $payload ), 16 );

        my $wasi_errno = $instance->call(
            'fd_write',
            $wasi_fd,    # WASI FD to write to
            16,          # iovecs are at offset 16.
            1,           # There’s 1 iovec.
            8,           # Write the # of bytes written to offset 8.
        );

        die "WASI errno: $wasi_errno" if $wasi_errno;

        my $wrote = unpack 'L', $mem->get( 8, 4 );
        is( $wrote, length($payload), 'bytes written' );

        is(
            $wasi->$read_fn(32),
            $payload,
            "$read_fn() reads captured output",
        );
    }

    return;
}

1;
