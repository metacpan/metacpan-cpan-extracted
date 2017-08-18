{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub probed_info {
		my($self) = @_;
		my $feat_file = $self->localize_file_path(
				"lib/Time/UTC/features");
		my $probe_file = $self->localize_file_path(
				"lib/Time/UTC/features.probe");
		unless($self->up_to_date($probe_file, $feat_file)) {
			require IO::File;
			require Data::Dumper;
			my $probe = do("./$probe_file") or
				die $@ || "can't read $probe_file: $!";
			my $feat_defs = $probe->($self);
			$self->add_to_cleanup($feat_file);
			my $feat_fh = IO::File->new($feat_file, "w")
				or die "can't write $feat_file: $!";
			local $Data::Dumper::Terse = 1;
			$feat_fh->printflush(Data::Dumper::Dumper($feat_defs))
				or die "can't write $feat_file: $!";
		}
		my $probed_info = do("./$feat_file") or
			die $@ || "can't read $feat_file: $!";
		return ($probed_info, $feat_file);
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		unless($args{no_feature_defs}) {
			my($probed, $probed_file) = $self->probed_info;
			$args{defines} = {
				%{$args{defines} || {}},
				%{$probed->{defs}},
			};
			$obj_file = $self->cbuilder->object_file($file);
			unless($self->up_to_date($probed_file, $obj_file)) {
				unlink $obj_file;
			}
		}
		return $self->SUPER::compile_c($file, %args);
	}
	sub link_c {
		no strict "refs";
		my($self, $spec) = @_;
		my($probed, $probed_file) = $self->probed_info;
		unless($self->up_to_date($probed_file, $spec->{lib_file})) {
			unlink $spec->{lib_file};
		}
		my $cb = $self->cbuilder;
		my $cbclass = ref($cb);
		my $orig_cb_link = $cb->can("link");
		local *{"${cbclass}::link"} = sub {
			my($self, %args) = @_;
			$args{extra_linker_flags} = [
				@{$args{extra_linker_flags} || []},
				@{$probed->{libs}},
			];
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Time::UTC::Now",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Data::Dumper" => 0,
		"ExtUtils::CBuilder" => "0.15",
		"IO::File" => 0,
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Exporter" => 0,
		"Math::BigRat" => "0.13",
		"Time::Unix" => "1.02",
		"XSLoader" => 0,
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
				mailto => "bug-Time-UTC-Now\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Time-UTC-Now",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
