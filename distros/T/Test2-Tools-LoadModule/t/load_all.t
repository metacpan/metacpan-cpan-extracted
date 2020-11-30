package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
# The above loaded our module but did not import
use Test2::Tools::LoadModule qw{ :test2 :private };

# The following are needed by all_*(). Normally they would be loaded
# on-the-fly, but INC_Jail prevents this. So we load them now.
use File::Find;
use File::Spec;

use lib qw{ inc };
use Test2::Plugin::INC_Jail;
use My::Module::Test qw{
    cant_locate
    CHECK_MISSING_INFO
};

use constant SUB_NAME	=> "${CLASS}::load_module_ok";

my $line;


{
    like
	intercept {
	    all_modules_tried_ok(); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> 'Module Test2::Tools::LoadModule not tried';
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> "${CLASS}::all_modules_tried_ok";
	    };

	    end;
	},
	"$CLASS not tried (yet)";

    like
	intercept {
	    load_module_ok( CLASS ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( CLASS );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS, default import";

    like
	intercept {
	    all_modules_tried_ok(); $line = __LINE__;
	},
	array {
	    end;
	},
	'All modules tried';

    clear_modules_tried;

    like
	intercept {
	    all_modules_tried_ok(); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> 'Module Test2::Tools::LoadModule not tried';
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> "${CLASS}::all_modules_tried_ok";
	    };

	    end;
	},
	"clear_modules_tried() made us forget we tried $CLASS";
}


done_testing;

1;

# ex: set textwidth=72 :
