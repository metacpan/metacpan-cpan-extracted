#!/usr/bin/env perl
#
# $Id: 01perlcritic.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use English qw(-no_match_vars);
use FindBin qw($Bin);
use Test::Base;

if ( $ENV{TEST_CRITIC} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    chdir "$Bin/..";
    eval {
        my $format = "%l: %m (severity %s)\n";
        if ( $ENV{TEST_VERBOSE} ) {
            $format .= "%p\n%d\n";
        }
        require Test::Perl::Critic;
        Test::Perl::Critic->import( -format => $format, -severity => 1 );
    };
    if ($EVAL_ERROR) {
        plan skip_all =>
          'Test::Perl::Critic required for testing PBP compliance';
    }
}
else {
    plan skip_all => 'set TEST_CRITIC for testing PBP compliance';
}

all_critic_ok();
