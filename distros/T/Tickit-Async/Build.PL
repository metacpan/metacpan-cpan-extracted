use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Async',
   requires => {
      'IO::Async' => '0.47',
      'IO::Async::Notifier' => '0.43',
      'IO::Async::Stream' => '0.34',
      'IO::Async::Test' => 0,
      'Tickit' => '0.72',
   },
   test_requires => {
      'Test::HexString' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
