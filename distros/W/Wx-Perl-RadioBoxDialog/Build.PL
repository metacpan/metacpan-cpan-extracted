use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wx::Perl::RadioBoxDialog',
    license             => 'Artistic_2_0',
    dist_author         => q{Tarek Unger <tu2@gmx.net>},
    dist_version_from   => 'lib/Wx/Perl/RadioBoxDialog.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Wx' => 0,
    },
    add_to_cleanup     => [ 'Wx-Perl-RadioBoxDialog-*' ],
    create_makefile_pl => 'traditional',
    
    meta_merge => {
        resources => {
            repository => 'https://github.com/taunger/Config-Source'
        }
    },
);

$builder->create_build_script();
