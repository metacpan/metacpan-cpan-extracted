#!/usr/bin/env perl -w
use strict;
use Test2::V0;
plan tests => 1;

use self self => { -as => 'this' };

sub echo {
    this;
}

is(echo(42), 42);
