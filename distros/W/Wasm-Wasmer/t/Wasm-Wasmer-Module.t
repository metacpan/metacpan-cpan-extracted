#!/usr/bin/env perl

package t::Wasm::Wasmer::Module;

use strict;
use warnings;

use Test2::V0 -no_utf8 => 1;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'TestBase';

use Wasm::Wasmer;
use Wasm::Wasmer::Store;
use Wasm::Wasmer::Module;

use constant _WAT => <<END;
(module
    (func (export "function") (param i32 i64))
    (global (export "global") i32 (i32.const 7))
    (table (export "table") 0 funcref)
    (memory (export "memory") 1)
)
END

__PACKAGE__->new()->runtests() if !caller;

sub test_invalid_module : Tests(1) {
    my $ok_wat = join(
        "\n",
        '(module',
        '(func (export "funcfunc") (param i32 i64))',
        '(func (export "funcfunc") (param i32 i64))',
        ')',
    );
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $err = dies { Wasm::Wasmer::Module->new($ok_wasm) };

    is(
        $err,
        match(qr<funcfunc>),
        'error as expected',
        explain $err,
    );

    return;
}

sub test_validate_module : Tests(4) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    ok( Wasm::Wasmer::Module::validate($ok_wasm),  'valid wasm' );
    ok( !Wasm::Wasmer::Module::validate('//////'), 'bad wasm' );

    my $store = Wasm::Wasmer::Store->new();

    ok(
        Wasm::Wasmer::Module::validate( $ok_wasm, $store ),
        'valid wasm, w/ store',
    );

    ok(
        !Wasm::Wasmer::Module::validate( '//////', $store ),
        'bad wasm, w/ store',
    );

    return;
}

sub test_serialize_deserialize : Tests(2) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $module = Wasm::Wasmer::Module->new($ok_wasm);

    my $serialized = $module->serialize();

    my $module2 = Wasm::Wasmer::Module::deserialize($serialized);

    isa_ok(
        $module2,
        ['Wasm::Wasmer::Module'],
        'deserialize() return',
    );

    my $serialized_up = $serialized;
    utf8::upgrade($serialized_up);

    $module2 = Wasm::Wasmer::Module::deserialize($serialized_up);

    isa_ok(
        $module2,
        ['Wasm::Wasmer::Module'],
        'deserialize() return (upgraded string)',
    );

    return;
}

1;
