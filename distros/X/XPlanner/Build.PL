#!/usr/bin/perl -w

use Module::Build;

Module::Build->new(
    module_name => 'XPlanner',
    license     => 'perl',
    requires    => {
                    'SOAP::Lite'    => 0,
                    'YAML'          => 0,
                    'URI'           => 0,
                    'Module::Build' => 0,
                    'Test::More'    => 0,
                    'Test::Harness' => 2.00,
                   },
)->create_build_script;
