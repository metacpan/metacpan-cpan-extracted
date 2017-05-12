#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

require 't/common.pl';

# BEGIN: 1 check if method_exists
ok( common_object()->can( common_method() ), 'method exist' );
