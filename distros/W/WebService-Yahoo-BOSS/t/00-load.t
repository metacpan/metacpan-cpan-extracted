#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok('WebService::Yahoo::BOSS');
use_ok('WebService::Yahoo::BOSS::Response');
use_ok('WebService::Yahoo::BOSS::Response::Web');

can_ok( 'WebService::Yahoo::BOSS', qw( Web ) );

done_testing();
