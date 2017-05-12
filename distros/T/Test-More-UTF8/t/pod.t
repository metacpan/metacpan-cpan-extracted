#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::More::UTF8;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;
plan tests => 1;
pod_file_ok($INC{'Test/More/UTF8.pm'});
