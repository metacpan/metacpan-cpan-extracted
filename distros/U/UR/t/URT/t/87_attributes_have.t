#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use UR;
use Test::More tests => 14;

class DoIt {
    is => 'Command',
    has => {
        i => { is_input => 1 },
        o => { is_output => 1 },
        p => { is_param => 1 },
    }
};

my $m = DoIt->__meta__;
ok($m, 'got meta object for the class');

my $pi = $m->property('i');
ok($pi, 'got meta property for attribute i');
ok($pi->{is_input}, "flag is set for input");
ok(!$pi->{is_output}, "flag is not set for output");
ok(!$pi->{is_param}, "flag is not set for param");
ok($pi->is_input(), "is_input returns true");
ok(!$pi->is_output(), "is_output returns false");
ok(!$pi->is_param(), "is_output returns false");
eval { $pi->foo };
ok($@, "calling odd methods fails"); 

class SomeThing { has => 'x' };
my $m2 = SomeThing->__meta__;
ok($m2, "got property meta for regular class");

my $px = $m2->property('x');
ok($px, 'got meta property for attribute x');

ok(!$px->{is_input}, "flag is not set for input");
eval { $px->is_input() };
ok($@, "is_input accessor attempt throws exception");
eval { $px->foo };
ok($@, "calling odd methods fails"); 

