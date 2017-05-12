use Module::Build;

my $build = Module::Build->new(
	module_name => 'Win32::Snarl',
	license => 'perl',
	requires => {
		perl => '5.8.0',
		Win32::GUI => '1.03',
	},
);

$build->create_build_script;