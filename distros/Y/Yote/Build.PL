use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Yote-*' ],
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.40,
    },
    dist_abstract      => 'fixed record store',
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Yote',
    release_status     => 'stable',
    test_files         => [ 't/yotedb.t', ],
    requires => {
        'perl'                  => 'v5.10',
        'JSON'                  => 0,
        'Data::RecordStore'     => 2.0,
        'Devel::Refcount'       => 0.1,
    },
    );

$builder->create_build_script();
