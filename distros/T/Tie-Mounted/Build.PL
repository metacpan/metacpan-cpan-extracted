## Created by make2build 0.17

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Tie::Mounted',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Tie/Mounted.pm',
   requires => {
                 'Carp' => 0,
                 'File::Which' => 0,
                 'IO::File' => 0,
                 'Symbol' => 0,
                 'Tie::Array' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   recommends => {
                   'Test::Pod' => '1.14',
                   'Test::Pod::Coverage' => '1.04',
                 },
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
