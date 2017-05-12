#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

require 't/common.pl';

my $method = common_method();
# BEGIN: 1 check object class
is( ref common_object()->$method, common_plugin_class(), 'object class' );
