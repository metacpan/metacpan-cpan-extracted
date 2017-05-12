#!/usr/bin/perl

use Test::More tests => 2;

use strict;
use warnings;

use barewords qw(foo bar);

is(foo, 'foo', 'foo');
is(bar, 'bar', 'bar');

