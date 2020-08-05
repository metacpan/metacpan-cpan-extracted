#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use Types::Algebraic;

data Bool = True | False;

is(True, True, "True is True");
isnt(True, False, "True is not False");
isnt(False, True, "False is not True");
is(False, False, "False is False");
