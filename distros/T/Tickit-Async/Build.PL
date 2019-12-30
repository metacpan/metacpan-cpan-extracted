use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Tickit::Async',
   requires => {
      'IO::Async' => '0.47',
      'IO::Async::Notifier' => '0.43',
      'IO::Async::Stream' => '0.34',
      'IO::Async::Test' => 0,
      'Tickit' => '0.69', # Tickit::_Tickit->_new_with_evloop
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

$build->use_pkgconfig( "tickit",
   atleast_version => "0.3",
   alien         => "Alien::libtickit",
   alien_version => "0.04",
);

$build->create_build_script;
