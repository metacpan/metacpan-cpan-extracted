use Module::Build;
Module::Build->new
    ( module_name => 'WebDAO::Store::MLDBM',
    license => 'perl',
   prereq => {
	      'MLDBM'	=> '0',
	      'WebDAO'=>'0',
	       },
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
