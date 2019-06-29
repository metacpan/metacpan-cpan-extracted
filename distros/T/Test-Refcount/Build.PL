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
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::Builder::Tester' => 0,
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_manify_args => {
      utf8 => 1, # We have UTF-8 manpages
   },
);

$build->create_build_script;
