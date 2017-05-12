#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use_ok( 'Tie::Scalar::Sticky' ) or BAIL_OUT( "can't use module" );
