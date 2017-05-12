#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use WWW::ConfixxBackup;

my @prefixes = qw(test foo_magazin_ renee-baecker);

my $cb = WWW::ConfixxBackup->new(
    file_prefix => $prefixes[0],
);
is $cb->file_prefix, $prefixes[0];


for my $pre ( @prefixes ){
    $cb->file_prefix( $pre );
    is $cb->file_prefix, $pre;
}