#!/usr/bin/perl
use strict;
use warnings;

use Benchmark qw/timethese cmpthese/;

my $c = 'c' x 10;
my $d = 'd' x 10;

my $STR = $c. $d;

my $result = timethese( -1 => +{
    'regex' => sub {
        return () = ($STR =~ /c/g);
    },
    'split' => sub {
        my @list = split /c/, $STR, -1;
        return scalar(@list) - 1,
    },
});

cmpthese $result;
