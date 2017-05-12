#!/usr/bin/perl
# $Id: perlcritic.t 2318 2011-01-22 12:59:02Z guillomovitch $

use strict;
use warnings;
use Test::More;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    unless $ENV{TEST_AUTHOR};

eval 'use Test::Perl::Critic';
plan(skip_all => 'Test::Perl::Critic required, skipping') if $@;

all_critic_ok();
