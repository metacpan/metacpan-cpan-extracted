package Biga;
use strict;
use warnings;
use utf8;

my $v = 0;

sub import { $v = 1 }

sub low { 0 }
sub high { $v }

1;
