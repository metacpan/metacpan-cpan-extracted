#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
my $error;

eval {
    use Tie::CheckVariables;
    
    tie my $scalar,'Tie::CheckVariables','integer';
    $scalar = 88; # is ok

    $scalar = 'test'; # is not ok, throws error
    untie $scalar;

    1;
} or $error = $@;

like $error, qr/Invalid value test/;
#diag $error;

done_testing;
