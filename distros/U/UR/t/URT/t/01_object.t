#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;             # dummy namespace

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
    has => [ qw( prop1 prop2 prop3 )],
);

my $o = URT::Thing->create(id => 111);
ok($o, "made an object");

ok(scalar($o->__changes__), 'Newly created object has changes');

$o = URT::Thing->__define__(id => 222);
ok($o, 'defined an object');
ok(! scalar($o->__changes__), 'Newly defined object has no changes');

ok($o->prop1(1), 'Change prop1');
ok(scalar($o->__changes__), 'Object now has changes');
ok(scalar($o->__changes__('prop1')), 'Change to prop1');
ok(! scalar($o->__changes__('prop2')), 'No change to prop2');


$o = URT::Thing->__define__(id => 333, prop1 => 1, prop2 => 2, prop3 => 3);
ok($o, 'Define another object with initial values');
ok($o->prop1(99) && $o->prop3(99), 'Change prop1 and prop3');
ok(scalar($o->__changes__), 'Object has changes');
ok(scalar($o->__changes__('prop2','prop3')), 'Object has changes to either prop2 or prop3');
ok(scalar($o->__changes__('prop3')), 'Object has changes to prop3');
ok(! scalar($o->__changes__('id','prop2')), 'Object has no changes to id or prop2');
1;
