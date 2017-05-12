use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Tie::Locked -- lock hashes so that they cannot be easily changed',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Tie::Locked',
            'requires' => {},
            'dist_version_from' => 'lib/Tie/Locked.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
