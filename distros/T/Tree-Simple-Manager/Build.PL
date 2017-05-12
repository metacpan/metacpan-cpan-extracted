use Module::Build;

use strict;
use warnings;

my $build = Module::Build->new(
    module_name => 'Tree::Simple::Manager',
    license => 'perl',
    requires => {
        'Tree::Simple'       => 1.14,
        'Tree::Parser'       => 0.15,
        'Tree::Simple::View' => 0.11,
        'Class::Throwable'   => 0.10,
        'File::stat'         => 0,
        'Storable'           => 0,                
    },
    optional => {
    },
    build_requires => {
        'Test::More'      => '0.47',
        'Test::Exception' => '0.21',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

