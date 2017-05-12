use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Text::DeSupercite",
         license     => 'perl',
         requires    => {
                          'Test::More'    => 0,
                          'Text::Quoted'  => 0,
                        },
         create_makefile_pl => 'passthrough',
         script_files       => ['desupercite'],
       );

$build->create_build_script;

