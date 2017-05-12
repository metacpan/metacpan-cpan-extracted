#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Text::Clip;

my ( $t0, $content, $data );

$data = <<_END_;

{
    abcdefghijklmnopqrstuvwxyz

  qwerty
-
1 2 3 4 5 5 6 7 8 9     

    xyzzy

}

_END_

$t0 = Text::Clip->new( data => $data );

( $t0, $content ) = $t0->split( qr/rty/, slurp => '[]' );

is( $content, <<_END_ );

{
    abcdefghijklmnopqrstuvwxyz

  qwerty
_END_

$data = <<_END_;
# Xyzzy
#   --- START 
    qwerty

        1 2 3 4 5 6
8 9 10 The end

# abcdefghi
        jklmnop
_END_

$t0 = Text::Clip->new( data => $data )->find( qr/#\s*--- START/ );
( $t0, $content ) = $t0->find( qr/ The end/, slurp => '[]' );

is( $content, <<_END_ );
#   --- START 
    qwerty

        1 2 3 4 5 6
8 9 10 The end
_END_

$t0 = Text::Clip->new( data => $data )->find( qr/#\s*--- START/ );
( $t0, $content ) = $t0->find( qr/ The end/, slurp => '()' );

is( $content, <<_END_ );
    qwerty

        1 2 3 4 5 6
_END_
