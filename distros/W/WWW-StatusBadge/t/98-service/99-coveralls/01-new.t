#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Scalar::Util ();

require 't/common.pl';

my (%arg, $object);

# BEGIN: 1-3 check required parameters
for my $param ( qw(user repo branch) ) {
    eval { $object = common_class()->new( %arg ); };
    like(
        $@,
        qr/^missing required parameter $param!/,
        "without $param"
    );
    $arg{ $param } = $param;
}

# BEGIN: 4 check object class
is( ref( common_object() ), common_class(), 'object class' );
