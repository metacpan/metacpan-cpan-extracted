#!/usr/bin/env perl

use strict;
use utf8;
use version;
use warnings;

use File::Spec::Functions;
use FindBin qw( $Bin );
use Test::More;

########################################
# Tests

plan skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.'
    if !$ENV{'TEST_AUTHOR'};

plan skip_all => 'Test::Perl::Critic required for testing PBP compliance'
    if !eval 'use Test::Perl::Critic; 1';    ## no critic (ProhibitStringyEval)

plan skip_all => 'Perl::Critic v1.117 or later required for testing PBP compliance'
    if $Perl::Critic::VERSION < version->parse('v1.117');

Test::Perl::Critic->import(
    -profile              => catfile( $Bin, 'perlcriticrc' ),
    '-profile-strictness' => 'quiet',
);
Test::Perl::Critic::all_critic_ok( catdir( $Bin, &updir, 'script' ) );

exit;
