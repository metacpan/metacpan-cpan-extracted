#!/usr/bin/env perl

package t::Wasm::Wasmer::Global;

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
use Wasm::Wasmer::Module;

use Data::Dumper;

use constant _WAT => Encode::decode_utf8(<<'END');
(module
   (global (export "é-const") i32 (i32.const 42))
   (global (export "é-mut") (mut i32) (i32.const 24))
)
END

__PACKAGE__->new()->runtests() if !caller;

sub test_global_int_excess : Tests(9) {
    my ($self) = @_;

  SKIP: {
        if (!eval { pack 'Q' } || !eval { pack('Q') eq pack('L!') }) {
            skip '64-bit support required.', $self->num_tests();
        }

        my $store = Wasm::Wasmer::Store->new();

        my $excess_i32 = q<> . hex('8000_0000');
        my $toolow_i32 = q<> . (-$excess_i32 - 1);
        my $max_i32 = 0x7fff_ffff;
        my $min_i32 = -0x8000_0000;

        for my $fn ( qw( create_i32_const create_i32_mut ) ) {
            my $err = dies { $store->$fn($excess_i32) };
            is(
                $err,
                check_set(
                    match( qr<$excess_i32> ),
                    match( qr<$max_i32> ),
                ),
                "$fn() rejects $excess_i32",
            );

            $err = dies { $store->$fn($toolow_i32) };
            is(
                $err,
                check_set(
                    match( qr<$toolow_i32> ),
                    match( qr<$min_i32> ),
                ),
                "$fn() rejects $toolow_i32",
            );
        }

        {
            my $i32 = $store->create_i32_mut(0);

            my $err = dies { $i32->set($excess_i32) };
            is(
                $err,
                check_set(
                    match( qr<$excess_i32> ),
                    match( qr<$max_i32> ),
                ),
                "i32->set() rejects $excess_i32",
            );

            $err = dies { $i32->set($toolow_i32) };
            is(
                $err,
                check_set(
                    match( qr<$toolow_i32> ),
                    match( qr<$min_i32> ),
                ),
                "i32->set() rejects $toolow_i32",
            );
        }

        my $excess_i64 = 0x8000 << 48;
        my $max_i64 = $excess_i64 - 1;

        for my $fn ( qw( create_i64_const create_i64_mut ) ) {
            my $err = dies { $store->$fn($excess_i64) };
            is(
                $err,
                check_set(
                    match( qr<$excess_i64> ),
                    match( qr<$max_i64> ),
                ),
                "$fn() rejects $excess_i64",
            );
        }

        {
            my $i64 = $store->create_i64_mut(0);

            my $err = dies { $i64->set($excess_i64) };
            is(
                $err,
                check_set(
                    match( qr<$excess_i64> ),
                    match( qr<$max_i64> ),
                ),
                "i64->set() rejects $excess_i64",
            );
        }
    }

    return;
}

sub test_global_validate : Tests(48) {
    my ($self) = @_;

    my $store = Wasm::Wasmer::Store->new();

    # TODO: ' 123', '123 '
    for my $val ( undef, 'hey', "123\0", [] ) {

        # It may be ideal not to have these warnings, but.
        no warnings 'numeric';

        my $valstr = defined($val) ? "$val" : 'undef';

        my $pretty = do {
            local $Data::Dumper::Indent = 0;
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Useqq = 1;
            Data::Dumper::Dumper($val);
        };

        for my $fn (
            qw( create_i32_const create_i32_mut ),
            qw( create_i64_const create_i64_mut ),
            qw( create_f32_const create_f32_mut ),
            qw( create_f64_const create_f64_mut ),
        ) {
            my $err = dies { $store->$fn($val) };

            is(
                $err,
                check_set(
                    match( qr<\Q$valstr\E> ),
                ),
                "$fn() rejects $pretty",
            );
        }

        for my $fn (
            qw( create_i32_mut ),
            qw( create_i64_mut ),
            qw( create_f32_mut ),
            qw( create_f64_mut ),
        ) {
            my $global = $store->$fn(0);

            my $err = dies { $global->set($val) };

            is(
                $err,
                check_set(
                    match( qr<\Q$valstr\E> ),
                ),
                "$fn then ->set() rejects $pretty",
            );
        }
    }

    return;
}

sub test_global_int_validate : Tests(8) {
    my ($self) = @_;

    my $store = Wasm::Wasmer::Store->new();

    for my $fn (
        qw( create_i32_const create_i32_mut ),
        qw( create_i64_const create_i64_mut )
    ) {

        # TODO: ' 123', '123 '
        for my $val ( 1.1, -1.2 ) {

            my $err = dies { $store->$fn($val) };
            is(
                $err,
                check_set(
                    match( qr<\Q$val\E> ),
                ),
                "$fn() rejects $val",
            );
        }
    }

    return;
}

sub test_globals : Tests(4) {
    my $wasm = Wasm::Wasmer::wat2wasm(_WAT);

    my @globals = do {
        my $module   = Wasm::Wasmer::Module->new($wasm);
        my $i = $module->create_instance();

        map { $i->export( Encode::decode_utf8($_) ) } (
            "é-const",
            "é-mut",
        );
    };

    is(
        \@globals,
        [
            object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call mutability => Wasm::Wasmer::WASM_CONST;
                call get        => 42;
            },
            object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call mutability => Wasm::Wasmer::WASM_VAR;
                call get        => 24;
            },
        ],
        'export() outputs expected objects',
    );

    my $got = $globals[1]->set(244);
    is( $got,               $globals[1], 'set() returns $self' );
    is( $globals[1]->get(), 244,         'set() updates the value' );

    my $err = dies { $globals[0]->set(233) };

    is(
        $err,
        check_set(
            match qr<i32>,
            match qr<constant>,
            match(qr<global>),
        ),
        'error on set() of a constant',
    );

    return;
}
