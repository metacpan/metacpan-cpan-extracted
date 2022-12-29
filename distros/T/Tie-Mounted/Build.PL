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
                 'boolean' => 0,
                 'Carp' => 0,
                 'File::Which' => 0,
                 'IO::File' => 0,
                 'Tie::Array' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Tie-Mounted',
       },
   },
  );

$build->create_build_script;
