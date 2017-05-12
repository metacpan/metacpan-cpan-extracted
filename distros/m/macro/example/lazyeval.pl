#!perl -w

use strict;
use macro::filter my_if => sub{ print $_[0], " "; $_[0] ? $_[1] : $_[2] };

my_if( 0, print "true\n", print "false\n" );

my_if( 1, print "true\n", print "false\n" );
