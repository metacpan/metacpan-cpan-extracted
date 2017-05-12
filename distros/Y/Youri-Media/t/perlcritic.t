#!/usr/bin/perl
# $Id: /mirror/youri/soft/Media/trunk/t/perlcritic.t 2315 2007-03-22T13:45:11.684364Z guillomovitch  $

use strict;
use warnings;
use Test::More;

eval 'use Test::Perl::Critic';
plan(skip_all => 'Test::Perl::Critic required, skipping') if $@;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    unless $ENV{TEST_AUTHOR};

all_critic_ok();
