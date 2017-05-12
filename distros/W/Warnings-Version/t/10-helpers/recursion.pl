#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

my $i = 0;
sub foo { foo() if $i++ < 100; }
foo();
