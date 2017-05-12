#!/usr/bin/perl

use Test::More tests => 10;

use_ok('Test::More');
require_ok('Test::More');

use_ok( 'LWP::UserAgent' );
require_ok( 'LWP::UserAgent' );

use_ok('URI');
require_ok('URI');

use_ok('JSON');
require_ok('JSON');

use_ok('HTTP::Headers');
require_ok('HTTP::Headers');