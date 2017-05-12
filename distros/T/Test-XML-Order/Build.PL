# @(#) $Id$
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Test::XML::Order',
    license       => 'perl',
    requires => {
	'perl'		=> '5.006',
    },
    build_requires => {
    },
    recommends => {
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
    },
    sign           => 1,
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script;
