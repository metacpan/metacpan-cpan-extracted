#! /usr/bin/perl
use strict;
use warnings;
use Test::More;
use Perlude::Lazy;

my @seed = qw/ toto tata tutu /;
my $content = 'toto
tata
tutu
';

open my $file, '<', \$content;

is_deeply
( [fold lines $file]
, [map { "$_\n" } @seed]
, "raw lines" );

done_testing;

