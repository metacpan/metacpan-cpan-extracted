use strict;
use Module::Build;

Module::Build->new(
    module_name => "UNIVERSAL::canAUTOLOAD",
    license     => 'perl',
    requires    => {
        'Test::More' => 0,
        'Class::ISA' => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
