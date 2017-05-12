#!/usr/bin/env perl
#
# $Id: 00load.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use English qw(-no_match_vars);
use Test::Base tests => 7;

our $WHY_SKIP_SAWAMPERSAND;

BEGIN {
    if ( $ENV{TEST_MATCH_VARS} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
        eval {
            require Devel::SawAmpersand;
            Devel::SawAmpersand->import(qw(sawampersand));
        };
        if ($EVAL_ERROR) {
            $WHY_SKIP_SAWAMPERSAND =
              'Devel::SawAmpersand required for testing sawampersand';
        }
    }
    else {
        $WHY_SKIP_SAWAMPERSAND = 'set TEST_MATCH_VARS for testing sawampersand';
    }

    use_ok('WebService::YouTube');
    use_ok('WebService::YouTube::Feeds');
    use_ok('WebService::YouTube::User');
    use_ok('WebService::YouTube::Util');
    use_ok('WebService::YouTube::Video');
    use_ok('WebService::YouTube::Videos');
}

# run sawampersand test if Devel::SawAmpersand is installed.
SKIP: {
    if ($WHY_SKIP_SAWAMPERSAND) {
        skip $WHY_SKIP_SAWAMPERSAND, 1;
    }
    ok( !sawampersand(), q{$`, $&, and $' should not appear} );    ## no critic
}
