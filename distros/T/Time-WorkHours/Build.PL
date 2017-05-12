use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Time::WorkHours',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jozef@kutej.net>',
    dist_version_from   => 'lib/Time/WorkHours.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::LectroTest::Compat' => 0,
        'Test::LectroTest::Generator' => 0,
        'Data::Dumper' => 0,
    },
    requires => {
        'DateTime' => 0,
        'Class::Accessor::Fast' => 0,
        'Carp::Clan' => 0,
    },
    add_to_cleanup      => [ 'Time-WorkHours-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
);

$builder->create_build_script();
