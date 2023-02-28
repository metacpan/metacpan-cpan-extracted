## Created by make2build 0.17

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Tie::DiskUsage',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Tie/DiskUsage.pm',
   requires => {
                 'Carp' => 0,
                 'Cwd' => 0,
                 'File::Which' => 0,
                 'Symbol' => 0,
               },
   test_requires => {
                      'File::Spec' => 0,
                      'File::Temp' => 0,
                      'FindBin' => 0,
                      'Test::More' => 0,
                    },
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Tie-DiskUsage',
       },
   },
  );

$build->create_build_script;
