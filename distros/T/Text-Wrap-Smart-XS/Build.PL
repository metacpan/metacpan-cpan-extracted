## Created by make2build 0.17

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Text::Wrap::Smart::XS',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Text/Wrap/Smart/XS.pm',
   requires => {
                 'boolean' => 0,
                 'Carp' => 0,
                 'Params::Validate' => 0,
               },
   test_requires => {
                      'ExtUtils::CBuilder' => 0,
                      'Test::More' => 0,
                    },
   xs_files => { 'XS.xs' => 'lib/Text/Wrap/Smart/XS.xs' },
   include_dirs => [ '.' ],
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Text-Wrap-Smart-XS',
       },
   },
  );

$build->create_build_script;
