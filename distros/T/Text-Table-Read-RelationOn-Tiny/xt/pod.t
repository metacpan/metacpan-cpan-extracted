use strict;
use warnings;

use Test::Pod;

my @poddirs = qw( lib );

my @files = all_pod_files( map {  $_ } @poddirs );

all_pod_files_ok(@files);
