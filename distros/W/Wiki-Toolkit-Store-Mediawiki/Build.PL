use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wiki::Toolkit::Store::Mediawiki',
    license             => 'perl',
    dist_author         => 'Derek Price <derek@ximbiot.com>',
    sign		=> 1,
    dist_version_from   => 'lib/Wiki/Toolkit/Store/Mediawiki.pm',
    requires => {
	'Wiki::Toolkit::Store::Database' => 0,
	'Carp' => 0,
	'Time::Piece::Adaptive' => 0,
	'Time::Seconds' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Wiki-Toolkit-Store-Mediawiki-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
