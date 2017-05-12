#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 missing arg
eval { common_object( 'img' => undef ); };
like( $@, qr/^missing required parameter img!/, 'missing arg' );

# BEGIN: 2 attribute value
is(
    common_object()->img,
    common_img(),
    'attribute value'
);
