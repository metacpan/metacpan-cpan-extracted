#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# weakrefs
{
    use builtin qw( is_weak weaken unweaken );

    my $arr = [];
    my $ref = $arr;

    ok(!is_weak($ref), 'ref is not weak initially');

    weaken($ref);
    ok(is_weak($ref), 'ref is weak after weaken()');

    unweaken($ref);
    ok(!is_weak($ref), 'ref is not weak after unweaken()');

    weaken($ref);
    undef $arr;
    is($ref, undef, 'ref is now undef after arr is cleared');

    is(prototype(\&builtin::weaken), '$', 'weaken prototype');
    is(prototype(\&builtin::unweaken), '$', 'unweaken prototype');
    is(prototype(\&builtin::is_weak), '$', 'is_weak prototype');
}

done_testing();
