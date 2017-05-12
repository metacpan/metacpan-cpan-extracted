use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::DxHash',
    license             => 'perl',
    dist_author         => 'Kevin Ruscoe <kevin@sapphireoflondon.org>',
    dist_version_from   => 'lib/Tie/DxHash.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Tie-DxHash-*' ],
);

$builder->create_build_script();
