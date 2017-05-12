#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author test.  Set $ENV{ TEST_AUTHOR } to enable this test.' unless $ENV{ TEST_AUTHOR };

eval "use Test::Perl::Critic ( -severity => 3, -profile => 't/perlcriticrc' )";
plan skip_all => 'Test::Perl::Critic not installed.' if $@;

all_critic_ok();

