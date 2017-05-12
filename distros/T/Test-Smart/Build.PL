use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Smart',
    license    => 'perl',
    requires    => {
	perl => '5.6.2'
    },
    create_makefile_pl => 'traditional'
);
$build->create_build_script;
