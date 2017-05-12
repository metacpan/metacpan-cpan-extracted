use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Structure',
    license             => 'perl',
    dist_author         => q{notbenh <notbenh@cpan.org>},
    dist_version_from   => 'lib/Test/Structure.pm',
    build_requires => {
        'Test::More' => 0,
        'PPI' => 0,
    },
    add_to_cleanup      => [ 'Test-Structure-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
