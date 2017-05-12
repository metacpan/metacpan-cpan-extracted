#!/usr/bin/perl

use Module::Build;
Module::Build->new(
    module_name => 'Text::Patch::Rred',
    script_files => [ 'bin/rred.pl' ],
    license     => 'perl',
    requires    => {
        perl => '5.6.0',
    },
    build_requires => {
        Test::More => 0,
        Test::Pod => 1.00,
        Test::Pod::Coverage => 1.00,
        # For TEST_AUTHOR only: Test::Perl::Critic => 1.00,
        File::Spec => 0,
    },
    PL_files => { },
    dynamic_config => 0,
    # Forgets the PL_FILES=>{} entry!
    create_makefile_pl => 'traditional',
)->create_build_script;
