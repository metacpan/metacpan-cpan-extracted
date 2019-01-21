#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Types::Standard qw(Int Enum);
use Tie::CheckVariables;

my $error;
Tie::CheckVariables->on_error( sub { $error = 'This was a test' } );

{
    tie my $int, 'Tie::CheckVariables', Int();
    $int = 99;
    is $int, 99;
    $int = 'a';
    is $error, 'This was a test';
}

{
    $error = '';
    tie my $enum, 'Tie::CheckVariables', Enum[1..5];
    $enum = 1;
    is $error, '';
    $enum = 2;
    is $error, '';
    $enum = 6;
    is $error, 'This was a test';
}

done_testing;
