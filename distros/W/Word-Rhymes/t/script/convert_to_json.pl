#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use JSON;
use Word::Rhymes;

my $dir = 't/data/';

if (@ARGV < 2) {
    die "Need filename and word as params, context is optionally last";
}

my ($file, $word, $context) = @ARGV;

my $j = JSON->new;

my $o = Word::Rhymes->new(return_raw => 1, multi_word => 1);

open my $wfh, '>', "$dir/$file" or die $!;

my $data = $o->fetch($word, $context);

#print $j->pretty->encode($o->fetch($word, $context));
print $wfh $j->pretty->encode( $o->fetch($word, $context));
