package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( qw{ :test2 :private } );
}

use lib qw{ inc };
use Test2::Plugin::INC_Jail;
use My::Module::Test qw{
    build_skip_reason
    cant_locate
    CHECK_MISSING_INFO
};

use constant SUB_NAME	=> "${CLASS}::load_module_or_skip_all";

my $line;

{
    like
	intercept {
	    load_module_or_skip_all -req => CLASS;
	},
	array {
	    end;
	},
	"use $CLASS (already loaded, require() semantics)";
}


{
    my $module = 'Present';

    not_imported_ok 'and_accounted_for';

    like
	intercept {
	    load_module_or_skip_all $module;
	},
	array {
	    end;
	},
	"use $module (not previously loaded, use() semantics)";

    imported_ok 'and_accounted_for';
}


{
    my $module	= 'Bogus0';

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module (not loadable, use() semantics) skips";
}


{
    my $module	= 'BogusVersion';
    my $version = 99999;

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module, $version;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module, $version );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module $version (version error, use() semantics) skips";
}


{
    my $module = 'BogusVersion';
    my @import = qw{ no_such_export };

    like
	intercept {
	    $line = __LINE__ + 1;
	    load_module_or_skip_all $module, undef, \@import;
	},
	array {

	    event Plan => sub {
		call max	=> 0;
		call directive	=> 'SKIP';
		call reason	=> build_skip_reason( $module, undef, \@import );

		prop file	=> __FILE__;
		prop package	=> __PACKAGE__;
		prop line	=> $line;
		prop subname	=> SUB_NAME;
	    };

	    end;
	},
	"use $module qw{ @import } (import error, use() semantics) skips";
}


done_testing;


1;

# ex: set textwidth=72 :
