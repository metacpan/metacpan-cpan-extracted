use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Timeout::Queue',
    license            => 'perl',
    dist_author        => 'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/Timeout/Queue.pm',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 
        'Timeout-Queue-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
