#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 render
is(
    common_object()->html,
    sprintf(
        '<a href="%s"><img src="%s" alt="%s" /></a>',
        common_url(),
        common_img(),
        common_txt(),
    ),
    'render'
);
