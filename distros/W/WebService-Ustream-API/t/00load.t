#!/usr/bin/env perl

use strict;
use warnings;
use version; our $VERSION = qv('0.03');

#use blib;
use English qw(-no_match_vars);
use Test::Base tests => 4;

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

    use_ok('WebService::Ustream::API');
    use_ok('WebService::Ustream::API::Stream');
    use_ok('WebService::Ustream::API::User');
}

# run sawampersand test if Devel::SawAmpersand is installed.
SKIP: {
    if ($WHY_SKIP_SAWAMPERSAND) {
        skip $WHY_SKIP_SAWAMPERSAND, 1;
    }
    ok( !sawampersand(), q{$`, $&, and $' should not appear} );    ## no critic
}

