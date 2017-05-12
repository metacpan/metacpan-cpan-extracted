#!/usr/bin/perl

use strict;
use File::MMagic;

my $file = shift || '/net/home/allenday/breakdance.mpg';

my $mm = File::MMagic->new();

my $result = $mm->checktype_filename($file);

print "\n\n$result\n\n";
