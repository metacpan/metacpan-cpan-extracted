use strict;
use Module::Build;

Module::Build
  ->new( module_name => "URI::Find::Iterator",
         license     => 'perl',
         requires    => {
                         'URI::Find'          => 0,
                         'Test::More'         => 0,
                         'UNIVERSAL::require' => 0,
                        },
         create_makefile_pl => 'passthrough',
       )
  ->create_build_script;



