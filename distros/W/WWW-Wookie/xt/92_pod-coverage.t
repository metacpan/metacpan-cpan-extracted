# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.020;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v1.1.5;
if ( !eval { require Test::Pod::Coverage; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Test::Pod::Coverage required for testing POD coverage};
}
## no critic (ProhibitCallsToUnexportedSubs)
Test::Pod::Coverage::all_pod_coverage_ok();
## use critic
