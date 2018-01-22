{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	sub ACTION_testauthor { $_[0]->generic_test(type => "author") }
})->new(
	module_name => "Time::OlsonTZ::Download",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Encode" => "1.75",
		"File::Path" => "2.07",
		"File::Temp" => "0.22",
		"IO::Dir" => "1.03",
		"IO::File" => "1.03",
		"IPC::Filter" => "0.002",
		"Net::FTP" => "3.07",
		"Params::Classify" => 0,
		"parent" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"utf8" => 0,
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
	test_types => { author => ".at" },
	sign => 1,
)->create_build_script;

1;
