#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use Text::Template::Inline;

package TestObj;
sub a { shift->{_a} }
sub a1 { shift->{_a1} }
sub b { shift->{_b} }
sub b1 { shift->{_b1} }
sub c { shift->{_c} }

package main;
my $data = bless {
    _a => 'aaa',
    _b => 'bbb',
    _c => 'ccc',
    _a1 => 'a1a',
    _b1 => 'b1b',
}, 'TestObj';

is render($data, '{a} {b} {c}'),  'aaa bbb ccc',  'basic templating';
is render($data, '{e} {b} {_c}'), '{e} bbb {_c}', 'missing keys';
is render($data, '{a} {b b} {c} {?}'), 'aaa {b b} ccc {?}', 'ignore invalid';
is render($data, '{{a}} { {b} }'), '{aaa} { bbb }', 'ignore out-of-place braces';
is render($data, '{a1} {b1}'), 'a1a b1b', 'identifiers can include digits';
is eval('render $data => "{a} {b}"'), 'aaa bbb',  'syntactic sugar';

my $nested = bless { map { $_ => $data } qw/ _a _b _c _a1 _b1 / }, 'TestObj';
my $nested2 = bless { map { $_ => $nested } qw/ _a _b _c _a1 _b1 / }, 'TestObj';

is render($nested, '{a.a} {a.b}'), 'aaa bbb', 'basic key paths';
is render($nested2, '{a.a.b} {a.b.a}'), 'bbb aaa', 'nested key paths';
is render($nested2, '{a.c.b1} {c.a1.c}'), 'b1b ccc', 'key paths can include digits';
is render($nested,'{a.z}'), '{a.z}', 'traversal to nonexistent';

eval { render $nested2,'{a.c.b.y}' }; my $line = __LINE__;
ok $@ =~ /$0 line $line$/, 'traversal failure with context';

# vi:filetype=perl ts=4 sts=4 et bs=2:
