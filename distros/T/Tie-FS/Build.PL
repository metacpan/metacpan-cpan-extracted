use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::FS',
    license             => 'perl',
    dist_author         => q{Deven T. Corzine <deven@ties.org>},
    dist_version_from   => 'lib/Tie/FS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Tie-FS-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
