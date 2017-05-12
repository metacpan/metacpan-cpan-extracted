use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Xen::Control',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Xen/Control.pm',
    requires => {
        'Carp::Clan'            => 0,
        'Class::Accessor::Fast' => 0,
        'Getopt::Long'          => 0,
        'Pod::Usage'            => 0,
        'List::MoreUtils'       => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Environment' => 0,
        'Test::Differences' => 0,
    },
    script_files => [
        'script/xmc',
    ],
    add_to_cleanup     => [ 'Xen-Control-*' ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    sign               => 1,
);

$builder->create_build_script();
