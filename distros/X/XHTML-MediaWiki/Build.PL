use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'XHTML::MediaWiki',
    dist_abstract => 'Convert MediaWiki text to xhtml',
    license       => 'perl',
    requires => {
 	'HTML::Parser'     => 0,
	'Params::Validate' => '0.85',
	'URI::Escape'      => 0,
    	'perl'             => '5.006_001',
    },
    meta_add => {
        no_index => {
	    namespace => [
		'XHTML::MediaWiki',
	    ],
	},
    },
    build_requires => {
	'Test::XML' => 0,
    },
    recommends => {
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    sign          => 1,
);

$builder->create_build_script;

