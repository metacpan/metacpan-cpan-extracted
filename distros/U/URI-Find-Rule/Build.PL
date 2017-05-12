use Module::Build;
my $build = Module::Build->new(
    module_name => 'URI::Find::Rule',
    license => 'perl',
    requires => {
        'URI::Find' => 0,
        'URI' => 0,
        'Text::Glob' => 0,
        'Test::More' => 0
    },
    create_makefile_pl => 'passthrough'
);
$build->create_build_script;
