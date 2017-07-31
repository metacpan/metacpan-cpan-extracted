{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	sub ACTION_testauthor { $_[0]->generic_test(type => "author") }
})->new(
	module_name => "Time::UTC",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Math::BigRat" => "0.13",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Digest::SHA1" => 0,
		"Exporter" => 0,
		"Math::BigRat" => "0.13",
		"Net::FTP::Tiny" => "0.001",
		"Net::HTTP::Tiny" => "0.001",
		"Time::Unix" => "1.02",
		"constant" => 0,
		"integer" => 0,
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
				mailto => "bug-Time-UTC\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Time-UTC",
			},
		},
	},
	test_types => { author => ".at" },
	sign => 1,
)->create_build_script;

1;
