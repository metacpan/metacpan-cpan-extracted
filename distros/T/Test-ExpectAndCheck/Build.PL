use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Test::ExpectAndCheck',
   requires => {
      'List::Util' => 0,
      'Test::Builder' => '1.302', # subtest indentation format
      'Test::Deep' => 0,
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
);

$build->create_build_script;
