#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;

my $tbl = table {
 warn "activated one or more items";
} data => [
 [ 1, 'first line' ],
 [ 2, 'second line' ],
], columns => [
 { label => 'ID', width => 9 },
 { label => 'Description' },
];
tickit->run;
