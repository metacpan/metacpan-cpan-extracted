#!/usr/bin/env perl

use strict;
use Warnings::Version '5.8';

use threads;
use threads::shared;

my $foo = 1;
cond_broadcast($foo);
