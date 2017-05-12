#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 4;

my %res;

eval q[
 package subs::auto::Test;
 use subs::auto;
 $res{"${_}2"} = __PACKAGE__->can($_) ? 1 : 0 for qw<foo bar baz qux>;
 return;
 BEGIN { $res{foo} = __PACKAGE__->can('foo') ? 1 : 0; }
 sub bar;
 BEGIN { $res{bar} = __PACKAGE__->can('bar') ? 1 : 0; }
 baz 1;
 BEGIN { $res{baz} = __PACKAGE__->can('baz') ? 1 : 0; }
 BEGIN { $res{qux} = __PACKAGE__->can('qux') ? 1 : 0; }
 qux 3, 4;
];
die $@ if $@;

is $res{foo}, 0, 'foo at compile time';
is $res{bar}, 1, 'bar at compile time';
is $res{baz}, 0, 'baz at compile time';
is $res{qux}, 0, 'qux at compile time';

is $res{foo2}, 0, 'foo at run time';
is $res{bar2}, 1, 'bar at run time';
is $res{baz2}, 0, 'baz at run time';
is $res{qux2}, 0, 'qux at run time';
