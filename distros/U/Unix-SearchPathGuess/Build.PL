use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Unix::SearchPathGuess -- Make an educated guess for $ENV{\'PATH\'} in a Unixish system',
            'module_name' => 'Unix::SearchPathGuess',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'dist_version_from' => 'lib/Unix/SearchPathGuess.pm',
            'requires' => {
                            'File::Which' => '1.09',
                            'Test' => 0
                          },
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
