use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'lib::remote',
    dist_abstract	=> 'Remote lib for use some modules without install',
    license             => 'perl',
    dist_author         => q{Mikhail Che <mche#cpan.org>},
    dist_version_from   => 'lib/lib/remote.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'LWP::UserAgent'=> 0,
    },
    add_to_cleanup      => [ 'lib-remote-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
