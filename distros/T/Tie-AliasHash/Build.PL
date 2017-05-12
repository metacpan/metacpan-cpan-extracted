use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::AliasHash',
    license             => 'perl',
    dist_author         => q{Aldo Calpini <dada@perl.it>},
    dist_version_from   => 'lib/Tie/AliasHash.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    add_to_cleanup      => [ 'Tie-AliasHash-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/dada/Tie-AliasHash',
        },
    },
);

$builder->create_build_script();
