#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Test::More;
use Test::If 'Test::More 0.01', sub{ $ENV{HOME} }, [ tests => 2 ];

ok 1, 'test 1 pass';
ok 1, 'test 2 pass';
