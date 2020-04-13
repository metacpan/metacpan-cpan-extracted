use Test2::V0 -no_srand => 1;
use Wasm;

try_ok  { Wasm->import( -api => 0 );    }                                                   'works with -api => 0 ';
is(dies { Wasm->import( -api => 2 );    }, match qr/Currently only -api => 0 is supported/, 'dies with non 0 api level');
is(dies { Wasm->import( -foo => 'bar'); }, match qr/You MUST specify an api level as the first option/,
                                                                                            'bad key ');
is(dies { Wasm->import( -api => 0, -api => 0 ) },
                                           match qr/Specified -api more than once/,         'api more than once');
try_ok  { Wasm->import( -api => 0, -wat => '(module)' ) }                                   'empty module';

{
  package Foo0;
  use Wasm -api => 0, -wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "subtract") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.sub)
      (memory (export "frooble") 2 3)
    )
  };
}

is( Foo0::add(1,2), 3, '1+2=3' );
is( Foo0::subtract(3,2), 1, '3-2=1' );

{
  package Foo1;
  use Wasm -api => 0, -file => 'corpus/wasm/Math.wat';
}

is( Foo1::add(1,2), 3, '1+2=3' );
is( Foo1::subtract(3,2), 1, '3-2=1' );

{
  package Foo2;
  use File::Temp qw( tempdir );
  use Path::Tiny qw( path );
  use Wasm -api => 0, -file => do {
    my $wat  = path('corpus/wasm/Math.wat');
    #my $wasm = path(tempdir( CLEANUP => 1 ))->child('math.wasm');
    my $wasm = path('corpus/wasm/Math.wasm');
    require Wasm::Wasmtime::Wat2Wasm;
    $wasm->spew_raw(Wasm::Wasmtime::Wat2Wasm::wat2wasm($wat->slurp_utf8));
    $wasm->stringify;
  };
}

is( Foo2::add(1,2), 3, '1+2=3' );
is( Foo2::subtract(3,2), 1, '3-2=1' );

require './corpus/wasm/Math.pm';

is( Math::add(1,2), 3, '1+2=3' );
is( Math::subtract(3,2), 1, '3-2=1' );

{
  package Foo3;
  use Wasm -api => 0, -package => 'Foo4', -file => 'corpus/wasm/Math.wat';
}

ok( !Foo3->can('add'), 'did not export into Foo3' );
is( Foo4::add(1,2), 3, '1+2=3' );
is( Foo4::subtract(3,2), 1, '3-2=1' );

{
  package Foo5;
  use Wasm -api => 0, -exporter => 'ok', -file => 'corpus/wasm/Math.wat';
  BEGIN { $INC{'Foo5.pm'} = __FILE__ }
}

{
  package Foo6;
  use Foo5 qw( add subtract );
}

{
  package Foo7;
  use Foo5;
}

ok( !Foo7->can('add'), 'did not export into Foo7' );
is( Foo6::add(1,2), 3, '1+2=3' );
is( Foo6::subtract(3,2), 1, '3-2=1' );

{
  package Foo8;
  use Wasm -api => 0, -exporter => 'all', -file => 'corpus/wasm/Math.wat';
  BEGIN { $INC{'Foo8.pm'} = __FILE__ }
}

{
  package Foo9;
  use Foo8;
}

is( Foo9::add(1,2), 3, '1+2=3' );
is( Foo9::subtract(3,2), 1, '3-2=1' );

{
  # huh?
  # Exception: trap in wasm function call: wasm trap: call stack exhausted, source location: @- at t/wasm.t line 117
  # same thing works in t/wasm_wasmtime_instance.t
  my $it_worked;
  {
    package Foo10;
    use Wasm -api => 0, -imports => [sub { warn 'here'; $it_worked = 1 }], -wat => q{
      (module
        (func $hello (import "" "hello"))
        (func (export "run") (call $hello))
      )
    }
  }

  if(0)
  {
    try_ok { Foo10::run() } 'Foo10::run()';
    is $it_worked, T();
  }
}

done_testing;
