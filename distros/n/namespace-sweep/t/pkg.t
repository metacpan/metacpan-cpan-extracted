#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

package Blorp; {
    use namespace::sweep;
    use Scalar::Util 'reftype';

    sub method { return 1 }
}

package main;

my $o = bless { }, 'Blorp';
ok $o;
isa_ok $o, 'Blorp';

ok $o->method;

eval { $o->reftype };
like $@, qr{^Can't locate object method "reftype"};



