#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Scalar::Util ();

require 't/common.pl';

my (%arg, $object);

# BEGIN: 1-2 check required parameters
for my $param ( qw(user repo) ) {
    eval { $object = common_class()->new( %arg ); };
    like(
        $@,
        qr/^missing required parameter $param!/,
        "without $param"
    );
    $arg{ $param } = $param;
}

# BEGIN: 3 check object class
is( ref( common_object() ), common_class(), 'object class' );
