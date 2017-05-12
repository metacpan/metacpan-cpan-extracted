use strict;
use warnings;
use Test::Pod tests => 1;

my $file_name = "lib/YAPC/Europe/UGR.pm";

my $file =  -f $file_name ? $file_name: "../$file_name";
pod_file_ok( "$file", "Valid POD file at $file" );
