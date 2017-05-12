#!/usr/bin/env perl
#
# $Id: 04kwalitee.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use English qw(-no_match_vars);
use FindBin qw($Bin);
use Test::Base;

if ( $ENV{TEST_KWALITEE} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    chdir "$Bin/..";
    eval {
        require Test::Kwalitee;
        Test::Kwalitee->import;
    };
    if ($EVAL_ERROR) {
        plan skip_all => 'Test::Kwalitee required for testing Kwalitee';
    }
}
else {
    plan skip_all => 'set TEST_KWALITEE for testing Kwalitee';
}
