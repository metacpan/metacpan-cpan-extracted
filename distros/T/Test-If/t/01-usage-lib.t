#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Test::More;
use Test::If 'Test::NonExistingTest 999.0', [ tests => 1 ];

ok 1, 'test pass';
