use strict;
use warnings;

use Module::Build;

Module::Build->new(
        module_name => 'Text::Trim',
        requires => {
            perl => '5',
        },
        build_requires => {
            'Test::More' => 0,
        },
        license => 'perl',
        create_makefile_pl => 'passthrough',
        create_readme => 1,
    )->create_build_script;
