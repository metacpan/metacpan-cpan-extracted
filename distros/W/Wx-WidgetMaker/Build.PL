use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    'dist_author' => 'Scott Lanning <lannings@who.int>',
    'module_name' => 'Wx::WidgetMaker',
    'build_requires' => {
        'Test::More'          => 0,
    },
#    'create_makefile_pl' => 'passthrough',
    'create_makefile_pl' => 'traditional',
    'requires' => {
        'Wx'                  => '0.13',
        'perl'                => '5.6.1',
    },
    'recommends' => {
        'Module::Build'       => '0.25',
    },
#    'sign' => 1,
    'license' => 'perl',
);

$build->create_build_script();
