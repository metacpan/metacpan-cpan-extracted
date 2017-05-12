#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use strict;
use warnings;

plan tests => 7;

class X {
    has => [
        x1 => { is => 'Text', doc => 'this is property x1 boo' },
        x2 => { is => 'Text', doc => 'this is property x2' },
        x3 => { is => 'Text', doc => 'this is property x3' },
        x4 => { is => 'Text', doc => 'this is property x4' },
    ],
};

class Y {
    is => ['X'],
    has => [
        y1 => { is => 'Text', doc => 'this is property y blah1' },
        y2 => { is => 'Text', doc => 'this is property y2 boo' },
        x1 => { doc => 'override of x1 in Y' },
        x4 => { doc => 'override of x4 in Y' },
    ],
};

class Z {
    is => ['Y'],
    has => [
        z1 => { is => 'Text', doc => 'this is property z1' },
        z2 => { is => 'Text', doc => 'this is property z2 blah' },
        y1 => { doc => 'override of y1 in Z' },
        x3 => { doc => 'override of x1 in Z' },
        x4 => { doc => 'override of x4 in Z which is also overriden in Y' },
    ],
};
my $m = Z->__meta__;
ok($m, "got meta for class Z");

my @p;
my $p;

@p = $m->_properties();
is(scalar(@p), 9, "got 8 properties, as expected");

@p = $m->_properties("doc like" => '%x4%');
is(scalar(@p), 1, "got 1 x4 property");
$p = $p[0];
is($p->class_name, "Z", "class name is Z as expected");
is($p->property_name, "x4", "property name is x4 as expected");

$p = $m->property('x1');
ok($p, "got 1 x1 property");
is($p->property_name,"x1","property name is correct");

