#!perl -w
use strict;
use Test::More tests => 2;

BEGIN { use_ok('WWW::Shorten::Smallr') }

can_ok('WWW::Shorten::Smallr', 'makeashorterlink');

