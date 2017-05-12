#!perl -w

use strict;
use Test::More tests => 2;

BEGIN { use_ok 'XS::Assert' }


ok eval{
    require XSLoader;
    XSLoader::load('XS::Assert');
    1;
} or diag $@;

diag "Testing XS::Assert/$XS::Assert::VERSION";

