use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Tk::ColourChooser',
    dist_author        => 'Tina Mueller',
    requires => {
        Tk       => 0,
        Carp     => 0,
        Symbol   => 0,
        strict   => 0,
        warnings => 0,
    },
    build_requires => {
        'Test::More'          => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0.
    },
    recommends         => {
    },
    create_readme      => 0,
    sign               => 0,
);
$build->create_build_script;
