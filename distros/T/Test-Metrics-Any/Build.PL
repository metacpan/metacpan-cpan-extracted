use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Test::Metrics::Any',
   requires => {
      'perl' => '5.020',

      'Metrics::Any::Adapter' => 0,
      'Metrics::Any::Adapter::Test' => 0,
      'Test::Builder::Module' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
