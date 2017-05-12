#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::Pangram');
can_ok('Text::Pangram',('new'));
