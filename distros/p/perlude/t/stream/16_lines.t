#! /usr/bin/perl
use strict;
use warnings;
use Test::More;
use Perlude;

note "this should be removed as lines is out of the scope of Perlude";

my @seed = qw/ toto tata tutu /;
my $content = 'toto
tata
tutu
';

open my $file, '<', \$content;

is_deeply
( [fold lines $file]
, [map { "$_" } @seed]
, "raw lines" );

done_testing;
