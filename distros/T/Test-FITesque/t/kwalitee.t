#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
plan( skip_all => 'Test::Kwalitee test only run by author' ) if !$ENV{AUTHOR_TEST};
eval { require Test::Kwalitee; Test::Kwalitee->import() };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

