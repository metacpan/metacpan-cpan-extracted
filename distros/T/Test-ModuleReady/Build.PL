use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::ModuleReady',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Test/ModuleReady.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp'              => '1.08',
        'Pod::Checker'      => '1.45',
        'Test::More'        => '0.94',
        'Test::Spelling'    => '0.11',
    },
    add_to_cleanup      => [ 'Test-ModuleReady-*' ],
);

$builder->create_build_script();
