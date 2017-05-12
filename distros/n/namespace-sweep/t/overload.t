#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

package Blorp; {
    use namespace::sweep;
    use overload '+' => \&_plus, '*' => \&_times, 'bool' => sub { 1 };
    use Scalar::Util 'reftype';

    sub method { return 1 }
    sub _plus { return 42 }
    sub _times { return "wh00p wh00p" }
}

package main;

my $o = bless { }, 'Blorp';
ok $o;
isa_ok $o, 'Blorp';

ok $o->method;

eval { $o->reftype };
like $@, qr{^Can't locate object method "reftype"};

is $o + $o, 42;
is $o * $o, 'wh00p wh00p';



