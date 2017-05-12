use 5.008;
use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name		=> 'Tree::BPTree',
	license			=> 'perl',
	requires		=> {
		'perl'			=> '5.8',
	},
);

$build->create_build_script;
