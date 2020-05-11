use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Module::Exports;
use YAML qw( Dump );

{
  my $module = Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
    )
  });
  my $exports = Wasm::Wasmtime::Module::Exports->new($module);
  is(
    $exports,
    object {
      call [ isa => 'Wasm::Wasmtime::Module::Exports' ] => T();
      call add => object {
        call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
      };

      # test %{} overload
      call sub { \%{ shift() } } => hash {
        field add => object {
          call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
        };
        end;
      };

      # test that you can't insert a new key
      call sub { my $exports = shift; dies { $exports->{foo} = 1 } } => D();

      # test that you can't replace an existing key
      call sub { my $exports = shift; dies { $exports->{add} = 1 } } => D();

      # hopefully we can still modify the values themselves?
      call sub { my $exports = shift; lives { $exports->{add}->{rando1} = 1 } } => T();

      call sub { \@{ shift() } } => array {
        item object {
          call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
          call name => 'add';
          call type => object {
            call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
          };
        };
        end;
      };

      call sub { my $exports = shift; dies { $exports->[0] = 1 } } => D();
      call sub { my $exports = shift; dies { $exports->[1] = 1 } } => D();
      call sub { my $exports = shift; lives { $exports->[0]->{rando2} = 1 } } => T();
    },
    'exports object looks good'
  );
  note Dump($exports);
}

done_testing;
