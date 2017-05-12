use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Test::Refcount',
   requires => {
      'B' => 0,
      'Scalar::Util' => 0,
      'Test::Builder' => 0,
   },
   recommends => {
      'Devel::MAT' => '0.04',
   },
   build_requires => {
      'Test::Builder::Tester' => 0,
      'Test::More' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
