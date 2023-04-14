{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Tuple::Munge",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.037009",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"ExtUtils::CBuilder" => "0.15",
		"ExtUtils::ParseXS" => 0,
		"Module::Build" => 0,
		"Test::More" => 0,
		"constant" => 0,
		"feature" => 0,
		"overload" => 0,
		"perl" => "5.037009",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Exporter" => 0,
		"XSLoader" => 0,
		"perl" => "5.037009",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-Tuple-Munge\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Tuple-Munge",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
