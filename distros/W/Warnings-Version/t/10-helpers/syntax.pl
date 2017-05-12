#!/usr/bin env perl

use strict;
use Warnings::Version 'all';

my $foo = 'foo';
if ($foo = 'bar') { exit 0; }
