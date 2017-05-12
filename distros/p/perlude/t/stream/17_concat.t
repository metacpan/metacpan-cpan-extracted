#! /usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use Perlude;
use autodie;

my $got = [fold concat range(1,4), range(5,10)]; 
my $expected = [1..10];

is_deeply ($got, $expected, "contat ranges works fine");




