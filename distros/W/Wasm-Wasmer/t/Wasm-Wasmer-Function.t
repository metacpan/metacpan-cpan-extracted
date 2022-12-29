#!/usr/bin/env perl

package t::Wasm::Wasmer::Function;

use strict;
use warnings;

use Test2::V0 -no_utf8 => 1;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'TestBase';

use Encode;

use Wasm::Wasmer;
use Wasm::Wasmer::Store;

__PACKAGE__->new()->runtests() if !caller;

sub test_anonymous_function : Tests(6) {
    my $store = Wasm::Wasmer::Store->new();

    my $ran = 3;

    my $func_0_0 = $store->create_function( code => sub { ++$ran; } );

    isa_ok( $func_0_0, ['Wasm::Wasmer::Function'], 'create_function() return' );

    my $err = dies { $func_0_0->call() };

    is( $err, undef, 'no error from call()' );

    is( $ran, 4, '… and it ran the Perl function' );

    #----------------------------------------------------------------------

    my $wat = q<(module
        ;; function import:
        (import "my" "func" (func $mf (param i32 i32) (result f64)))

        (func (export "callfunc") (result f64)
            i32.const 0  ;; pass offset 0 to log
            i32.const 2  ;; pass length 2 to log
            call $mf
        )
    )>;

    my $module = Wasm::Wasmer::Module->new(
        Wasm::Wasmer::wat2wasm($wat),
        $store,
    );

    $err = dies {
        $module->create_instance( { my => { func => $func_0_0 } } );
    };

    is(
        $err,
        check_set(
            match( qr<i32>i ),
            match( qr<f64>i ),
            match( qr<my>i ),
            match( qr<func>i ),
        ),
        'expected error when import func doesn’t match module functype',
    );

    my $func_2_1 = $store->create_function(
        code => sub { ++$ran },
        params => [ Wasm::Wasmer::WASM_I32, Wasm::Wasmer::WASM_I32 ],
        results => [ Wasm::Wasmer::WASM_F64 ],
    );

    my $instance1 = $module->create_instance( { my => { func => $func_2_1 } } );
    my $instance2 = $module->create_instance( { my => { func => $func_2_1 } } );

    undef $func_2_1;

    is(
        $instance1->export('callfunc')->call(),
        5,
        'call() from first instance',
    );

    is(
        $instance2->export('callfunc')->call(),
        6,
        'call() from second instance',
    );

    return;
}

1;
