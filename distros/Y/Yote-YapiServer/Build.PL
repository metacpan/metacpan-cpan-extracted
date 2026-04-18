use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    build_requires => {
        'Test::More'      => 0,
        'Module::Build'   => 0.40,
    },
    dist_abstract      => 'Yote API Server - JSON RPC for persistent Perl objects',
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Yote::YapiServer',
    release_status     => 'stable',
    test_files         => [ glob('t/server/*.t') ],
    requires => {
        'perl'                  => 'v5.16',
        'Yote::SQLObjectStore'  => 0,
        'JSON::PP'              => 0,
        'Digest::MD5'           => 0,
        'IO::Socket::INET'     => 0,
        'Time::Piece'           => 0,
        'Time::HiRes'           => 0,
        'YAML'                  => 0,
    },
);

$builder->create_build_script();
