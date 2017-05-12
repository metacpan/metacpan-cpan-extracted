use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tk::Chart',
    license             => 'perl',
    dist_author         => q{Djibril Ousmanou <djibel@cpan.org>},
    dist_version_from   => 'lib/Tk/Chart.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Tk::Canvas::GradientColor' => '1.04',
        'Tk' => 800,
        'POSIX' => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    add_to_cleanup      => [ 'Tk-Chart-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
