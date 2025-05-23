{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	unless(__PACKAGE__->can("have_c_compiler")) {
		*have_c_compiler = sub {
			my $cb = eval { $_[0]->cbuilder };
			return $cb && $cb->have_compiler;
		};
	}
	if($Module::Build::VERSION < 0.33) {
		# Older versions of Module::Build have a bug where if the
		# cbuilder object is used at Build.PL time (which it will
		# be for this distribution due to the logic in
		# ->find_xs_files) then that object can be dumped to the
		# build_params file, and then at Build time it will
		# attempt to use the dumped blessed object without loading
		# the ExtUtils::CBuilder class that is needed to make it
		# work.
		*write_config = sub {
			delete $_[0]->{properties}->{_cbuilder};
			return $_[0]->SUPER::write_config;
		};
	}
	sub find_xs_files {
		my($self) = @_;
		return {} unless $self->have_c_compiler;
		return $self->SUPER::find_xs_files;
	}
})->new(
	module_name => "XML::Easy",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"warnings" => 0,
	},
	configure_recommends => {
		"ExtUtils::CBuilder" => "0.15",
	},
	build_requires => {
		"Encode" => 0,
		"IO::File" => 0,
		"Module::Build" => 0,
		"Params::Classify" => 0,
		"Scalar::Util" => 0,
		"Test::More" => 0,
		"if" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"utf8" => 0,
		"warnings" => 0,
	},
	build_recommends => {
		"ExtUtils::CBuilder" => "0.15",
	},
	requires => {
		"Exporter" => 0,
		"Params::Classify" => 0,
		"if" => 0,
		"parent" => 0,
		"perl" => "5.008",
		"strict" => 0,
		"warnings" => 0,
	},
	recommends => {
		"Internals" => 0,
		"XSLoader" => 0,
	},
	needs_compiler => 0,
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-XML-Easy\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=XML-Easy",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
