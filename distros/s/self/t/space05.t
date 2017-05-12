#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use self;


    sub echo {
        $self
    }


is(echo(42), 42);
