use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name => 'URI::Builder',
    requires    => {
        'perl' => '5.6.0',
        'URI'  => '1.60',
    },
    configure_requires => {
        'Module::Build' => '0.38',
    },
    create_makefile_pl => 'small',
    create_readme      => 1,
    license            => 'artistic',
)->create_build_script;
