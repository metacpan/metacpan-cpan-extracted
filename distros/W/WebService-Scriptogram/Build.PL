use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Scriptogram',
    license             => 'perl',
    dist_author         => q{Steve Huff <shuff@cpan.org>},
    dist_version_from   => 'lib/WebService/Scriptogram.pm',
    build_requires => {
        'Test::More'          => 0,
        'Test::Perl::Critic'  => 0,
        'Test::Pod::Coverage' => 1.04,
        'Test::Pod'           => 1.14,
    },
    configure_requires => {
        'Module::Build' => 0.40,
    },
    requires => {
        'perl'               => 5.006,
        'Params::Validate'   => 0,
        'Readonly'           => 0,
        'WebService::Simple' => 0,
    },
    meta_merge => {
        resources => {
            homepage   => 'https://github.com/hakamadare/webservice-scriptogram',
            bugtracker => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Scriptogram',
            repository => 'git://github.com/hakamadare/webservice-scriptogram.git',
        },
    },
    add_to_cleanup      => [ 'WebService-Scriptogram-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
