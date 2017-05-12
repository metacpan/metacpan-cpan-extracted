{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Time::TAI",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Math::BigRat" => "0.04",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Exporter" => 0,
		"LWP" => "5.5394",
		"LWP::UserAgent" => 0,
		"Math::BigRat" => "0.04",
		"Math::Interpolator::Robust" => 0,
		"Math::Interpolator::Source" => 0,
		"Time::TT::InterpolatingRealisation" => 0,
		"Time::TT::OffsetKnot" => "0.004",
		"Time::TT::Realisation" => 0,
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
