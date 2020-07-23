use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Trap;

is(
  Wasm::Trap->new("foo\0"),
  object {
    call [isa => 'Wasm::Trap'] => T();
    call message => 'foo';
    call sub { my $trap = shift; "$trap" } => "foo\n";
    call exit_status => undef;
  },
  'created trap ok',
);

{
  package Frooble;

  require Wasm;
  Wasm->import(
    -api => 0,
    -wat => q{
      (module
        (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))
        (memory 10)
        (export "memory" (memory 0))
        (func (export "do_exit")
          (call $proc_exit (i32.const 7))
        )
      )
    },
  );
}

is(
  dies { Frooble::do_exit() },
  object {
    call [ isa => 'Wasm::Trap' ] => T();
    call exit_status => 7;
  },
);

done_testing;
