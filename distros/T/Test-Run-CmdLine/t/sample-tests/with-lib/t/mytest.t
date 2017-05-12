#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use MyTestModule5;

# TEST
is (camel_case("hello", "there"), "HelloThere");

1;

