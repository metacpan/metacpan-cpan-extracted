use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Universe::Galaxy',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Universe/Galaxy.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Universe-Galaxy-*' ],
    create_makefile_pl => 'traditional',
    create_readme       => 1,
    sign                => 1,
);

$builder->create_build_script();
