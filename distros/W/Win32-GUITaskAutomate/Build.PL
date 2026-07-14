#!perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Win32::GUITaskAutomate',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/Win32/GUITaskAutomate.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        Carp            => 1.04,
        'Win32::GUIRobot' => 0.05,
        'Win32::Clipboard' => 0.5201,
    },
    add_to_cleanup      => [ 'Win32-GUITaskAutomate-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
