#!/usr/bin/env perl

use strict;
use Warnings::Version '5.20';

my $fn = "$0\0.invalid";
open( my $fh, '<', $fn );
