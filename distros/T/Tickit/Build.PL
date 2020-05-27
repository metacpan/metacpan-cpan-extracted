use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Tickit',
   requires => {
      'Exporter' => '5.57',
      'perl' => '5.014', # PL_phase
      'Struct::Dumb' => '0.04',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::Builder::Tester' => 0,
      'Test::Fatal' => 0,
      'Test::HexString' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->use_pkgconfig( "tickit",
   atleast_version => "0.4.0",
   alien         => "Alien::libtickit",
   alien_version => "0.09",
);

$build->create_build_script;
