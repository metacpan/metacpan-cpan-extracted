use Module::Build;
my $build = Module::Build->new(
	module_name => 'Text::Modify',
	license     => 'perl',
	create_makefile_pl => 'traditional',
	#     requires => {
	#                  'perl'           => '5.6.1',
	#                 },
);
$build->create_build_script();

