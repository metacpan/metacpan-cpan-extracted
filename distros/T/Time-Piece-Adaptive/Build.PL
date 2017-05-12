use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Time::Piece::Adaptive',
    license             => 'perl',
    dist_author         => 'Derek Price <derek@ximbiot.com>',
    sign		=> 1,
    dist_version_from   => 'lib/Time/Piece/Adaptive.pm',
    requires => {
	'Time::Piece' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Time-Piece-Adaptive-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
