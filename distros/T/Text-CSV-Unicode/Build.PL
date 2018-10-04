use Module::Build;	
Module::Build->new(
	module_name	=> 'Text::CSV::Unicode',
	configure_requires => { Module::Build => 0.38 }, 
	requires	=> { perl => 5.008, Text::CSV => 1, },
	build_requires	=> { Test::More => 0 },
	license		=> 'perl',	
	create_makefile_pl => 'traditional',
) -> create_build_script;

