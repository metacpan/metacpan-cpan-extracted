#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 render
is(
    common_object()->rdoc,
    sprintf(
        '{<img src="%s" alt="%s" />}[%s]',
        common_img(),
        common_txt(),
        common_url(),
    ),
    'render'
);
