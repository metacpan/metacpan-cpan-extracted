# $Id: 91-meta-yaml.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;

BEGIN {
    eval ' use YAML; ';
    if ( $@ ) {
        plan( skip_all => 'YAML not installed.' );
    }
    else {
        eval ' require Test::NoWarnings; ';
        if ( $@ ) {
            plan( tests => 1 );
            undef $test_warn;
        }
        else {
            plan( tests => 2 );
            $test_warn = 1;
        }
    }
}

ok( YAML::LoadFile( './META.yml' ),          'Is the META.yml valid?' );
if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}
