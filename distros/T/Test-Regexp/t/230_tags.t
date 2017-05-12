#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use Test::More 0.88;
use Test::Regexp import => [];

#
# Check to see whether the objects remember 'tags'
#

my $obj1 = Test::Regexp:: -> new -> init (
    pattern => 'foo',
    tags    => {
        -foo => 1,
        -bar => 2,
    }
);


my $obj2 = Test::Regexp:: -> new -> init (
    pattern => 'foo',
    tags    => {
        -bar => 1,
        -baz => 3,
        -baz => 4,
        -qux => 5,
    }
);
      

is $obj1 -> tag ('-foo'),  1, "Tag";
is $obj1 -> tag ('-bar'),  2, "Tag";
is $obj2 -> tag ('-bar'),  1, "Tag";
is $obj2 -> tag ('-baz'),  4, "Tag";
is $obj2 -> tag ('-qux'),  5, "Tag";


$obj2 -> set_tag (-quux => 6);
$obj2 -> set_tag (-bar  => 7);

is $obj1 -> tag ('-foo'),  1, "Tag";
is $obj1 -> tag ('-bar'),  2, "Tag";
is $obj2 -> tag ('-bar'),  7, "Tag";
is $obj2 -> tag ('-baz'),  4, "Tag";
is $obj2 -> tag ('-qux'),  5, "Tag";
is $obj2 -> tag ('-quux'), 6, "Tag";

done_testing;
