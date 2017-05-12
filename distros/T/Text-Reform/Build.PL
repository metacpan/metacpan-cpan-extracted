use 5.005;
use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Reform',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Text/Reform.pm',
    requires => {
#        'version'    => 0,
        'Exporter'   => 0,
        'perl'       => 5.005,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Text-Reform-*' ],
);

$builder->create_build_script();
