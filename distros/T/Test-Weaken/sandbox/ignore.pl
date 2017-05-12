#!/usr/bin/perl -w
use strict;
use Test::Weaken;

# uncomment this to run the ### lines
use Smart::Comments;

my $tw = Test::Weaken->new({ constructor => sub { return [] },
                                });
### $tw

$tw->test;
### $tw
