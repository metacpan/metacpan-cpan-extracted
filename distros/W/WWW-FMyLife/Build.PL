use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'WWW::FMyLife',
    license              => 'perl',
    dist_author          => [
        q{Sawyer X <xsawyerx@cpan.org>},
        q{Tamir Lousky <tlousky@cpan.org>},
    ],
    dist_version_from    => 'lib/WWW/FMyLife.pm',
    build_requires   => {
        'Net::Ping'                 => 0,
        'Test::More'                => 0.88,
        'Test::Deep'                => 0,
        'Sub::Override'             => 0,
        'Test::MockObject::Extends' => 0,
    },
    requires             => {
        'Moose'          => 0.86,
        'LWP::UserAgent' => 0,
        'XML::Simple'    => 2.18
    },
    recursive_test_files => 1,
    add_to_cleanup       => [ 'WWW-FMyLife-*' ],
    create_makefile_pl   => 'traditional',
    meta_merge           => {
        resources => {
            repository => 'http://github.com/xsawyerx/www-fmylife/',
        },
        keywords   => [ 'fml', 'fmylife' ],
    },
    create_readme        => 1,
    create_license       => 1,
);

$builder->create_build_script();
