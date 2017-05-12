use strict;
use warnings;

use Module::Build;

my @test_requires = (
        'File::Path' => 0,
        'Test::Differences' => 0,
        'File::DirCompare' => 0,
        'Text::Diff' => 0,
);
my @extra_requires_for_tests = ();
if ($Module::Build::VERSION < 0.4004) {
    @extra_requires_for_tests = @test_requires;
}

my $build = Module::Build->new(
    module_name => 'Text::Frundis',
    dist_version_from => 'lib/Text/Frundis.pm',
    '1_files' => { 
        'frundis.1' => 'mdoc/man1/frundis.1',
    },
    '5_files' => {
        'frundis_syntax.5' => 'mdoc/man5/frundis_syntax.5',
    },
    license => 'open_source',
    requires => {
        perl => 5.012,
        URI => 0,
        Carp => 0,
        'File::Spec' => 0,
        'File::Spec::Functions' => 0,
        'File::Basename' => 0,
        'File::Copy' => 0,
        'File::Temp' => 0,
        @extra_requires_for_tests,
    },
    test_requires => { @test_requires },
    recommends => {
        'Data::UUID' => 0,
    },
    script_files => [ 'script/frundis' ],
    configure_requires => { 'Module::Build' => 0.4000 },
);
if ($build->install_base) {
    $build->install_path('mdoc' => $build->install_base . "/man");
    $build->add_build_element('1');
    $build->add_build_element('5');
}
else {
    warn "install_base not defined, skipping man page installation";
}

$build->create_build_script;
