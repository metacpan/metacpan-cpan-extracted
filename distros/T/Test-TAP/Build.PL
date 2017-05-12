use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::TAP',
    license             => 'perl',
    dist_author         => 'Curtis Poe <ovid@cpan.org>',
    dist_version_from   => 'lib/Test/TAP.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-TAP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
