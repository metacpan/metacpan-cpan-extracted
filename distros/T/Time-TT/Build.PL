{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Time::TT",
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
		"Date::JD" => "0.005",
		"Exporter" => 0,
		"Math::BigRat" => "0.13",
		"Math::Interpolator::Knot" => "0.003",
		"Math::Interpolator::Linear" => "0.003",
		"Math::Interpolator::Robust" => "0.003",
		"Math::Interpolator::Source" => "0.003",
		"Net::FTP::Tiny" => "0.001",
		"Time::UTC" => "0.007",
		"constant" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
