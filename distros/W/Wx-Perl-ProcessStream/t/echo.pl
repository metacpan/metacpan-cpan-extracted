#!/usr/bin/perl -w
use strict;

my $input = 'ECHO:';

while(<STDIN>) {
    $input .= $_;
}

print $input;
exit(123);
1;

