#!/usr/bin/perl
# $Id: kwalitee.t 1891 2007-11-04 17:40:52Z guillomovitch $

use Test::More;
eval {
    require Test::Kwalitee;
    Test::Kwalitee->import()
};
plan(skip_all => 'Test::Kwalitee not installed; skipping') if $@;
