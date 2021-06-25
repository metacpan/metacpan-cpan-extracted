use Test2::V0 -no_srand => 1;
use Test2::Plugin::FFI::Package;
use Test2::Tools::FFI;

ffi_options api => 1;

subtest 'ffi->runtime' => sub {

  my $ffi = ffi->runtime;

  is
    $ffi,
    object {
      call [ isa => 'FFI::Platypus' ] => T();
      call api => 1;
      call [ symbol_ok => 't2t_simple_init' ] => T();
    },
  ;

};

subtest 'ffi->test' => sub {

  my $ffi = ffi->test;

  is
    $ffi,
    object {
      call [ isa => 'FFI::Platypus' ] => T();
      call api => 1;
      call [ function => myanswer => [] => 'int' ] => object {
        call call => 42;
      };
      call [ symbol_ok => 'myanswer' ] => T();
    },
  ;

};

subtest 'ffi->combined' => sub {

  my $ffi = ffi->combined;

  is
    $ffi,
    object {
      call [ isa => 'FFI::Platypus' ] => T();
      call api => 1;
      call [ function => 'myanswer' => [] => 'int' ] => object {
        call call => 42;
      };
      call [ symbol_ok => 't2t_simple_init' ] => T();
      call [ symbol_ok => 'myanswer' ] => T();
    }
  ;

  lives { $ffi->function(t2t_simple_init => [] => 'void') };
};

done_testing
