use Module::Build;

my $build = Module::Build->new(
	module_name => 'Thrift::Parser',
	license     => 'perl',
	sign        => 1,
	create_readme => 1,
	configure_requires => {
		'Module::Build' => 0.4,
	},
	build_requires => {
		'Test::More'  => 0,
		'Test::Class' => 0,
		'Test::Deep'  => 0,
	},
	requires => {
		'Thrift' => 0,
		'Parse::RecDescent' => 0,
		'Class::Accessor'   => 0,
		'Class::Accessor::Grouped' => 0,
		'Class::Data::Accessor' => 0,
		'Class::ISA'        => 0,
		'Exception::Class' => 0,
		'Params::Validate' => 0,
		'JSON::XS'         => 0,
	},
	create_makefile_pl => 'small',
	meta_merge => {
		resources => {
			repository => "http://github.com/ewaters/thrift-parser",
			bugtracker => "http://github.com/ewaters/thrift-parser/issues?labels=bug",
		},
	},
);

$build->create_build_script;

