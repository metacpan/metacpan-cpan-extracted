#!perl
use strict;
use warnings;
use Test::More;


plan skip_all => "Test::Distribution required for checking distribution"
    unless eval "use Test::Distribution; 1";
