use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wiki::Toolkit::Formatter::Mediawiki',
    license             => 'perl',
    dist_author         => 'Derek R. Price <derek@ximbiot.com>',
    dist_version_from   => 'lib/Wiki/Toolkit/Formatter/Mediawiki.pm',
    requires => {
	'Carp' => 0,
	'Text::MediawikiFormat' => 0.02,
	'URI::Escape' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Wiki-Toolkit-Formatter-Mediawiki-*' ],
    create_makefile_pl	=> 'traditional',
    sign		=> 1,
);

$builder->create_build_script();
