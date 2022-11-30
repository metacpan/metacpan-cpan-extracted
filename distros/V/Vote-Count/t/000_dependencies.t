#!/usr/bin/env perl

=pod

This is a test designed to bail on dependency issues.

=cut

use 5.024;

# Using Test2, important to specify which version of Test2
# since later versions may break things.
use Test2::V0;
use Test2::Bundle::More;
use Test::Exception;
use Test::use::ok;

use feature qw /postderef signatures/;
no warnings 'experimental';

# Dzil plugin doesn't seem to always pick up minimum version specified in dist.ini
# This test is to allow keeping all of the min version statements in one place
# rather than scattering them in modules.
note( 'Testing minimum versions of dependencies');

use ok 'Path::Tiny 0.130';
use ok 'Cpanel::JSON::XS 4.32';
use ok 'List::Util 1.63';
use ok 'Math::BigRat 0.2624';
use ok 'Math::BigInt 1.999837';
use ok 'Math::BigInt::GMP 1.6005';
use ok 'Storable 3.25';
use ok 'Ref::Util 0.204';

done_testing();
