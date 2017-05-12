use Module::Build;	
Module::Build->new(
	module_name	=> 'Text::CSV::Unicode',
	configure_requires => { Module::Build => 0.38 }, 
	requires	=> { perl => 5.008, charnames => 1 },
	build_requires	=> { Test::More => 0 },
	license		=> 'perl',	
	create_makefile_pl => 'traditional',
) -> create_build_script;

if( ! eval { require charnames } ) {
    warn "required charnames does not load\n";
    warn "unicore/Name.pm not installed by perl 5.15.5 build\n"
	if $^V eq v5.15.5;
}
