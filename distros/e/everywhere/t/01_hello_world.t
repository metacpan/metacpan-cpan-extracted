#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib 't';
use everywhere 'Hello';
use World;

is World::hello(), 'hello', 'Got hello from world';

