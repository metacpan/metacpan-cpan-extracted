#!/usr/bin/perl

use strict;
use warnings;

use Tie::Mounted;

#$Tie::Mounted::NO_FILES = 1;

my $node = '';

tie my @files, 'Tie::Mounted', $node, '-v';
{
    local $, = "\n";
    print @files;
    print "\n";
}
untie @files;
