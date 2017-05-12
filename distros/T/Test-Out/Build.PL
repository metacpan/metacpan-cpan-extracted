use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Out',
    license => 'perl',
    requires => {
        'perl'           => '5.6.1',
        'Test::Builder'         => '0.17',
        'Carp'                  => '1.04',
        'Carp::Assert'          => '0.20',
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
);
$build->create_build_script;
