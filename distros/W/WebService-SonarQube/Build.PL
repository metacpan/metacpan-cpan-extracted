use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'WebService::SonarQube',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/WebService/SonarQube.pm',
    requires          => {
        'perl'             => 5.010,
        'JSON'             => '2.00',
        'Moo'              => '1.006001',
        'Path::Tiny'       => 0,
        'Try::Tiny'        => '0.22',
        'Type::Tiny'       => '1.000005',
        'Types::Standard'  => '1.000005',
        'URI'              => '1.64',
        'WWW::Mechanize'   => '1.73',
        'namespace::clean' => '0.25',
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'WebService-SonarQube-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/WebService-SonarQube.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService::SonarQube',
        },
    },
);

$builder->create_build_script();
