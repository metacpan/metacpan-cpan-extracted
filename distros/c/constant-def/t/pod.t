#!/usr/bin/perl -w

use strict;
use Test::More;
use ex::lib '../lib';
use File::Find;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
$@ and plan skip_all => "Test::Pod $min_tp required for testing POD";
my @files;
eval "use File::Find";
$@ and plan skip_all => "File::Find required for testing POD";

File::Find::find sub {
	push @files, $File::Find::name if /\.pm$/;
}, $INC[0];

plan tests => 0+@files;

pod_file_ok($_) for @files;
