#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 render
is(
    common_object()->markdown,
    sprintf(
        '[![%s](%s)](%s)',
        common_txt(),
        common_url(),
        common_img(),
    ),
    'render'
);
