{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	sub ACTION_testauthor { $_[0]->generic_test(type => "author") }
})->new(
	module_name => "Time::TAI::Now",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Data::Float" => "0.008",
		"Exporter" => 0,
		"Math::BigRat" => "0.10",
		"Math::Decimal" => 0,
		"Time::UTC" => "0.007",
		"Time::UTC::Now" => "0.012",
		"constant" => 0,
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
				mailto => "bug-Time-TAI-Now\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Time-TAI-Now",
			},
		},
	},
	test_types => { author => ".at" },
	sign => 1,
)->create_build_script;

1;
