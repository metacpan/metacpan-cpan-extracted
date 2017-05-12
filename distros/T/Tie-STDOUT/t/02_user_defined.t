#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Tie::STDOUT
    print => sub { $main::accumulator .= $_ foreach(@_) },
    printf => sub { my $fmt = shift(); $main::accumulator .= sprintf($fmt, @_) };
    # can't be bothered with syswrite, as the code which handles it is exactly
    # the same as the others

print qw(foo bar baz);
printf "%s %d", "foo", 20;

ok($main::accumulator eq 'foobarbazfoo 20', 'user-defined functions work');
