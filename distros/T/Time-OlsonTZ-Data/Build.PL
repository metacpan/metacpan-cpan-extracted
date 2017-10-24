{ use 5.006; }
use warnings;
use strict;

use Module::Build 0.26;

my $build = Module::Build->new(
	module_name => "Time::OlsonTZ::Data",
	license => "perl",
	dist_author => "Andrew Main (Zefram) <zefram\@fysh.org>",
	configure_requires => {
		"Module::Build" => "0.26",
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => "0.26",
		"Test::More" => "0.41",
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Exporter" => 0,
		"File::Spec" => 0,
		"if" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-Time-OlsonTZ-Download".
					"\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=".
					"Time-OlsonTZ-Download",
			},
		},
	},
	sign => 0,
);
$build->add_build_element("tz");
$build->add_build_element("tzp");
$build->create_build_script;

1;
