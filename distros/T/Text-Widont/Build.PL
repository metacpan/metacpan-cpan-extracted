use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [ 'Text-Widont-*' ],
    build_requires     => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    dist_version_from  => 'lib/Text/Widont.pm',
    license            => 'perl',
    module_name        => 'Text::Widont',
    requires           => {
        'Carp' => 0,
    },
);

$builder->create_build_script();
