## Created by make2build 0.17

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Text::Wrap::Smart',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Text/Wrap/Smart.pm',
   requires => {
                 'boolean' => 0,
                 'Math::BigFloat' => 0,
                 'Params::Validate' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Text-Wrap-Smart',
       },
   },
  );

$build->create_build_script;
