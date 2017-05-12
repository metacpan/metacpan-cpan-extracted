use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'XML::Filter::Conditional',
   dist_version_from => 'lib/XML/Filter/Conditional.pm',
   requires => {
                 'XML::SAX::Base' => 0,
               },
   build_requires => {
                        'Test::More' => 0,
                        'Test::Exception' => 0,
                        'XML::SAX::Base' => '1.04',
                        'XML::SAX::ParserFactory' => '1.00',
                     },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
  );
  
$build->create_build_script;
