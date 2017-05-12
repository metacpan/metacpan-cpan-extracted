#!/usr/bin/env perl

use strict;
use warnings;

use UR;
use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

class My::Foo {
    attributes_have => [
        is_blah => { is => 'Boolean' },
    ],
    has => [
        foo => { is => 'Text', is_blah => 1 },
        bar => { is => 'Text', is_blah => 0 },
    ]
};

my $meta = My::Foo->__meta__;
my @p;

@p = $meta->properties(is_blah => 1);
is(scalar(@p), 1, "got just one property");
is($p[0]->property_name, "foo", "got the expected property");

@p = $meta->properties(is_blah => 0);
is(scalar(@p), 1, "got just one property");
is($p[0]->property_name, "bar", "got the expected property");

