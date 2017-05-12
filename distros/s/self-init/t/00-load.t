#!/usr/bin/env perl -w

use strict;
use warnings;
use ex::lib qw(../lib);

use Test::More tests => 2;
BEGIN { use_ok 'self::init' };
ok defined &self::init, 'have sub self::init';

