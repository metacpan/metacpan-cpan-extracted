#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok("Text::Lorem::More");
use Text::Lorem::More qw(lorem);
ok( my $tlm = Text::Lorem::More->new(), "\$tlm = Text::Lorem::More->new()" );
ok( Text::Lorem::More->lorem, "was able to get a singleton via Text::Lorem::More->lorem" );
ok( Text::Lorem::More::lorem, "was able get a singleton via Text::Lorem::More::lorem" );
ok( &lorem, "was able get a singleton via import of &lorem" );
cmp_ok( Text::Lorem::More->lorem, "eq", Text::Lorem::More::lorem,
	"Text::Lorem::More->lorem is the same as Text::Lorem::More::lorem" );
	cmp_ok( Text::Lorem::More::lorem, "eq", &lorem,
	"Text::Lorem::More::lorem is the same as &lorem" );
cmp_ok( $tlm, "ne", &lorem, "\$tlm is not the same as &lorem" );
