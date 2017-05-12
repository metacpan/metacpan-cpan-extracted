#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

use Text::Flowed qw(reformat quote_fixed);
ok(reformat("Hello, world!"), "Hello, world!\n");
ok(reformat("Hello, \nworld!") eq "Hello, world!\n");

ok(quote_fixed("> Hello, world!"), ">> Hello, world!\n");
