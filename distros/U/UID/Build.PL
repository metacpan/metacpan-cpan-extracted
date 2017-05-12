use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	distribution_type   => 'module',
    module_name         => 'UID',
    dist_abstract       => 'Define unique identifier objects that can be used like a kind of keyword',
    dist_author         => 'David Green <plato@cpan.org>',
    license             => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'UID-*' ],
);

$builder->create_build_script();
