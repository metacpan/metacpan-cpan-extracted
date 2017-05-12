use Module::Build;

my $build = Module::Build->new(
	module_name => 'Text::UnicodeBox',
	license     => 'perl',
	sign        => 1,
	configure_requires => {
		'Module::Build' => 0.4,
	},
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Moose'           => 0,
		'Term::ANSIColor' => '2.01',
		'Text::CharWidth' => '0.04',
	},
	create_makefile_pl => 'passthrough',
	create_readme      => 1,
);

$build->create_build_script;
