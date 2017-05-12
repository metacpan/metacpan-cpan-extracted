use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'XHTML::Instrumented',
    license       => 'perl',
    requires => {
	'perl'		=> '5.6.0',
	'Params::Validate' => 0,
	'XML::Parser' => 0,
    },
    build_requires => {
	'Test::XML' => 0,
	'Test::Warn' => 0,
	'Test::XML::Order' => '0.03',
    },
    sign           => 1,
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script;
