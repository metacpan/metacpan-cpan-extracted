#!/usr/bin/env perl

=pod

This is a test designed to bail on dependency issues.

=cut

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::LoadModule;

use feature qw /postderef signatures/;
no warnings 'experimental';

# Dzil plugin doesn't seem to always pick up minimum version specified in dist.ini
# This test is to allow keeping all of the min version statements in one place
# rather than scattering them in modules.
note( 'Testing minimum versions of dependencies');

use ok 'Path::Tiny 0.130';
use ok 'Cpanel::JSON::XS 4.32';
use ok 'List::Util 1.63';
use ok 'Storable 3.25';
use ok 'Ref::Util 0.204';
# set environment MACARM for testing where this may fail
# do not use Vote::Count on environments with this issue.
# this workaround is for CI testing, where the issue couldn't be fixed
# to allow CI to include macos.
SKIP: {
  skip "Math::BigInt doesnt work on GitHub Actions Mac Arm", 4, if ( $ENV{'MACARM'});
  load_module_ok 'Math::BigRat 0.2624';
  load_module_ok 'Math::BigInt 1.999837';
  load_module_ok 'Math::BigInt::GMP 1.6005'; 
};

done_testing();
