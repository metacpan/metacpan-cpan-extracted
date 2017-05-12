#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Tumblr' ) || print "Bail out!\n";
}


