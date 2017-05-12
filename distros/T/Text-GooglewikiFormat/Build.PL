use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::GooglewikiFormat',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Text/GooglewikiFormat.pm',
    build_requires => {
        'Test::More' => 0,
        'Scalar::Util' => 0,
        'URI'         => 0,
        'URI::Escape' => 0,
        'URI::Find'   => 0,
    },
    add_to_cleanup      => [ 'Text-GooglewikiFormat-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
