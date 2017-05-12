#!/usr/bin/perl -w

use Module::Build;

my $build = Module::Build->new(
    module_name => 'your',
    license     => 'perl',
    requires    => {
        'Module::Build'     => 0.28,
        'Test::More'        => 0.40
    },
);
$build->create_build_script;
