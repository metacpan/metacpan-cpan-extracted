use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'random',
    license             => 'perl',
    dist_author         => 'JMELTZER <joerg@joergmeltzer.de>',
    dist_version_from   => 'lib/random.pm',
    requires => {
        'perl'       => '5.010',
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'random-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
