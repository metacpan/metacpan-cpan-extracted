use Module::Build;

my $build = Module::Build->new(
    module_name => 'UR::Object::Command::Crud',
    license => 'perl',
    dist_abstract => 'Create, List (Read), Update and Delete plus Copy (CRUD) Command Line Interfaces for UR Objects',
    dist_author => 'Eddie Belter <ebelter@cpan.org>',
    dist_version => '0.01',
    build_requires => {
        'Module::Build' => 0,
    },
    test_requires => {
        'Path::Class'   => 0,
        'Test::More'    => 0,
        'Scope::Guard'  => 0,
    },
    requires => {
        'UR'                    => 0,
        'YAML'                  => 0,
        'Lingua::EN::Inflect'   => 0,
        'List::MoreUtils'       => 0,
        'Sub::Install'          => 0,
    },
);
$build->create_build_script;
