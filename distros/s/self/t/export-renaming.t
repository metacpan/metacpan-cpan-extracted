#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use self self => { -as => 'this' };

sub echo {
    this;
}

is(echo(42), 42);
