#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';
no warnings 'portable';

# don't do this ... causes segmentation fault on perls between 5.12.0 - 5.20.1
#my $time = gmtime('NaN');

my $num = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
