use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test2::Tools::Wasm;
use Wasm::Wasmtime::Store;
use Wasm::Wasmtime::Module;
use Wasm::Wasmtime::Wat2Wasm;

is(
  Wasm::Wasmtime::Module->new(wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'autocreate store',
);

is(
  dies { Wasm::Wasmtime::Module->new('f00f') },
  match qr/error creating module/,
  'exception for bad wasm',
);

is(
  Wasm::Wasmtime::Module->new(Wasm::Wasmtime::Store->new, wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'explicit store',
);

is(
  Wasm::Wasmtime::Module->new(wat => '(module)'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'wat key',
);

is(
  Wasm::Wasmtime::Module->new(wasm => wat2wasm('(module)')),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'wasm key',
);

is(
  Wasm::Wasmtime::Module->new(file => 'examples/gcd.wat'),
  object {
    call ['isa', 'Wasm::Wasmtime::Module'] => T();
    call store => object {
      call ['isa', 'Wasm::Wasmtime::Store'] => T();
    };
  },
  'file key',
);

is(
  scalar(Wasm::Wasmtime::Module->validate(wat2wasm('(module)'))),
  T(),
  'validate good',
);

is(
  [Wasm::Wasmtime::Module->validate(wat2wasm('(module)'))],
  array {
    item T();
    item '';
    end;
  },
  'validate good, list context',
);

is(
  scalar(Wasm::Wasmtime::Module->validate( wat => '(module)' )),
  T(),
  'validate good, key wat',
);

is(
  scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat2wasm('(module)'))),
  T(),
  'validate good with store',
);

is(
  scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, wat => '(module)')),
  T(),
  'validate good with store, key wat',
);

is(
  scalar(Wasm::Wasmtime::Module->validate('f00f')),
  F(),
  'validate bad',
);

is(
  [Wasm::Wasmtime::Module->validate('f00f')],
  array {
    item F();
    item match qr/./;
    end;
  },
  'validate bad, list context',
);

is(
  scalar(Wasm::Wasmtime::Module->validate(Wasm::Wasmtime::Store->new, 'f00f')),
  F(),
  'validate bad with store',
);

is(
  Wasm::Wasmtime::Module->new(wat => q{
    (module
      (func (export "add") (param i32 i32) (result i32)
        local.get 0
        local.get 1
        i32.add)
      (func (export "sub") (param i64 i64) (result i64)
        local.get 0
        local.get 1
        i64.sub)
      (memory (export "frooble") 2 3)
    )
  }),
  object {
    call [ get_export => 'add' ] => object {
      call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
    };
    call [ get_export => 'foo' ] => U();
    call_list imports => [];
    call_list exports => array {
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'add';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
          call kind => 'func';
          call as_functype => object {
            call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
            call_list params => array {
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i32';
              };
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i32';
              };
              end;
            };
            call_list results => array {
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i32';
              };
              end;
            };
          };
        };
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'sub';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
          call kind => 'func';
          call as_functype => object {
            call [ isa => 'Wasm::Wasmtime::FuncType' ] => T();
            call_list params => array {
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i64';
              };
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i64';
              };
              end;
            };
            call_list results => array {
              item object {
                call [ isa => 'Wasm::Wasmtime::ValType' ] => T();
                call kind => 'i64';
              };
              end;
            };
          };
        };
      };
      item object {
        call [ isa => 'Wasm::Wasmtime::ExportType' ] => T();
        call name => 'frooble';
        call type => object {
          call [ isa => 'Wasm::Wasmtime::ExternType' ] => T();
          call kind => 'memory';
          call as_functype => U();
        };
      };
      end;
    };
  },
  'exports',
);

wasm_module_ok '(module)';

done_testing;
