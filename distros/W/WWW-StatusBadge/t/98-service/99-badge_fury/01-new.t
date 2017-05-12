#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Scalar::Util ();

require 't/common.pl';

my (%arg, $object);

# BEGIN: 1-2 check required parameters
for my $param ( qw(for dist) ) {
    eval { $object = common_class()->new( %arg ); };
    like(
        $@,
        qr/^missing required parameter $param!/,
        "without $param"
    );
    $arg{ $param } = $param;
}

# BEGIN: 3 for not suported
eval { $object = common_class()->new( %arg ); };
like(
    $@,
    qr/^not suported: for/,
    "for not suported"
);

# BEGIN: 4 check object class
is(
    ref( common_class()->new( %arg, 'for' => 'pl' ) ),
    common_class(),
    'object class'
);
