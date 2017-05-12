#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{IS_MAINTAINER};

eval "require Test::Kwalitee;";
plan skip_all => "Test::Kwalitee needed for testing kwalitee"
    if $@;
Test::Kwalitee->import();
