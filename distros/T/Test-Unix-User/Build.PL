use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Unix::User',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Test/Unix/User.pm',
    requires => {
        'Test::More' => 0,
	'Test::Builder' => 0,
	'Test::Tester' => 0.102,
    },
    add_to_cleanup      => [ 'Test-Unix-User-*' ],
    create_readme	=> 1,
    sign		=> 1,
    create_makefile_pl	=> 'passthrough',
);

$builder->create_build_script();
