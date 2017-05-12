#!/usr/bin/perl
# Test building graphs with an invalid style.

use strict;
use warnings;
use Test::More tests => 1;

use Text::Graph;

eval { Text::Graph->new( 'Fred' ); };
is( $@, "Unknown style 'Fred'.\n", "A bad style should fail." );

