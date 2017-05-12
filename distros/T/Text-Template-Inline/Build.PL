# vi:sts=4 sw=4 bs=2 et ai:
use Module::Build;
my $build = Module::Build->new(
    module_name => 'Text::Template::Inline',
    license  => 'perl',
    requires => {
        'perl'              => '5.6.1',
        'Scalar::Util'      => 0,
        'Test::Simple'      => 0,
        'Test::Exception'   => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
);
$build->create_build_script;



