# -*- perl -*-
# check that any POD documentation is valid

use warnings;
use strict;
use Test::More;
use File::Find;

plan skip_all => 'only run for author tests' unless $ENV{AUTHOR_TEST};
eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;

my @files;
find(sub { push @files, $File::Find::name if /\.pm$/ }, 'lib');
all_pod_files_ok(@files);