#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 missing arg
eval { common_object( 'txt' => undef ); };
like( $@, qr/^missing required parameter txt!/, 'missing arg' );

# BEGIN: 2 attribute value
is(
    common_object()->txt,
    common_txt(),
    'attribute value'
);
