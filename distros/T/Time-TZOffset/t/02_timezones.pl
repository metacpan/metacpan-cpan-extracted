#!/usr/bin/perl

use strict;
use warnings;
use Time::Local;
use Time::TZOffset;

my $mode = shift @ARGV;

my @t = @ARGV ? localtime timelocal(@ARGV) : localtime;

print $mode eq 'string'  ? Time::TZOffset::tzoffset(@t)
    : $mode eq 'seconds' ? Time::TZOffset::tzoffset_as_seconds(@t)
    : die "Unknown mode: $mode";

