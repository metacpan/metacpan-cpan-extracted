#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

require 't/common.pl';

# BEGIN: 1 check object class
is_deeply(
    { common_object()->args },
    { common_args() },
    'method match constructor'
);
