use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::ECSV',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Text/ECSV.pm',
    configure_requires => {
        'Module::Build' => '0.38',
    },
    requires => {
        'Text::CSV_XS'          => 0,
        'Class::Accessor::Fast' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Text-ECSV-*' ],
    create_readme       => 1,
);

$builder->create_build_script();
