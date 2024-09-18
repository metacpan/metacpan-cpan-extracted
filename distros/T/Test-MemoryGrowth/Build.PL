use v5;
use strict;
use warnings;

use Module::Build;

grep { $^O eq $_ } qw(
   linux
   freebsd
) or die "OS unsupported - see TODO note about OS-specific memory usage query\n";

my $build = Module::Build->new(
   module_name => 'Test::MemoryGrowth',
   requires => {
      'perl' => '5.014',

      'Test::Builder' => 0,
   },
   recommends => {
      'Devel::Gladiator' => 0,
      'Devel::MAT' => '0.04',
   },
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   test_requires => {
      'Test::Builder::Tester' => 0,
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;
