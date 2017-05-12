use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'Unicode::Util',
    license              => 'perl',
    create_license       => 1,
    create_readme        => 1,
    recursive_test_files => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0.41,  # diag()
        'Test::Warn' => 0.01,
    },
    requires => {
        'perl'   => '5.8.0',  # minimum Unicode support
        'parent' => 0,
    },
    recommends => {
        'perl'   => '5.12.0',  # ideal Unicode support
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/unicode-util-pm5.git',
            homepage   => 'https://github.com/patch/unicode-util-pm5',
            bugtracker => 'https://github.com/patch/unicode-util-pm5/issues',
        },
    },
);

$builder->create_build_script;
