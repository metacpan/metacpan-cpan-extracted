#!/usr/bin/perl -w

use strict;
use Test::More;
use FindBin;
BEGIN {
	chdir "$FindBin::Bin/.." or plan skip_all => "Can't chdir to dist: $!";
}
# Ensure a recent version of Test::Pod
eval "use Test::Pod 1.22; 1" or plan skip_all => "Test::Pod 1.22 required for testing POD";

all_pod_files_ok();
exit 0;

# kwalitee hacks
require Test::Pod;
require Test::NoWarnings;
