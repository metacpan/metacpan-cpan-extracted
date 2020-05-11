use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Func;
use Wasm::Wasmtime::FuncType;

my $add;

is(
  $add = wasm_func_ok( add => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
    )
  }),
  object {
    call [ call => 1, 2 ] => 3;
    call [ call => 3, 4 ] => 7;
    call type => object {
      call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
    };
    call param_arity => 2;
    call result_arity => 1;

    call is_func   => T();
    call is_global => F();
    call is_table  => F();
    call is_memory => F();
    call kind      => 'func';
  },
  'call add',
);

if($add)
{
  { package Foo::Bar;
    $add->attach('baz');
    sub optimus {}
  }
  ok(Foo::Bar->can('baz'), 'attached using caller');
  is(Foo::Bar::baz(9,9), 18, 'calling attached Foo::Bar::baz');

  is(
    warnings { $add->attach('Foo::Bar', 'optimus') },
    bag {
      item match qr/attaching Foo::Bar::optimus replaces existing subroutine .*wasm_wasmtime_func\.t/;
      etc;
    },
    'warns about redefine'
  );

  ok(Foo::Bar->can('optimus'), 'attached using caller');
  is(Foo::Bar::optimus(9,9), 18, 'calling attached Foo::Bar::optimus');

  { package Foo;
    $add->attach('Bar', 'baz');
  }
  undef $add;
  ok(!Foo->can('baz'), 'attach using explicit package does not install in caller');
  ok(Bar->can('baz'), 'attach using explicit package');
  is(Bar::baz(9,9), 18, 'calling attached Bar::baz');

}

is(
  wasm_func_ok( round_trip_many => q{
    (module
  (func $round_trip_many
    (export "round_trip_many")
    (param i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)
    (result i64 i64 i64 i64 i64 i64 i64 i64 i64 i64)

    local.get 0
    local.get 1
    local.get 2
    local.get 3
    local.get 4
    local.get 5
    local.get 6
    local.get 7
    local.get 8
    local.get 9)
    )
  }),
  object {
    call_list [ call => 0,1,2,3,4,5,6,7,8,9 ] => [0,1,2,3,4,5,6,7,8,9];
  },
  'call round_trip_many',
);

{
  my $it_worked;

  my $f = Wasm::Wasmtime::Func->new(
    Wasm::Wasmtime::Store->new,
    Wasm::Wasmtime::FuncType->new([],[]),
    sub { $it_worked = 1 },
  );

  is(
    $f,
    object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
    },
    'create functon with no arguments/results',
  );

  try_ok { $f->call } 'call function';

  is(
    $it_worked,
    T(),
    'it worked',
  );
}

{
  my $it_worked;

  my $f = Wasm::Wasmtime::Func->new(
    Wasm::Wasmtime::Store->new,
    [],[],
    sub { $it_worked = 1 },
  );

  is(
    $f,
    object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
    },
    'create functon with no arguments/results',
  );

  try_ok { $f->call } 'call function';

  is(
    $it_worked,
    T(),
    'it worked',
  );
}

{
  my @it_worked;

  my $f = Wasm::Wasmtime::Func->new(
    Wasm::Wasmtime::Store->new,
    ['i32','i32'],[],
    sub { @it_worked = @_ },
  );

  is(
    $f,
    object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
    },
    'create functon with arguments',
  );

  try_ok { $f->call(1,2) } 'call function';

  is(
    \@it_worked,
    [1,2],
    'it worked',
  );
}

{
  my $it_worked;

  my $f = Wasm::Wasmtime::Func->new(
    Wasm::Wasmtime::Store->new,
    [],['i32'],
    sub { return 42 },
  );

  is(
    $f,
    object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
    },
    'create functon with arguments',
  );

  try_ok { $it_worked = $f->call } 'call function';

  is(
    $it_worked,
    42,
    'it worked',
  );
}

{
  my $f = Wasm::Wasmtime::Func->new(
    Wasm::Wasmtime::Store->new,
    Wasm::Wasmtime::FuncType->new([],[]),
    sub { die 'it dies' },
  );

  is(
    $f,
    object {
      call [ isa => 'Wasm::Wasmtime::Func' ] => T();
    },
    'create functon with an exception',
  );

  is(
    dies { $f->call },
    match qr/it dies/,
    'it died',
  );

}

done_testing;
