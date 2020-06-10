use 5.008004;
use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Module::Imports;
use YAML qw( Dump );

{
  my $module = Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func $hello (import "" "add"))
    )
  });
  my $imports = Wasm::Wasmtime::Module::Imports->new($module);
  is(
    $imports,
    object {
      call [ isa => 'Wasm::Wasmtime::Module::Imports' ] => T();

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
          call [ isa => 'Wasm::Wasmtime::ImportType' ] => T();
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
    'imports object looks good'
  );
  note Dump($imports);
}

done_testing;
