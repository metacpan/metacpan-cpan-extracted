#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# reference queries
{
    use builtin qw( refaddr reftype blessed );

    my $arr = [];
    my $obj = bless [], "Object";

    is(refaddr($arr),        $arr+0, 'refaddr yields same as ref in numeric context');
    is(refaddr("not a ref"), undef,  'refaddr yields undef for non-reference');

    is(reftype($arr),        "ARRAY", 'reftype yields type string');
    is(reftype($obj),        "ARRAY", 'reftype yields basic container type for blessed object');
    is(reftype("not a ref"), undef,   'reftype yields undef for non-reference');

    is(blessed($arr), undef, 'blessed yields undef for non-object');
    is(blessed($obj), "Object", 'blessed yields package name for object');

    # blessed() as a boolean
    is(blessed($obj) ? "YES" : "NO", "YES", 'blessed in boolean context still works');

    # blessed() appears false as a boolean on package "0"
    is(blessed(bless [], "0") ? "YES" : "NO", "NO", 'blessed in boolean context handles "0" cornercase');

    is(prototype(\&builtin::blessed), '$', 'blessed prototype');
    is(prototype(\&builtin::refaddr), '$', 'refaddr prototype');
    is(prototype(\&builtin::reftype), '$', 'reftype prototype');
}

done_testing;
