use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::GetVolatileData',
    license             => 'Artistic_2_0',
    dist_author         => q{Zoffix Znet <zoffix@cpan.org>},
    dist_version_from   => 'lib/Test/GetVolatileData.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.006',
        'Carp'           => 1.26,
        'LWP::UserAgent' => 6.00,
        'Exporter'       => '5.64_03',
    },
    add_to_cleanup     => [ 'Test-GetVolatileData-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/Test/GetVolatileData.pm > README');
}
$builder->create_build_script();
