#!perl -T
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

# add t/lib to verify there's no bad pod in test modules.
# Note that we don't require coverage for all test modules in t/pod-coverage.t
all_pod_files_ok( all_pod_files( 'lib', 't/lib' ) );   
