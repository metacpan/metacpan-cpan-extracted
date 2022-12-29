#!/usr/bin/env perl

package t::Wasm::Wasmer::Instance;

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

use constant _WAT => <<'END';
(module

    ;; function export:
    (func (export "add") (param $lhs i32) (param $rhs i32) (result i32)
        local.get $lhs
        local.get $rhs
        i32.add
    )

    ;; memory export:
    (memory (export "pagememory") 1)
    (data (i32.const 0) "Hello World!\00")

    ;; mutable global export:
    (global $gg (mut i32) (i32.const 123))
    (export "varglobal" (global $gg))

    (func (export "tellvarglobal") (result i32)
        global.get $gg
    )

    ;; constant global export:
    (global (export "constglobal") i32 (i32.const 333))
)
END

use constant _WAT_IMPORTS => <<'END';
(module

    ;; global import:
    ;; (import "my" "global" (global $g (mut i32)))

    ;; memory import:
    ;; (import "my" "memory" (memory $m 1))

    ;; function import:
    (import "my" "func" (func $mf (param i32 i32) (result i32 i32)))

    (func (export "callfunc") (result i32 i32)
        i32.const 0  ;; pass offset 0 to log
        i32.const 2  ;; pass length 2 to log
        call $mf
    )

    (func (export "needsparams") (param i32 i32))
)
END

use constant _WAT_FUNCTYPES => <<'END';
(module

    ;; function import:
    (import "my" "func" (func $mf (param i32 i64 f32 f64) (result i32 i64 f32 f64)))

    (func (export "callfunc") (param i32 i64 f32 f64) (result i32 i64 f32 f64)
        local.get 0
        local.get 1
        local.get 2
        local.get 3
        call $mf
    )
)
END

use constant _WAT_GLOBAL_TYPES => <<'END';
(module
    (global (export "my_i32") (mut i32) (i32.const 333))
    (global (export "my_i64") (mut i64) (i64.const 333))

    (global (export "my_f32") (mut f32) (f32.const 33.5))
    (global (export "my_f64") (mut f64) (f64.const 33.5))
)
END

use constant _WAT_FUNC_PERL_CONTEXT => <<'END';
(module

    ;; function import:
    (import "my" "voidfunc" (func $vf))
    (import "my" "scalarfunc" (func $sf (result i32)))

    (func (export "voidfunc")
        call $vf
    )

    (func (export "scalarfunc") (result i32)
        call $sf
    )
)
END

__PACKAGE__->new()->runtests() if !caller;

sub test_create_instance__imports_misshapen : Tests(5) {
    my $ok_wat  = _WAT_FUNCTYPES;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    # Do this at least once in the test suite to ensure that
    # we treat upgraded byte strings the same as downgraded ones:
    utf8::upgrade($ok_wasm);

    my $module = Wasm::Wasmer::Module->new($ok_wasm);

    my $err = dies { $module->create_instance( [123] ) };

    is(
        $err,
        check_set(
            match(qr<ARRAY>),
            match(qr<HASH>),
        ),
        'imports are arrayref',
    );

    $err = dies {
        $module->create_instance(
            {
                my => [123],
            }
        );
    };

    is(
        $err,
        check_set(
            match(qr<my>),
            match(qr<ARRAY>),
            match(qr<HASH>),
        ),
        'import namespace value is arrayref',
    );

    $err = dies { $module->create_instance( {} ) };

    is(
        $err,
        check_set(
            match(qr<my>),
            not_in_set( match(qr<func>) ),
        ),
        'required namespace not given',
    );

    $err = dies { $module->create_instance( { my => {} } ) };

    is(
        $err,
        check_set(
            match(qr<my>),
            match(qr<func>),
        ),
        'required import not given',
    );

    $err = dies {
        $module->create_instance(
            {
                my => {
                    func => [],
                }
            }
        )
    };

    is(
        $err,
        check_set(
            match(qr<my>),
            match(qr<func>),
            match(qr<CODE>),
        ),
        'required import given as wrong type',
    );
}

sub test_func_import_types : Tests(2) {
    my $ok_wat  = _WAT_FUNCTYPES;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my @cb_inputs;

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance(
        {
            my => {
                func => sub { @cb_inputs = @_; return @cb_inputs },
            },
        },
    );

    my @values = ( 1, 2, 1.5, 2.5 );

    my @got = $instance->call( callfunc => @values );
    is( \@cb_inputs, \@values, 'callback receives expected values' );
    is( \@got,       \@values, 'all values go through as expected' );
}

sub test_func_import_context : Tests(2) {
    my $ok_wat  = _WAT_FUNC_PERL_CONTEXT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $wantarray;

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance(
        {
            my => {
                voidfunc   => sub { $wantarray = wantarray; () },
                scalarfunc => sub { $wantarray = wantarray; 1 },
            },
        },
    );

    $instance->call('scalarfunc');
    is( $wantarray, q<>, '1 return -> scalar context' );

    $instance->call('voidfunc');
    is( $wantarray, undef, '0 returns -> void context' );

    return;
}

sub test_func_die : Tests(1) {
    my $ok_wat = join(
        "\n",
        '(module',
        '   (import "my" "croaker" (func $vf))',
        '   (func (export "voidfunc") call $vf)',
        ')',
    );
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $wantarray;

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance(
        {
            my => {
                croaker => sub { die "nonono" },
            },
        },
    );

    my $err = dies { $instance->call('voidfunc') };

    is(
        $err,
        match(qr<nonono>),
        'expected error',
    );

    return;
}

sub test_func_import : Tests(7) {
    my $ok_wat  = _WAT_IMPORTS;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my @cb_inputs;

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance(
        {
            my => {
                func => sub { @cb_inputs = @_; return ( 22, 33 ) },
            },
        },
    );

    my @got = $instance->call('callfunc');

    is( \@cb_inputs, [ 0,  2 ],  'callback called' );
    is( \@got,       [ 22, 33 ], 'values from callback passed' );

    #--------------------------------------------------

    $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance(
        {
            my => {
                func => sub { @cb_inputs = @_; return ( 1, 2, 3 ) },
            },
        },
    );

    my $err = dies {
        diag explain [ $instance->call('callfunc') ];
    };

    is(
        $err,
        check_set(
            match(qr<2>),    # expected
            match(qr<3>),    # received
        ),
        'error when callback mismatches expected returns count',
    );

    $err = dies {
        diag explain [ scalar $instance->call('callfunc') ];
    };

    is(
        $err,
        check_set(
            match(qr<scalar>),    # expected
        ),
        'error when list-returning WASM function called in scalar context',
    );

    #----------------------------------------------------------------------

    $err = dies {
        diag explain [ $instance->call('needsparams') ];
    };

    is(
        $err,
        check_set(
            match(qr<2>),
            match(qr<0>),
        ),
        'No params given to function that needs 2',
    );

    $err = dies {
        diag explain [ $instance->call( 'needsparams', 7 ) ];
    };

    is(
        $err,
        check_set(
            match(qr<2>),
            match(qr<1>),
        ),
        '1 param given to function that needs 2',
    );

    $err = dies {
        diag explain [ $instance->call( 'needsparams', 7, 7, 7 ) ];
    };

    is(
        $err,
        check_set(
            match(qr<2>),
            match(qr<3>),
        ),
        '3 params given to function that needs 2',
    );

    return;
}

sub test_memory_limits_and_grow_fail : Tests(5) {
    my $store = Wasm::Wasmer::Store->new();

    my $mem = $store->create_memory( initial => 22, maximum => 37 );

    is(
        $mem->size(),
        22,
        'initial size',
    );

    is(
        [ $mem->limits() ],
        [ 22, 37 ],
        'limits()',
    );

    is(
        $mem->grow(5),
        $mem,
        'grow() returns $self',
    );

    is(
        $mem->size(),
        27,
        'grown size',
    );

    my $err = dies { $mem->grow(100000) };

    is(
        $err,
        check_set(
            match qr<27>,
            match qr<37>,
            match qr<100000>,
        ),
        'error when trying to over-grow() memory',
    );

    return;
}

sub test_export : Tests(1) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    is(
        $instance,
        object {
            call [ export => 'qeqeqeqq' ] => undef;

            call [ export => 'add' ] => object {
                prop blessed => 'Wasm::Wasmer::Function';
            };

            call [ export => 'varglobal' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'constglobal' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call mutability => Wasm::Wasmer::WASM_CONST;
            };

            call [ export => 'pagememory' ] => object {
                prop blessed => 'Wasm::Wasmer::Memory';
            };

            call export_names_ar => bag {
                item 'add';
                item 'varglobal';
                item 'constglobal';
                item 'tellvarglobal';
                item 'pagememory';
                end();
            };
        },
        'export() method gives expected returns',
    );

    return;
}

sub test_func_export_add : Tests(2) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    is(
        $instance,
        object {
            call [ export => 'add' ] => object {
                prop blessed            => 'Wasm::Wasmer::Function';
                call [ call => 22, 33 ] => 55;
            };
            call [ export => 'tellvarglobal' ] => object {
                prop blessed => 'Wasm::Wasmer::Function';
            },
        },
        'export_functions()',
    );

    my $err = dies { $instance->call('hahahaha') };
    is(
        $err,
        match(qr<hahahaha>),
        'error on call() to nonexistent function export',
    );

    return;
}

sub test_create_memory__args : Tests(3) {
    my $store = Wasm::Wasmer::Store->new();

    my $err = dies { $store->create_memory( initial => 3, "foo" ) };
    like( $err, qr<even>i, 'err about uneven args' );

    $err = dies { $store->create_memory() };
    like( $err, qr<initial>, 'err about missing `initial`' );

    $err = dies { $store->create_memory( initial => 3, foofoo => 2 ) };
    like( $err, qr<foofoo>i, 'err about unrecognized arg' );

    return;
}

sub test_import_memory : Tests(3) {
    my $ok_wat = join(
        "\n",
        '(module',
        '   (import "my" "memory" (memory $m 2))',
        '   (func (export "readbyte") (param $offset i32) (result i32)',
        '       (i32.load8_u (get_local $offset))',
        '   )',
        ')',
    );

    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $store  = Wasm::Wasmer::Store->new();
    my $module = Wasm::Wasmer::Module->new( $ok_wasm, $store );

    my $mem = $store->create_memory( initial => 2 );

    my $instance = $module->create_instance(
        {
            my => { memory => $mem },
        },
    );

    is(
        $mem->set('hello'),
        $mem,
        'set() returns $self',
    );

    is(
        $instance,
        object {
            call [ call => readbyte => 0 ] => ord('h');
            call [ call => readbyte => 1 ] => ord('e');
        },
        'memory written & read',
    );

    is( $mem->get( 2, 3 ), 'llo', 'get() with offset & length' );

    return;
}

sub test_import_globals_types : Tests(1) {
    my $ok_wat = join(
        "\n",
        '(module',
        '   (import "global" "i32" (global $g1 (mut i32)))',
        '   (import "global" "i64" (global $g2 (mut i64)))',
        '   (import "global" "f32" (global $g3 (mut f32)))',
        '   (import "global" "f64" (global $g4 (mut f64)))',
        '   (func (export "get_i32") (result i32) global.get $g1)',
        '   (func (export "get_i64") (result i64) global.get $g2)',
        '   (func (export "get_f32") (result f32) global.get $g3)',
        '   (func (export "get_f64") (result f64) global.get $g4)',
        ')',
    );

    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $store  = Wasm::Wasmer::Store->new();
    my $module = Wasm::Wasmer::Module->new( $ok_wasm, $store );

    my $instance = $module->create_instance(
        {
            global => {
                i32 => $store->create_i32_mut(5),
                i64 => $store->create_i64_mut(500),
                f32 => $store->create_f32_mut(5.5),
                f64 => $store->create_f64_mut(500.5),
            },
        },
    );

    is(
        $instance,
        object {
            call [ call => 'get_i32' ] => 5;
            call [ call => 'get_i64' ] => 500;
            call [ call => 'get_f32' ] => 5.5;
            call [ call => 'get_f64' ] => 500.5;
        },
        'globals set as expected on instantiation',
    );
}

sub test_import_globals_mutability : Tests(6) {
    my $ok_wat = join(
        "\n",
        '(module',
        '   (import "mystuff" "myconst" (global $g1 i32))',
        '   (import "mystuff" "myvar" (global $g2 (mut i32)))',
        '   (func (export "get_const") (result i32) global.get $g1)',
        '   (func (export "get_var") (result i32) global.get $g2)',
        ')',
    );

    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $store  = Wasm::Wasmer::Store->new();
    my $module = Wasm::Wasmer::Module->new( $ok_wasm, $store );

    my $const = $store->create_i32_const(5);
    my $var   = $store->create_i32_mut(500);

    my $instance = $module->create_instance(
        {
            mystuff => {
                myconst => $const,
                myvar   => $var,
            },
        },
    );

    is(
        $instance,
        object {
            call [ call => 'get_const' ] => 5;
            call [ call => 'get_var' ]   => 500;
        },
        'globals set as expected on instantiation',
    );

    is( $const->get(), 5,   'get() on const' );
    is( $var->get(),   500, 'get() on var' );

    my $err = dies { $const->set(6) };
    is(
        $err,
        check_set(
            match(qr<i32>),
            match(qr<global>),
        ),
        'error from set() on a constant',
    );

    $var->set(600);
    is( $var->get(),                600, 'set() on a variable import works' );
    is( $instance->call('get_var'), 600, '… confirmed via WASM accessor' );

    return;
}

sub test_global_export_types : Tests(2) {
    my $ok_wat  = _WAT_GLOBAL_TYPES;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    is(
        $instance,
        object {
            call [ export => 'my_i32' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 333;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_i64' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 333;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_f32' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 33.5;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_f64' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 33.5;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };
        },
        'export()s',
    );

    $instance->export($_)->set(37) for qw(my_i32 my_i64 my_f32 my_f64);

    is(
        $instance,
        object {
            call [ export => 'my_i32' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 37;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_i64' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 37;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_f32' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 37;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };

            call [ export => 'my_f64' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 37;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };
        },
        'export()s after set()',
    );

    return;
}

sub test_global_export : Tests(8) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    my $tellvarglobal_f = $instance->export('tellvarglobal');

    is(
        $instance,
        object {
            call [ export => 'varglobal' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 123;
                call mutability => Wasm::Wasmer::WASM_VAR;
            };
            call [ export => 'constglobal' ] => object {
                prop blessed    => 'Wasm::Wasmer::Global';
                call get        => 333;
                call mutability => Wasm::Wasmer::WASM_CONST;
            };
        },
        'export() on globals',
    );

    my $err = dies { $instance->call('varglobal') };
    is(
        $err,
        check_set(
            match(qr<function>),
            match(qr<global>),
        ),
        'error when call()ing a global',
    );

    is( $tellvarglobal_f->call(), 123, 'tellvarglobal - initial' );

    my $global      = $instance->export('varglobal');
    my $constglobal = $instance->export('constglobal');

    is(
        $global->set(234),
        $global,
        'set() return',
    );

    is( $global->get(), 234, 'set() did its thing' );

    is( $tellvarglobal_f->call(), 234, 'tellvarglobal - after set()' );

    $err = dies { $constglobal->set(11) };
    is( $err, match(qr<global>), 'error on set of constant global' );

    is(
        $instance->export('varglobal'),
        object {
            call get => 234;
        },
        'set() did its thing (new export_globals())',
    );

    return;
}

sub test_memory_export : Tests(11) {
    my $ok_wat  = _WAT;
    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    is(
        $instance->export('pagememory'),
        object {
            prop blessed => 'Wasm::Wasmer::Memory';
            call size    => 1;
            call [ get => () ], "Hello World!" . ( "\0" x 65524 );
            call [ get => 0,       12 ] => "Hello World!";
            call [ get => 6,       12 ] => "World!\0\0\0\0\0\0";
            call [ set => 'Harry', 6 ]  => T();
        },
        'export()',
    );

    is(
        $instance->export('pagememory'),
        object {
            call [ get => 0,       13 ] => "Hello Harry!\0";
            call [ set => 'Sally', 6 ]  => T();
            call [ get => 0,       13 ] => "Hello Sally!\0";

        },
        'export() - redux',
    );

    #--------------------------------------------------

    my $mem = $instance->export('pagememory');

    my $err = dies { $mem->set("\x{100}") };
    ok( $err, 'set() with wide character', explain $err);

    $mem->set("HELLO");
    is(
        $mem->get( 0, 11 ),
        "HELLO Sally",
        'set() with no offset',
    );

    $mem->set( "hahaha", -6 );
    is(
        $mem->get(-10),
        "\0\0\0\0hahaha",
        'set() with negative offset',
    );

    $err = dies { $mem->set( "hahahaha", 65534 ) };
    is(
        $err,
        check_set(
            match(qr<65534>),
            match(qr<8>),
            match(qr<65542>),
            match(qr<65536>),
        ),
        'set(): excess',
        explain $err,
    );

    $err = dies { $mem->set( "hahahaha", -3 ) };
    is(
        $err,
        check_set(
            match(qr<65533>),
            match(qr<8>),
            match(qr<65541>),
            match(qr<65536>),
        ),
        'set() with negative offset: excess',
        explain $err,
    );

    #----------------------------------------------------------------------

    $err = dies { $mem->get(); 1 };
    is(
        $err,
        check_set(
            match(qr<get>),
            match(qr<void>),
        ),
        'get() fails in void context',
    );

    $err = dies { () = $mem->get(65536) };
    is(
        $err,
        check_set(
            match(qr<65536>),
        ),
        'get() fails if given offset matches the byte length',
        explain $err,
    );

    $err = dies { () = $mem->get( 65534, 5 ) };
    is(
        $err,
        check_set(
            match(qr<65534>),
            match(qr<5>),
            match(qr<65539>),
            match(qr<65536>),
        ),
        'get() fails if offset + length exceed the byte length',
        explain $err,
    );

    is( $mem->get( 65534, 2 ), 'ha', 'last 2 bytes w/ offset & length' );

    return;
}

sub test_table_export : Tests(4) {
    my $ok_wat = q<
        (module
            (table (export "mytable") 2 4 funcref)

            (func (export "give42") (result i32) i32.const 42)

            (type $return_i32 (func (result i32)))

            (func (export "callByIndex") (param $i i32) (result i32)
                local.get $i
                call_indirect (type $return_i32)
            )
        )
    >;

    my $ok_wasm = Wasm::Wasmer::wat2wasm($ok_wat);

    my $instance = Wasm::Wasmer::Module->new($ok_wasm)->create_instance();

    is(
        $instance->export_names_ar(),
        bag {
            item 'mytable';
            item 'give42';
            item 'callByIndex';
            end();
        },
        'table export name',
        explain $instance->export_names_ar(),
    );

    my $table_obj = $instance->export('mytable');

    is(
        $table_obj,
        object {
            prop blessed => 'Wasm::Wasmer::Table';
            call size    => 2;
        },
        'table object',
    );

    SKIP: {
        skip( 'Not implemented in Wasmer yet', 2 );

        is(
            $table_obj->grow(1),
            $table_obj,
            'grow() returns the table',
        );

        is(
            $table_obj->size(),
            3,
            'grow() does its thing',
        );
    };

    return;
}

1;
