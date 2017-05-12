#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 attribute value
is(
    common_object()->txt,
    common_txt(),
    'attribute value'
);
