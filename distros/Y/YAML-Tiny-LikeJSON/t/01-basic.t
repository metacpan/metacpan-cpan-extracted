#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most 'no_plan';

use YAML::Tiny::LikeJSON;

my ( $yaml, $data );

$yaml = YAML::Tiny::LikeJSON->new;

$data = $yaml->decode( <<_END_ );
apple: 1
banana:
    - 1
    - 2
    - 3
_END_

cmp_deeply( $data, { apple => 1, banana => [qw/ 1 2 3 /]} );

is( $yaml->encode( $data ), <<_END_ );
apple: 1
banana:
  - 1
  - 2
  - 3
_END_

warning_like { $data = $yaml->decode( <<_END_ ) } qr/Decoded more than 1 document \(actually 2, but only returning the first\)/;
apple: 1
---
banana: 2
_END_
