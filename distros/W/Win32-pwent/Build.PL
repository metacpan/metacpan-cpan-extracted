use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Win32::pwent',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/Win32/pwent.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'File::Spec' => 0,
        'Win32' => 0,
        'Win32::NetAdmin' => 0.11,
        'Win32::Registry' => 0,
        'Win32API::Net' => 0.13,
    },
    add_to_cleanup      => [ 'Win32-pwent-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
