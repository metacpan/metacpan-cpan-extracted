use strict;
use warnings;
use Module::Build;

use 5.010;

my $builder = Module::Build->new(
    module_name         => 'Test::Install::METArequires',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Test/Install/METArequires.pm',
    requires => {
        'YAML::Syck'     => 0,
        'IPC::Run'       => 0,
        'Test::Builder'  => 0.82,
        'File::Basename' => 0,
    },
    build_requires => {
        'Test::More'        => 0.82,   # need $tb->note()
    },
    add_to_cleanup      => [ 'Test-Install-METArequires-*' ],
    create_makefile_pl => 'traditional',
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Test-Install-METArequires.git',
            bugtracker => 'http://github.com/jozef/Test-Install-METArequires/issues',
        },
        keywords => [ qw/ test install META.yml requires / ],
    },
);

$builder->add_build_element('t');
$builder->create_build_script();
