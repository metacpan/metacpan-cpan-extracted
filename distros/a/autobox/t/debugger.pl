#!/usr/bin/env perl

use strict;
use warnings;
use blib;

use autobox { DEFAULT => __PACKAGE__ };

# helper for t/debugger.t
#
# this prints "foo -> bar -> baz -> quux"
# on perl < 5.22 and fails with the following error on newer perls:
#
#     Can't locate object method "baz" via package "foo -> bar"
#
# https://github.com/scrottie/autobox-Core/issues/34

sub bar {
    return "$_[0] -> bar";
}

sub baz {
    return "$_[0] -> baz";
}

sub quux {
    print "$_[0] -> quux", $/;
}

'foo'->bar->baz->quux;
