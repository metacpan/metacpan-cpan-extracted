use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Test::Future::IO::Impl',
   requires => {
      'perl' => '5.014',

      # core modules
      'Errno' => 0,
      'IO::Handle' => 0,
      'Socket' => 0,
      'Time::HiRes' => 0,

      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
