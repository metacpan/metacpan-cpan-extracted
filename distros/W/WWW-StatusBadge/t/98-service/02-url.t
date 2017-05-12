#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util ();

require 't/common.pl';

# BEGIN: 1 missing arg
eval { common_object( 'url' => undef ); };
like( $@, qr/^missing required parameter url!/, 'missing arg' );

# BEGIN: 2 attribute value
is(
    common_object()->url,
    common_url(),
    'attribute value'
);
