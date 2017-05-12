#!perl -wT

use strict;
use warnings;

use Test::More;


eval 'use Test::Pod 1.14';
if ( $@ ) {
    plan skip_all => 'Test::Pod 1.14 required for testing POD';
}
else {
    Test::Pod::all_pod_files_ok();
}
