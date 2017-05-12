#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

for my $pkg (qw/Unimport UnimportTarget/) {
    use_ok($pkg);

    ok( !$pkg->can('foo'),
        'first function correctly removed' );
    ok( $pkg->can('bar'),
        'excluded method still in package' );
    ok( !$pkg->can('baz'),
        'second function correctly removed' );
    ok( $pkg->can('qux'),
        'last method still in package' );
    is( $pkg->qux, 23,
        'all functions are still bound' );
}

done_testing;
