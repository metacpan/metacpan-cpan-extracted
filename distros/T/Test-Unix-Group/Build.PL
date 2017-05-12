use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Unix::Group',
    license             => 'bsd',
    dist_author         => 'Nik Clayton <nik@FreeBSD.org>',
    dist_version_from   => 'lib/Test/Unix/Group.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-Unix-Group-*' ],
    sign		=> 1,
    create_readme	=> 1,
);

$builder->create_build_script();
