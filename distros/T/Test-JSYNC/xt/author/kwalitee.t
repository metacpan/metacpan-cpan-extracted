#!perl
use strict;
use warnings;
use Test::More;

eval 'use Test::Kwalitee';
plan skip_all => 'Test::Kwalitee not installed; skipping' if $@;
