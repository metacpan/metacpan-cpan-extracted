#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use File::Spec::Functions;
use FindBin qw( $Bin );
use Test::More;

########################################
# Tests

plan skip_all => 'Test::Pod 1.45 required for testing POD'
    if !eval 'use Test::Pod 1.45; 1';    ## no critic (ProhibitStringyEval)

all_pod_files_ok( catdir( $Bin, &updir, 'script' ) );

exit;
