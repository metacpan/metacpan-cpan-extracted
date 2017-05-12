#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::FogBugz' );
    use_ok( 'WebService::FogBugz::Config' );
}

diag( "Testing WebService::FogBugz $WebService::FogBugz::VERSION" );
