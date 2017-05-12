#!perl

use 5.006;
use strict; use warnings;
use Test::More tests => 1;

BEGIN { use_ok( 'WWW::MovieReviews::NYT' ) || print "Bail out!"; }
