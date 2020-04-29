package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
# The above loaded our module but did not import
use Test2::Tools::LoadModule qw{ :test2 :private };

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


{
    like
	intercept {
	    load_module_ok( CLASS, 0 ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( CLASS, 0 );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS, version 0, default import";
}


{
    like
	intercept {
	    load_module_ok( CLASS, undef, [] ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( CLASS, undef, [] );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-loaded module $CLASS, no import";
}


{
    like
	intercept {
	    load_module_ok(); $line = __LINE__;
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
	"Load previously-loaded default module ($CLASS), default import";
}


{
    my $module = 'Present';
    like
	intercept {
	    load_module_ok( $module, undef, undef, "Load $module" ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "Load $module";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load previously-unloaded module $module, with default import";

    imported_ok( 'and_accounted_for' );
    not_imported_ok( 'under_the_tree' );
}


{
    my $module = 'Present';
    my @import = qw{ under_the_tree };
    like
	intercept {
	    load_module_ok( $module, undef, \@import ); $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> __build_load_eval( $module, undef, \@import );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load now-loaded module $module, with explicit import";

    imported_ok( 'under_the_tree' );
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    load_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $module );
		call info	=> array {
		    item object {
			call details	=> cant_locate( $module );
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, with load error diagnostic";
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    load_module_ok( -load_error => 0, $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $module );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, error diagnostic suppressed by subroutine argument";
}


SKIP: {
    HINTS_AVAILABLE
	or skip "Hints not available in perl $]";

    my $module = 'Bogus0';

    # This strange code is because we want the import list to be empty
    # if hints are not available, but they need to be executed at
    # compile time if they are. The 'skip' does not help us here because
    # the use() is done unconditionally.
    my @import;
    BEGIN { HINTS_AVAILABLE and @import = ( -load_error => 0 ); }
    use Test2::Tools::LoadModule @import;

    like
	intercept {
	    load_module_ok( $module ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $module );
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, error diagnostic suppressed by custom pragma";
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    load_module_ok( $module, undef, [], undef, 'Fubar' ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $module, undef, [] );
		call info	=> array {
		    item object {
			call details	=> 'Fubar';
		    };
		    item object {
			call details	=> cant_locate( $module );
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load unloadable module $module, with extra diagnostic";
}


{
    my $module = 'BogusVersion';
    my $version = 99999;

    like
	intercept {
	    load_module_ok( $module, $version ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval( $module, $version );
		call info	=> array {
		    item object {
			call details	=>
				match qr<\A$module version $version required\b>sm;
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load $module, with too-high version $version";
}


{
    my $module = 'BogusVersion';
    my @import = qw{ no_such_import };

    like
	intercept {
	    load_module_ok( $module, undef, \@import ); $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> __build_load_eval(
		    $module, undef, \@import );
		call info	=> array {
		    item object {
			call details	=>
				match qr<\A"@import" is not exported\b>sm;
		    };
		    end;
		};
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Load $module, with non-existent import";
}


done_testing;

1;

# ex: set textwidth=72 :
