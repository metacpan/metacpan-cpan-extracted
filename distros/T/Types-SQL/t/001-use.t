#!/usr/bin/env perl

use Test::Most;

use_ok('Types::SQL')       or BAIL_OUT 'use Types::SQL failed';
use_ok('Types::SQL::Util') or BAIL_OUT 'use Types::SQL::Util failed';

done_testing;
