use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Symlink',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Test/Symlink.pm',
    requires => {
        'Test::More' => 0,
	'Test::Tester' => 0.102,
	'Test::Builder' => 0,
    },
    add_to_cleanup      => [ 'Test-Symlink-*' ],
    'create_readme',
    'sign',
);

$builder->create_build_script();
