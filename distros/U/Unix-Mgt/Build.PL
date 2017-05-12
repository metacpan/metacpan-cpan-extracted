use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Unix::Mgt',
            'dist_abstract' => 'Unix::Mgt - lightweight Unix management tools',
            'license' => 'perl',
            'requires' => {
                            'String::Util' => '1.24',
                            'IPC::System::Simple' => '1.25',
                            'Unix::SearchPathGuess' => '0.11',
                            'JSON::Tiny' => '0.50',
                            'Capture::Tiny' => '0.25'
                          },
            'dist_version_from' => 'lib/Unix/Mgt.pm'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
