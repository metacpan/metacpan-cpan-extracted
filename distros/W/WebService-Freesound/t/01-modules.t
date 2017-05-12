#!/usr/bin/perl

use Test::More tests => 14;

use_ok('Test::More');
require_ok('Test::More');

use_ok('Test::Exception');
require_ok('Test::Exception');

use_ok('HTTP::Response');
require_ok('HTTP::Response');

use_ok('LWP::Simple');
require_ok('LWP::Simple');

use_ok('LWP::UserAgent');
require_ok('LWP::UserAgent');

use_ok('Test::MockModule');
require_ok('Test::MockModule');

use_ok('JSON');
require_ok('JSON');
