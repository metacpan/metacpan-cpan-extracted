use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name => 'WWW::LiveDepartureBoards',
    license => 'perl',
    requires => {
        'perl' => 5.006,
	'LWP'  => 0,
	'DateTime' => 0
    },
    build_requires => {
	'Test::More' => 0
    },
    create_makefile_pl => 'traditional'
    )->create_build_script;		   
