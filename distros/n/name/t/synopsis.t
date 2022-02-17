#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => "Author tests not required for installation"
    unless $ENV{RELEASE_TESTING};

# Ensure a recent version of Test::Synopsis
my $min_ver = 0.16;
eval "use Test::Synopsis $min_ver";
plan skip_all => "Test::Synopsis $min_ver required for testing POD synopsis"
    if $@;

all_synopsis_ok();
