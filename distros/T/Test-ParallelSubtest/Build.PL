use 5.006001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Test::ParallelSubtest',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/Test/ParallelSubtest.pm',
    license     => 'perl',
    requires => {
        'perl'                  => 5.006001,
        'Carp'                  => 0,
        'IO::WrapTie'           => 0,
        'POSIX'                 => 0,
        'Sub::Prepend'          => 0,
        'TAP::Parser'           => 0,
        'Test::Builder'         => 0.94, # need subtest support
        'Tie::FileHandle::Base' => 0,
    },
    build_requires => {
        'Config'            => 0,
        'Test::Builder'     => 0.94,
        'Test::Cmd'         => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0.94,
    },
    create_makefile_pl => 'traditional',
);
$builder->create_build_script();
