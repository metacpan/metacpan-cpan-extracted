#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Test::More;
use Test::If sub{ $ENV{SOME_DUMMY_ENV_VAR} }, [ tests => 1 ];

ok 1, 'test pass';
