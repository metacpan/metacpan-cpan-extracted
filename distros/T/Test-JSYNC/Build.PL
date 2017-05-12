use 5.006;
use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'Test::JSYNC',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::Tester' => 0.107,
    },
    requires => {
        'perl'              => '5.6.0',
        'parent'            => 0,
        'JSYNC'             => 0,
        'Test::Differences' => 0.47,
        'Test::Simple'      => 0.62,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/test-jsync-pm5.git',
            homepage   => 'http://github.com/patch/test-jsync-pm5',
            bugtracker => 'http://github.com/patch/test-jsync-pm5/issues',
        },
    },
);

$builder->create_build_script();
