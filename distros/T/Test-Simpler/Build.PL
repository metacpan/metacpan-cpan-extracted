use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Simpler',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Test/Simpler.pm',
    requires => {
        'Test::More'            => 0,
        'Test::Builder::Module' => 0,
        'PadWalker'             => 0,
        'Data::Dump'            => 0,
        'PPI'                   => 0,
    },
    add_to_cleanup      => [ 'Test-Simpler-*' ],
);

$builder->create_build_script();
