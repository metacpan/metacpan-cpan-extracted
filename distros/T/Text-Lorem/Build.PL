#!/usr/bin/perl


use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
		   module_name       => 'Text::Lorem',
		   license           => 'perl',
		   build_requires    => {
				         Test::More => 0,
				        },
                  create_makefile_pl => 'passthrough'
		  )->create_build_script;
