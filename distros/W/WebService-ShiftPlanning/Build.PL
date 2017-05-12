use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::ShiftPlanning',
    license             => 'perl',
    dist_author         => q{Craig Ringer <ringerc@cpan.org>},
    dist_version_from   => 'lib/WebService/ShiftPlanning.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'       => 6.00,
        'LWP::Protocol::https' => 6.00,
    },
    add_to_cleanup     => [ 'WebService-ShiftPlanning-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
