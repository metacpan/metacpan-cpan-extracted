use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_version_from' => 'lib/Test/Toolbox.pm',
            'requires' => {},
            'dist_abstract' => 'Test::Toolbox - tools for testing',
            'module_name' => 'Test::Toolbox',
            'license' => 'perl',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
