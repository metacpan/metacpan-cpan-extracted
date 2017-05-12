use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Text::Indent',
	license            => 'perl',
	requires           => {
		Params::Validate   => 0.50,
		Class::MethodMaker => 1.12,
	},
	dist_version_from       => 'lib/Text/Indent.pm',
    create_makefile_pl => 'passthrough',
);

$build->create_build_script;
