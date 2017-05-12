#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Text::Template::Inline;

package TestObj;
sub h { shift->{_h} }
sub l { shift->{_l} }

package main;
my @list = qw/ zero one two three /;
my %hash = (
    a => 'aaa',
    b => 'bbb',
    c => 'ccc',
    a1 => [@list],
    b1 => [@list],
);
my $obj = bless {
    _h => {%hash},
    _l => [@list],
}, 'TestObj';
my $hashref = {
    z => $obj,
    y => {%hash},
    x => [@list],
};

is render($obj, '{h.a} {l.1}'), 'aaa one', 'basic key paths';
is render($hashref, '{z.h.a1.03} {y.b1.1}'), 'three one', 'nested key paths';
is render($obj,'{l.8}'), '{l.8}', 'traversal to nonexistent';
is render($hashref,'{y.b1.m}'), '{y.b1.m}', 'traversal to wrong key type';

eval { render $obj,'{h.b.y}' }; my $line = __LINE__;
ok $@ =~ /$0 line $line$/, 'traversal failure with context';

# vi:filetype=perl ts=4 sts=4 et bs=2:
