
#use strict;
use Module::Build;


my $build = Module::Build->new
    (
     module_name => 'types',
     license => 'unknown',
     dynamic_config => 1,
     requires => 
     { 
	 'optimize' => '0.02',
	 'perl' => '5.8',
	 'B::Generate' => '1.06',
     }
     );
$build->create_build_script();
