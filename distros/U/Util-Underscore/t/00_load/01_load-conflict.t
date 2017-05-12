#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

# fixture: set up a conflicting underscore package
{

    package _;
    sub foo;
}

throws_ok { require Util::Underscore }
qr/\AThe package "_" has already been defined/;
