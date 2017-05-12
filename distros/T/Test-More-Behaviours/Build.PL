use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::More::Behaviours',
    license             => 'perl',
    dist_author         => 'Rija Menage <cpan@rijam.sent.as>',
    dist_version_from   => 'lib/Test/More/Behaviours.pm',
    requires => {
        'Test::More'    => 0,
        'version'       => 0,
        'Sub::Uplevel'  => '0.16',
    },
    add_to_cleanup      => [ 'Test-More-Behaviours-*' ],
);

$builder->create_build_script();
