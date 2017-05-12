#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

sub outer { my $foo; sub inner { sub { $foo } } }
