use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    meta_merge => {
        resources => {
            repository => 'http://github.com/duncs/perl-test-noplan',
            bugtracker =>
                'https://rt.cpan.org/Public/Dist/Display.html?Name=Test-NoPlan',
            homepage => 'http://github.com/duncs/perl-test-noplan',
        },
    },

    module_name       => 'Test::NoPlan',
    license           => 'perl',
    dist_author       => 'Duncan Ferguson <duncan_j_ferguson@yahoo.co.uk>',
    dist_version_from => 'lib/Test/NoPlan.pm',
    build_requires    => {
        'version'    => 0,
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'Test-NoPlan-*', 'Debian_CPANTS.txt', ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
