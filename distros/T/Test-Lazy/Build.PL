use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Lazy',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Test/Lazy.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Test::Deep' => 0,
        'Data::Dumper' => 0,
        'Carp' => 0,
        'Class::Accessor::Fast' => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Test-Lazy-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
