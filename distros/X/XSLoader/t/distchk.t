#!perl 
use strict;
use Test::More;

plan skip_all => "Test::Distribution required for checking distribution"
    unless eval "use Test::Distribution not => 'podcover'; 1";
