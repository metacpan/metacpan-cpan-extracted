package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
# The above loaded our module but did not import
use Test2::Tools::LoadModule qw{ :more :private };

use lib qw{ inc };
use Test2::Plugin::INC_Jail;
use My::Module::Test qw{
    cant_locate
    CHECK_MISSING_INFO
    $LOAD_ERROR_TEMPLATE
};

use constant SUB_NAME	=> "${CLASS}::require_ok";

$LOAD_ERROR_TEMPLATE = TEST_MORE_LOAD_ERROR;

my $line;


{
    like
	intercept {
	    require_ok CLASS; $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "require $CLASS;";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Require previously-loaded module $CLASS";
}


{
    my $module = 'Present';
    like
	intercept {
	    require_ok $module; $line = __LINE__;
	},
	array {

	    event Pass => sub {
		call name	=> "require $module;";
		call info	=> CHECK_MISSING_INFO;
		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"Require not-previously-loaded module $module";
}


{
    my $module = 'Bogus0';

    like
	intercept {
	    require_ok $module; $line = __LINE__;
	},
	array {

	    event Fail => sub {
		call name	=> "require $module;";
		call info	=> array {
		    item object {
			call details	=> error_context( $module );
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
	"Require unloadable module $module";
}


done_testing;

sub error_context {
    my ( $module ) = @_;
    return sprintf TEST_MORE_ERROR_CONTEXT, require => $module;
}

1;

# ex: set textwidth=72 :
